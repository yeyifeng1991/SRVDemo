//
//  VPNConfigManager.swift
//  PacketTunnel
//
//  Created by yyf on 2025/6/29.
//

import Foundation
import NetworkExtension

@objc public class VPNConfigManager: NSObject {
    @objc public static let shared = VPNConfigManager()
    
    @objc public private(set) var tunnelManager: NETunnelProviderManager?
    // 加载或创建VPN配置
    @objc public func loadOrCreateConfiguration(completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("加载VPN配置失败: \(error)")
                completion(false)
                return
            }
            
            self.tunnelManager = managers?.first ?? NETunnelProviderManager()
            completion(true)
        }
    }
    
    // 配置并启动VPN
    @objc func startVPN(server: String,
                        port: Int,
                        protocolType: String,
                        password: String,
                        method: String?,
                        completion: @escaping (Error?) -> Void) {
        print("[VPNConfig] 开始启动VPN - 服务器: \(server):\(port), 协议: \(protocolType), 方法: \(method ?? "默认")")
        // 最大重试次数
        let maxRetryCount = 2
        var currentRetry = 0
        func attemptStart() {
            loadOrCreateConfiguration { success in
                guard success, let manager = self.tunnelManager else {
                    // 重试逻辑
                    if currentRetry < maxRetryCount {
                        currentRetry += 1
                        print("[VPNConfig] 配置加载失败，重试 #\(currentRetry)")
                        attemptStart()
                    } else {
                        completion(NSError(domain: "VPNConfig", code: 1, userInfo: [NSLocalizedDescriptionKey: "配置加载失败"]))
                    }
                    return
                }
                
                self.loadOrCreateConfiguration { success in
                         guard success, let manager = self.tunnelManager else {
                             print("[VPNConfig] 配置加载失败")

                             completion(NSError(domain: "VPNConfig", code: 1, userInfo: [NSLocalizedDescriptionKey: "配置加载失败"]))
                             return
                         }
                         print("[VPNConfig] 加载配置成功")

                         // 1. 配置协议
                         let protocolConfig = NETunnelProviderProtocol()
                         protocolConfig.providerBundleIdentifier = "com.talkcloud.name.SRVDemo.PacketTunnel" // 替换为你的扩展bundle ID
                         protocolConfig.serverAddress = server
                         
                         // 2. 添加自定义配置
                         var providerConfig = [String: Any]()
                         providerConfig["server"] = server
                         providerConfig["port"] = port
                         providerConfig["protocol"] = protocolType
                         providerConfig["password"] = password
                         
                         if let method = method {
                             providerConfig["method"] = method
                         }
                         
                         protocolConfig.providerConfiguration = providerConfig
                         
                         // 3. 应用配置
                         manager.protocolConfiguration = protocolConfig
                         manager.localizedDescription = "安全VPN连接"
                         manager.isEnabled = true
                         
                         // 4. 保存配置
                         manager.saveToPreferences { error in
                             if let error = error {
                                 print("[VPNConfig] 保存配置失败: \(error)")
                                 completion(error)
                                 return
                             }
                             print("[VPNConfig] 配置保存成功")

                             // 5. 加载配置后启动VPN
                             manager.loadFromPreferences { error in
                                 if let error = error {
                                     print("[VPNConfig] 加载配置失败: \(error)")
                                     completion(error)
                                     return
                                 }
                                 print("[VPNConfig] 配置加载完成，准备启动隧道")
                                 do {
                                     try manager.connection.startVPNTunnel()
                                     self.tunnelManager = manager
                                     print("[VPNConfig] VPN隧道启动命令已发送")
                                     completion(nil)
                                 } catch {
                                     print("[VPNConfig] 启动隧道失败: \(error)")
                                     completion(error)
                                 }
                             }
                         }
                     }
                
                // 在启动隧道前添加延迟
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    do {
                        try manager.connection.startVPNTunnel()
                        self.tunnelManager = manager
                        print("[VPNConfig] VPN隧道启动命令已发送")
                        completion(nil)
                    } catch {
                        // 重试逻辑
                        if currentRetry < maxRetryCount {
                            currentRetry += 1
                            print("[VPNConfig] 启动失败，重试 #\(currentRetry): \(error)")
                            attemptStart()
                        } else {
                            completion(error)
                        }
                    }
                }
            }
        }
        
        // 开始首次尝试
        attemptStart()
        
     
    }
    
    // 停止VPN
    @objc public func stopVPN(completion: @escaping (Error?) -> Void) {
        print("[VPNConfig] 停止VPN命令已发送")
        tunnelManager?.connection.stopVPNTunnel()
        completion(nil)
    }
    
    // 获取当前状态
    @objc func getVPNStatus() -> Int {
        return tunnelManager?.connection.status.rawValue ?? 0
    }
    
    // 添加状态变化监听
    @objc public func addStatusObserver(completion: @escaping (Int) -> Void) {
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange,
                                              object: nil,
                                              queue: .main) { notification in
            if let connection = notification.object as? NEVPNConnection {
                completion(connection.status.rawValue)
            }
        }
    }
}
