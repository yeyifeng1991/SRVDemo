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
    
    // MARK: - VPN 状态监听
    private var statusObserver: NSObjectProtocol?
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - VPN 配置管理
    @objc public func loadOrCreateConfiguration(completion: @escaping (Bool) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard let self = self else { return }

            if let error = error {
                print("[VPNConfigManager] 加载VPN配置失败: \(error)")
                completion(false)
                return
            }

            let existingManager = managers?.first

            if let manager = existingManager,
               let proto = manager.protocolConfiguration as? NETunnelProviderProtocol,
               proto.providerBundleIdentifier == "com.talkcloud.name.SRVDemo.PacketTunnel" {
                // ✅ 已存在且配置正确，使用该配置
                self.tunnelManager = manager
                completion(true)
            } else {
                // ⚠️ 存在但配置错误，先删除再重新创建
                if let manager = existingManager {
                    manager.removeFromPreferences { [weak self] error in
                        if let error = error {
                            print("[VPNConfigManager] 删除旧配置失败: \(error)")
                            completion(false)
                            return
                        }
                        print("[VPNConfigManager] 旧配置已删除，创建新配置")
                        self?.createNewConfiguration(completion: completion)
                    }
                } else {
                    // ✅ 不存在任何配置，直接创建新配置
                    self.createNewConfiguration(completion: completion)
                }
            }
        }
    }
    
    private func createNewConfiguration(completion: @escaping (Bool) -> Void) {
        let manager = NETunnelProviderManager()
        manager.localizedDescription = "安全VPN连接"
        manager.isEnabled = true

        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.serverAddress = "VPN" // 任意非空字符串即可
        tunnelProtocol.providerBundleIdentifier = "com.talkcloud.name.SRVDemo.PacketTunnel"
        manager.protocolConfiguration = tunnelProtocol

        manager.saveToPreferences { [weak self] error in
            if let error = error {
                print("[VPNConfigManager] 创建VPN配置失败: \(error)")
                completion(false)
            } else {
                self?.tunnelManager = manager
                completion(true)
            }
        }
    }
    
    // MARK: - VPN 启动与停止
    @objc func startVPN(
        server: String,
        port: Int,
        protocolType: String,
        password: String,
        method: String?,
        completion: @escaping (Error?) -> Void
    ) {
        print("[VPNConfigManager] 开始启动VPN - 服务器: \(server):\(port), 协议: \(protocolType), 方法: \(method ?? "默认")")
        
        loadOrCreateConfiguration { [weak self] success in
            guard let self = self, success, let manager = self.tunnelManager else {
                completion(NSError(domain: "VPNConfig", code: 1, userInfo: [NSLocalizedDescriptionKey: "配置加载失败"]))
                return
            }
            
            // 配置隧道协议
            let protocolConfig = NETunnelProviderProtocol()
            protocolConfig.providerBundleIdentifier = "com.talkcloud.name.SRVDemo.PacketTunnel"
            protocolConfig.serverAddress = server
            
            // 自定义配置
            var providerConfig = [String: Any]()
            providerConfig["server"] = server
            providerConfig["port"] = port
            providerConfig["protocol"] = protocolType
            providerConfig["password"] = password
            
            if let method = method {
                providerConfig["method"] = method
            }
            
            protocolConfig.providerConfiguration = providerConfig
            manager.protocolConfiguration = protocolConfig
            manager.isEnabled = true
            
            // 保存配置
            manager.saveToPreferences { [weak self] error in
                if let error = error {
                    print("[VPNConfigManager] 保存配置失败: \(error)")
                    completion(error)
                    return
                }
                
                // 加载配置后启动VPN

                manager.loadFromPreferences { [weak self] error in
                    if let error = error {
                        print("[VPNConfigManager] 加载配置失败: \(error)")
                        completion(error)
                        return
                    }
                    
                    do {
                        try manager.connection.startVPNTunnel()
                        self?.tunnelManager = manager
                        print("[VPNConfigManager] VPN隧道启动命令已发送")
                        completion(nil)
                    } catch {
                        print("[VPNConfigManager] 启动隧道失败: \(error)")
                        completion(error)
                    }
                }
            }
        }
    }
    
    @objc public func stopVPN(completion: @escaping (Error?) -> Void) {
        print("[VPNConfigManager] 停止VPN命令已发送")
        tunnelManager?.connection.stopVPNTunnel()
        completion(nil)
    }
    
    // MARK: - VPN 状态管理
    @objc func getVPNStatus() -> Int {
        return tunnelManager?.connection.status.rawValue ?? 0
    }
    
    @objc public func addStatusObserver(completion: @escaping (Int) -> Void) {
        // 移除现有观察者
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // 添加新观察者
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { notification in
            if let connection = notification.object as? NEVPNConnection {
                completion(connection.status.rawValue)
            }
        }
    }
    
    // MARK: - 连接信息
    @objc public func getConnectionInfo() -> [String: Any] {
        guard let session = tunnelManager?.connection as? NETunnelProviderSession else {
            return [:]
        }
        
        var info: [String: Any] = [:]
        info["status"] = session.status.rawValue
        
        if let startDate = session.connectedDate {
            info["connectedSince"] = startDate
        }
        
        return info
    }
}
