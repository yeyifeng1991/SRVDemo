//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by yyf on 2025/6/29.
//

import NetworkExtension
import NEKit

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var proxyServer: GCDSOCKS5ProxyServer?
    private var proxyRunning = false
    private var tunInterface: TUNInterface?
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[PacketTunnel] 准备启动 Shadowsocks 隧道")

        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = protocolConfiguration.providerConfiguration else {
            completionHandler(NSError(domain: "PacketTunnel", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无效配置"]))
            return
        }

        let server = providerConfig["server"] as? String ?? ""
        let port = providerConfig["port"] as? Int ?? 0
        let password = providerConfig["password"] as? String ?? ""
        let method = providerConfig["method"] as? String ?? "aes-256-gcm"

        NSLog("[PacketTunnel] Shadowsocks配置: \(server):\(port), method=\(method)")

        do {
            try startShadowsocksProxy(server: server, port: port, password: password, method: method)
            completionHandler(nil)
        } catch {
            NSLog("[PacketTunnel] 启动失败: \(error)")
            completionHandler(error)
        }
    }

    private func startShadowsocksProxy(server: String, port: Int, password: String, method: String) throws {
        // 1. 停止旧代理
        stopProxy()

        // 2. 校验加密方式
        guard let algorithm = CryptoAlgorithm(rawValue: method) else {
            throw NSError(domain: "Invalid cipher method: \(method)", code: -1, userInfo: nil)
        }

        // 3. 构建加密器
        let cryptorFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm)

        // 4. 创建 Shadowsocks 适配器工厂
        let ssAdapterFactory = ShadowsocksAdapterFactory(
            serverHost: server,
            serverPort: port,
            protocolObfuscaterFactory: ShadowsocksAdapter.ProtocolObfuscater.Factory(),
            cryptorFactory: cryptorFactory,
            streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.Factory()
        )

        // 5. 配置转发规则（所有流量都转发）
        let ruleManager = RuleManager(fromRules: [
            AllRule(adapterFactory: ssAdapterFactory)
        ])
        RuleManager.currentManager = ruleManager

        // 6. 创建本地 GCDSOCKS5 代理服务器
         let localProxyPort: UInt16 = 1086
        proxyServer = GCDSOCKS5ProxyServer(
            address: IPAddress(fromString: "127.0.0.1"),
            port: Port(integerLiteral: UInt16(localProxyPort))
        )
         try proxyServer?.start()
//
//         // 7. 配置 TCP Stack
         let tcpStack = TCPStack.stack
         tcpStack.proxyServer = proxyServer

//         // 8. 创建 TUNInterface，绑定 packetFlow
         let interface = TUNInterface(packetFlow: self.packetFlow)
         interface.register(stack: tcpStack)
//
//         // 可选：添加 UDP 支持（如需要）
         let udpStack = UDPDirectStack()
         interface.register(stack: udpStack)
//
//         // 9. 启动虚拟网卡
         interface.start()
         tunInterface = interface
//        
        // 10. 标记代理已启动（你可以设置为成员变量）
        self.proxyRunning = true
    }

    private func stopProxy() {
        if proxyRunning {
            proxyServer?.stop()
            proxyServer = nil
          tunInterface?.stop()
          tunInterface = nil
            proxyRunning = false
            NSLog("[PacketTunnel] Shadowsocks 隧道已停止")
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[PacketTunnel] 停止隧道，原因: \(reason.rawValue)")
        stopProxy()
        completionHandler()
    }
    // MARK: - 支持算法映射
      func getCryptoAlgorithm(from method: String) -> CryptoAlgorithm? {
          switch method.lowercased() {
          case "aes-128-cfb": return .AES128CFB
          case "aes-192-cfb": return .AES192CFB
          case "aes-256-cfb": return .AES256CFB
//          case "aes-128-gcm": return .AES128GCM
//          case "aes-256-gcm": return .AES256GCM
          case "chacha20":    return .CHACHA20
          case "rc4-md5":     return .RC4MD5
          default: return nil
          }
      }
}

