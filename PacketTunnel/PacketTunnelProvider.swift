//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by yyf on 2025/6/29.
//

import NetworkExtension
import NEKit

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var proxyServer: GCDSOCKS5ProxyServer? //本地 socks5 服务器
    private var proxyRunning = false
    private var tunInterface: TUNInterface? // 虚拟 TUN 接口
    override init() {
        super.init()
        NSLog("[PacketTunnel] init")
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[PacketTunnel] 准备启动  startTunnel 被调用！")

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

        // 2. 验证加密算法是否支持
        guard let algorithm = CryptoAlgorithm(rawValue: method) else {
            throw NSError(domain: "Invalid cipher method: \(method)", code: -1, userInfo: nil)
        }

        // 3. 创建 Shadowsocks 加密器
        let cryptorFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm)

        // 4. 创建 Shadowsocks 适配器工厂
        let ssAdapterFactory = ShadowsocksAdapterFactory(
            serverHost: server,
            serverPort: port,
            protocolObfuscaterFactory: ShadowsocksAdapter.ProtocolObfuscater.Factory(),
            cryptorFactory: cryptorFactory,
            streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.Factory()
        )

        // 5. 设置代理规则：所有请求都走这个代理（所有流量都转发）
        let ruleManager = RuleManager(fromRules: [
            AllRule(adapterFactory: ssAdapterFactory)
        ])
        RuleManager.currentManager = ruleManager

        // 6. 创建本地 GCDSOCKS5 代理服务器 （NEKit 的代理转发组件）
         let localProxyPort: UInt16 = 1086
        proxyServer = GCDSOCKS5ProxyServer(
            address: IPAddress(fromString: "127.0.0.1"),
            port: Port(integerLiteral: UInt16(localProxyPort))
        )
         try proxyServer?.start() // 启动 socks5 服务
//
//         // 7. 设置 TCPStack，把数据转发给代理
         let tcpStack = TCPStack.stack
         tcpStack.proxyServer = proxyServer

//         //8. 创建TUNInterface虚拟网络接口，挂接 TUN
        /**
         TUN（network TUNnel）接口是一种虚拟的网络设备，它在操作系统中扮演一个“假装的网卡”，用于收发 IP 层的数据包。其作用是：
         你可以把 TUN 看成是一个“假网卡”：
         设备发起网络请求（如访问 Google）
         数据包本该通过真实的网卡发出（如 Wi-Fi）
         但你通过 TUN 把数据“劫持”了
         你拿到这些原始 IP 包，可以：
         加密
         改路径
         发往代理服务器（如 Shadowsocks）
         再返回结果
         最终的效果是：
         📡 系统以为访问网络正常，其实数据流量被你拦截→加工→转发→返回。
         */
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

