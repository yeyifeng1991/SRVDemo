//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by yyf on 2025/6/29.
//
import NetworkExtension
import NEKit

class RuleBasedSOCKS5Handler: NSObject {
    private let rule: Rule
    
    init(rule: Rule) {
        self.rule = rule
        super.init()
    }
    
    func handleNewSocket(_ socket: GCDTCPSocket) {
        // 创建代理连接并应用规则
        let proxySocket = SOCKS5ProxySocket(socket: socket)
    
        let connection = SOCKS5ProxyConnection(
            socket: proxySocket,
            rule: rule
        )
        connection.start()
    }
}

class PacketTunnelProvider: NEPacketTunnelProvider {
    // MARK: - 代理状态
    private var proxyRunning = false
    private var proxyPort: UInt16 = 1080 // 默认代理端口
    
    // 代理服务器
    private var proxyServer: GCDSOCKS5ProxyServer?
    
    // MARK: - 隧道生命周期
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        logStartTunnel(options: options)
        
        // 1. 验证配置有效性
        guard let protocolConfig = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = protocolConfig.providerConfiguration else {
            logError("❌ 缺少必要的隧道配置")
            completionHandler(createError(domain: "TunnelConfig", code: 100, message: "缺少配置"))
            return
        }
        
        // 2. 解析配置参数
        guard let server = providerConfig["server"] as? String,
              let port = providerConfig["port"] as? Int,
              let password = providerConfig["password"] as? String else {
            logError("❌ 代理配置参数不完整")
            completionHandler(createError(domain: "TunnelConfig", code: 101, message: "配置参数不完整"))
            return
        }
        
        logConfig(server: server, port: port, protocolType: "Trojan")
        
        // 3. 创建网络设置
        let settings = createNetworkSettings()
        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.logError("❌ 设置隧道网络失败: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            self.logInfo("✅ 网络设置完成")
            
            // 4. 启动代理服务器
            self.startTrojanProxy(
                server: server,
                port: port,
                password: password
            ) { error in
                if let error = error {
                    self.logError("❌ 启动代理失败: \(error.localizedDescription)")
                    completionHandler(error)
                } else {
                    self.logInfo("🚀 隧道完全就绪")
                    
                    // 5. 开始处理数据包
                    self.startReadingPackets()
                    
                    // 6. 完成隧道启动
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completionHandler(nil)
                        self.logInfo("✅ 调用完成处理程序")
                    }
                }
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logStopTunnel(reason: reason)
          
        // 1. 停止代理服务
        stopProxyServer()
          
        // 2. 停止数据包读取
        proxyRunning = false
          
        // 3. 延迟确保资源释放
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.logInfo("🛑 隧道已完全停止")
            completionHandler()
        }
    }
    
    // MARK: - 代理服务器管理
    private func startTrojanProxy(
        server: String,
        port: Int,
        password: String,
        completion: @escaping (Error?) -> Void
    ) {
        logInfo("🔄 正在启动 Trojan 代理服务器...")
        
        do {
            // 1. 创建 Trojan 配置
                  let config = TrojanConfiguration(
                      server: server,
                      port: port,
                      password: password
                  )
      
                  // 2. 创建适配器工厂
                  let adapterFactory = TrojanAdapterFactory(config: config)
            
            // 3. 创建代理规则（这里使用全部流量都走代理）
                let allRule = AllRule(adapterFactory: adapterFactory)
                  // 4. 创建本地 SOCKS5 代理服务器
                proxyServer = GCDSOCKS5ProxyServer(address: nil, port: NEKit.Port(port: proxyPort))
                  
                  // 5. 注册适配器工厂 - 使用正确的 registerHandler 方法
//                  proxyServer?.registerHandler(for: allRule, adapterFactory: adapterFactory)

          
                  // 6. 启动代理服务器
                  try proxyServer?.start()
                  
                  logInfo("✅ Trojan 代理已启动")
                  proxyRunning = true
                  completion(nil)
        } catch {
            logError("❌ 启动 Trojan 失败: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    private func stopProxyServer() {
        logInfo("🛑 停止代理服务器")
        proxyRunning = false
        
        // 停止代理服务器
        proxyServer?.stop()
        proxyServer = nil
    }
    
    // MARK: - 数据包处理
    private func startReadingPackets() {
        logInfo("📦 开始读取数据包")
        
        readPacket()
    }
    
    private func readPacket() {
        guard proxyRunning else {
            logInfo("📦 停止读取数据包（隧道已停止）")
            return
        }
        
        packetFlow.readPackets { [weak self] (packets, protocols) in
            guard let self = self, self.proxyRunning else { return }
            
            self.logDebug("📥 收到 \(packets.count) 个数据包")
            
            for (index, packet) in packets.enumerated() {
                let protocolFamily = protocols[index].intValue
                self.handlePacket(packet, protocolFamily: protocolFamily)
            }
            
            // 继续读取下一个数据包
            self.readPacket()
        }
    }
    
    private func handlePacket(_ packet: Data, protocolFamily: Int) {
        logDebug("📦 处理数据包 (\(packet.count) 字节), 协议族: \(protocolFamily)")
        
        // 这里简化处理，实际应该将数据包发送到代理服务器
        // 在完整实现中，应该通过代理服务器处理这些数据包
    }
    
    // MARK: - 网络设置
    private func createNetworkSettings() -> NEPacketTunnelNetworkSettings {
        logInfo("⚙️ 创建网络设置")
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        // IPv4 设置
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // DNS 设置
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
        
        // 代理设置
        let proxySettings = NEProxySettings()
        proxySettings.autoProxyConfigurationEnabled = false
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: Int(proxyPort))
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: Int(proxyPort))
        proxySettings.excludeSimpleHostnames = false
        proxySettings.exceptionList = ["localhost", "127.0.0.1"]
        settings.proxySettings = proxySettings
        
        return settings
    }
    
    // MARK: - 消息处理
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        logInfo("📨 收到应用消息 (\(messageData.count) 字节)")
        
        if let message = String(data: messageData, encoding: .utf8) {
            logDebug("消息内容: \(message)")
            
            switch message {
            case "status":
                let status = "ProxyRunning: \(proxyRunning)"
                completionHandler?(status.data(using: .utf8))
            default:
                let response = "Unhandled message: \(message)"
                completionHandler?(response.data(using: .utf8))
            }
        } else {
            completionHandler?("Invalid message".data(using: .utf8))
        }
    }
    
    // MARK: - 睡眠/唤醒处理
    override func sleep(completionHandler: @escaping () -> Void) {
        logInfo("😴 隧道进入睡眠状态")
        completionHandler()
    }
    
    override func wake() {
        logInfo("🌞 隧道唤醒")
    }
    
    // MARK: - 日志工具
    private func logStartTunnel(options: [String: NSObject]?) {
        Logger.info("⏺ 开始启动隧道", category: "PacketTunnel")
        
        if let options = options, !options.isEmpty {
            Logger.debug("启动选项: \(options.description)", category: "PacketTunnel")
        }
    }
    
    private func logStopTunnel(reason: NEProviderStopReason) {
        let reasonDescription: String
        switch reason {
        case .none: reasonDescription = "未指定"
        case .userInitiated: reasonDescription = "用户主动停止"
        case .noNetworkAvailable: reasonDescription = "无可用网络"
        case .unrecoverableNetworkChange: reasonDescription = "不可恢复的网络变化"
        case .providerDisabled: reasonDescription = "提供者被禁用"
        case .authenticationCanceled: reasonDescription = "认证取消"
        case .configurationFailed: reasonDescription = "配置失败"
        case .idleTimeout: reasonDescription = "空闲超时"
        case .configurationDisabled: reasonDescription = "配置被禁用"
        case .configurationRemoved: reasonDescription = "配置被移除"
        case .superceded: reasonDescription = "被取代"
        case .userLogout: reasonDescription = "用户登出"
        case .userSwitch: reasonDescription = "用户切换"
        case .connectionFailed: reasonDescription = "连接失败"
        @unknown default: reasonDescription = "未知原因 (\(reason.rawValue))"
        }
        
        Logger.info("⏹ 停止隧道，原因: \(reasonDescription)", category: "PacketTunnel")
    }
    
    private func logConfig(server: String, port: Int, protocolType: String) {
        Logger.info("""
        📋 代理配置:
         服务器: \(server)
         端口: \(port)
         协议: \(protocolType)
        """, category: "PacketTunnel")
    }
    
    private func logInfo(_ message: String) {
        Logger.info(message, category: "PacketTunnel")
    }
    
    private func logDebug(_ message: String) {
        Logger.debug(message, category: "PacketTunnel")
    }
    
    private func logError(_ message: String) {
        Logger.error(message, category: "PacketTunnel")
    }
    
    private func createError(domain: String, code: Int, message: String) -> NSError {
        NSError(domain: domain, code: code, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
}
