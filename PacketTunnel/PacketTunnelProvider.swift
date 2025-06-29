//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by yyf on 2025/6/29.
//
import NetworkExtension
import os.log
//startShadowsocksProxy 方法中，"实际代理启动代码" 是指您需要集成 Shadowsocks 库（如 Shadowsocks-iOS）
//private var shadowsocksClient: ShadowsocksClient? // 添加代理客户端引用
private var isReadingPackets = false // 添加读取状态标志

class PacketTunnelProvider: NEPacketTunnelProvider {
    // MARK: - 日志系统
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "PacketTunnel"
    )
    
    // MARK: - 代理状态
    private var proxyRunning = false
    private var proxyPort: UInt16 = 1080 // 默认代理端口
    
    // MARK: - 隧道生命周期
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        logStartTunnel(options: options)
        
        // 1. 验证配置
        guard let protocolConfig = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = protocolConfig.providerConfiguration else {
            logError("❌ 缺少必要的隧道配置")
            completionHandler(createError(domain: "TunnelConfig", code: 100, message: "缺少配置"))
            return
        }
        
        // 2. 解析配置参数
        guard let server = providerConfig["server"] as? String,
              let port = providerConfig["port"] as? Int,
              let protocolType = providerConfig["protocol"] as? String,
              let password = providerConfig["password"] as? String else {
            logError("❌ 代理配置参数不完整")
            completionHandler(createError(domain: "TunnelConfig", code: 101, message: "配置参数不完整"))
            return
        }
        
        let method = providerConfig["method"] as? String
        logConfig(server: server, port: port, protocolType: protocolType, method: method)
        
        // 3. 设置网络配置 - 关键修复点：不在此处调用completionHandler
        let settings = createNetworkSettings()
        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.logError("❌ 设置隧道网络失败: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            self.logInfo("✅ 网络设置完成")
            
            // 4. 启动代理服务器 - 关键修复点：延迟调用completionHandler
            self.startProxyServer(
                server: server,
                port: port,
                protocolType: protocolType,
                password: password,
                method: method
            ) { error in
                // 关键：在代理完全启动后再调用完成处理程序
                if let error = error {
                    self.logError("❌ 启动代理失败: \(error.localizedDescription)")
                    completionHandler(error)
                } else {
                    self.logInfo("🚀 隧道完全就绪")
                    
                    // 关键修复：启动数据包处理循环
                    self.startReadingPackets()
                    
                    // 关键：延迟500ms确保隧道稳定
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
          
          // 2. 停止数据包读取循环
          proxyRunning = false
          
          // 3. 停止 Shadowsocks 客户端
//          shadowsocksClient?.stop()
//          shadowsocksClient = nil
          
          // 4. 延迟确保资源释放
          DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
              self.logInfo("🛑 隧道已完全停止")
              completionHandler()
          }
    }
    
    // MARK: - 代理服务器管理
    private func startProxyServer(
        server: String,
        port: Int,
        protocolType: String,
        password: String,
        method: String?,
        completion: @escaping (Error?) -> Void
    ) {
        logInfo("🔄 正在启动 \(protocolType) 代理服务器...")
        
        // 根据协议类型选择不同的启动方式
        switch protocolType.lowercased() {
        case "shadowsocks", "ss":
            startShadowsocksProxy(
                server: server,
                port: port,
                password: password,
                method: method,
                completion: completion
            )
            
        case "trojan":
            startTrojanProxy(
                server: server,
                port: port,
                password: password,
                completion: completion
            )
            
        default:
            logError("❌ 不支持的协议类型: \(protocolType)")
            completion(createError(domain: "TunnelConfig", code: 102, message: "不支持的协议类型"))
        }
    }
    
    private func stopProxyServer() {
        logInfo("🛑 停止代理服务器")
        proxyRunning = false
        
        // 实际停止代理的代码
        // 这里应该有停止代理服务的实现
    }
    
    private func startShadowsocksProxy(
        server: String,
        port: Int,
        password: String,
        method: String?,
        completion: @escaping (Error?) -> Void
    ) {
        let encryption = method ?? "aes-256-gcm"
       logInfo("🔐 使用 Shadowsocks (\(encryption))")
       
       // 移除 startReadingPackets() 调用
       // 实际代理启动代码...
       logInfo("✅ Shadowsocks 代理已启动")
       proxyRunning = true
       
       // 模拟代理启动成功
       DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
           completion(nil)
       }
    }
    
    private func startTrojanProxy(
        server: String,
        port: Int,
        password: String,
        completion: @escaping (Error?) -> Void
    ) {
        logInfo("🔐 启动 Trojan 代理")
        
        do {
            // 实际启动 Trojan 代理的代码
            // 这里应该有 Trojan 库的初始化
            logInfo("✅ Trojan 代理已启动")
            proxyRunning = true
            startReadingPackets()
            completion(nil)
        } catch {
            logError("❌ 启动 Trojan 失败: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    // MARK: - 数据包处理 (使用 NEPacketTunnelFlow)
    private func startReadingPackets() {
        guard !isReadingPackets else {
            logInfo("📦 数据包读取已启动")
            return
        }
        
        logInfo("📦 开始读取数据包")
        isReadingPackets = true
        proxyRunning = true
        
        // 使用递归函数保持循环
        func readPackets() {
            // 确保隧道仍在运行
            guard proxyRunning else {
                logInfo("📦 停止读取数据包（隧道已停止）")
                isReadingPackets = false
                return
            }
            
            packetFlow.readPackets { [weak self] (packets, protocols) in
                guard let self = self else { return }
                
                self.logDebug("📥 收到 \(packets.count) 个数据包")
                
                // 处理数据包
                for (index, packet) in packets.enumerated() {
                    let protocolFamily = protocols[index].intValue
                    self.handlePacket(packet, protocolFamily: protocolFamily)
                }
                
                // 继续读取下一个数据包
                readPackets()
            }
        }
        
        // 启动读取循环
        readPackets()
    }
    
    private func handlePacket(_ packet: Data, protocolFamily: Int) {
        // 1. 检查代理是否运行
//           guard proxyRunning, let client = shadowsocksClient else {
//               logDebug("📦 收到数据包但代理未运行")
//               return
//           }
//           
//           // 2. 记录数据包信息
//           logDebug("📦 处理数据包 (\(packet.count) 字节), 协议族: \(protocolFamily)")
//           
//           // 3. 将数据包发送到代理服务器
//           do {
//               try client.write(packet)
//               logDebug("📤 已发送数据包到代理服务器")
//           } catch {
//               logError("❌ 发送数据包失败: \(error.localizedDescription)")
//               
//               // 如果是严重错误，停止隧道
//               if let nsError = error as NSError?,
//                  nsError.domain == "ShadowsocksErrorDomain" && nsError.code == 100 {
//                   cancelTunnelWithError(error)
//               }
//           }
    }
    
    private func writePacket(_ packet: Data, protocolFamily: Int) {
        let protocols = [NSNumber(value: protocolFamily)]
         packetFlow.writePackets([packet], withProtocols: protocols)
         logDebug("📤 发送数据包 (\(packet.count) 字节)")
    }
    
    // MARK: - 网络设置
    private func createNetworkSettings() -> NEPacketTunnelNetworkSettings {
        logInfo("⚙️ 创建网络设置")
        
        // 创建基础网络设置
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        // 配置 IPv4 设置
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // 配置 DNS 设置
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
        
        // 配置代理设置
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
        
        // 解析消息内容
        if let message = String(data: messageData, encoding: .utf8) {
            logDebug("消息内容: \(message)")
            
            // 处理不同类型的消息
            switch message {
            case "status":
                let status = "ProxyRunning: \(proxyRunning)"
                completionHandler?(status.data(using: .utf8))
            case "stats":
                let stats = "PacketsProcessed: 0" // 实际应该有统计信息
                completionHandler?(stats.data(using: .utf8))
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
}

// MARK: - 日志工具
extension PacketTunnelProvider {
    private func logStartTunnel(options: [String: NSObject]?) {
        logger.log(level: .info, "⏺ 开始启动隧道")
        
        if let options = options, !options.isEmpty {
            logger.debug("启动选项: \(options.description)")
        }
    }
    
    private func logStopTunnel(reason: NEProviderStopReason) {
        let reasonDescription: String
        switch reason {
        case .none: reasonDescription = "未指定"
        case .userInitiated: reasonDescription = "用户主动停止"
        case .providerFailed: reasonDescription = "提供程序失败"
        case .noNetworkAvailable: reasonDescription = "无网络可用"
        case .unrecoverableNetworkChange: reasonDescription = "不可恢复的网络变化"
        case .providerDisabled: reasonDescription = "提供程序被禁用"
        case .authenticationCanceled: reasonDescription = "认证取消"
        case .configurationFailed: reasonDescription = "配置失败"
        case .idleTimeout: reasonDescription = "空闲超时"
        case .configurationDisabled: reasonDescription = "配置被禁用"
        case .configurationRemoved: reasonDescription = "配置被移除"
        case .superceded: reasonDescription = "被更高优先级配置取代"
        case .userLogout: reasonDescription = "用户注销"
        case .userSwitch: reasonDescription = "用户切换"
        case .connectionFailed: reasonDescription = "连接失败"
        @unknown default: reasonDescription = "未知原因 (\(reason.rawValue))"
        }
        
        logger.log(level: .info, "⏹ 停止隧道，原因: \(reasonDescription)")
    }
    
    private func logConfig(server: String, port: Int, protocolType: String, method: String?) {
        logger.log(level: .info, """
        📋 代理配置:
         服务器: \(server)
         端口: \(port)
         协议: \(protocolType)
         方法: \(method ?? "默认")
        """)
    }
    
    private func logInfo(_ message: String) {
        logger.log(level: .info, "ℹ️ \(message)")
    }
    
    private func logDebug(_ message: String) {
        logger.debug("🐞 \(message)")
    }
    
    private func logError(_ message: String) {
        logger.error("❌ \(message)")
    }
    
    private func createError(domain: String, code: Int, message: String) -> NSError {
        NSError(domain: domain, code: code, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }
}

// MARK: - 文件日志（可选）
extension PacketTunnelProvider {
    private func logToFile(_ message: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourcompany.app"
        ) else {
            logger.error("无法获取共享容器URL")
            return
        }
        
        let logFileURL = containerURL.appendingPathComponent("vpn_tunnel_log.txt")
        
        do {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
            let logEntry = "\(timestamp): \(message)\n"
            
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            logger.error("写入日志文件失败: \(error.localizedDescription)")
        }
    }
}
