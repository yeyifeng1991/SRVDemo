//
//  NEKitTool.swift
//  SRVDemo
//
//  Created by yyf on 2025/6/20.
//

import Foundation
import NEKit
import NetworkExtension
import ObjectiveC

// 使用 MainActor 确保在主队列上访问
private class TunnelManager {
    static let shared = TunnelManager()
        private init() {}
        
        private var tunnelsMap: [ObjectIdentifier: [Tunnel]] = [:]
        
        func setTunnels(_ tunnels: [Tunnel], for server: GCDSOCKS5ProxyServer) {
            tunnelsMap[ObjectIdentifier(server)] = tunnels
        }
        
        func hasTunnels(for server: GCDSOCKS5ProxyServer) -> Bool {
            return tunnelsMap[ObjectIdentifier(server)] != nil
        }
        
        func applyRuleManager(_ ruleManager: RuleManager, to server: GCDSOCKS5ProxyServer) async {
            guard let tunnels = tunnelsMap[ObjectIdentifier(server)] else { return }
            
            // 由于可能涉及 UI 更新，在主队列上执行
            await MainActor.run {
                for tunnel in tunnels {
                    if let ruleSupport = tunnel as? RuleSupporting {
                        ruleSupport.applyRuleManager(ruleManager as AnyObject)
                    } else {
                        tunnel.ruleManager = ruleManager
                    }
                }
            }
        }
}
// MARK: - 规则管理器支持
private enum RuleManagerAssociatedKeys {
    static func ruleManagerKey() -> UnsafeRawPointer {
        return UnsafeRawPointer(bitPattern: "ruleManagerKey".hashValue)!
    }
}

extension GCDSOCKS5ProxyServer {
    public var ruleManager: RuleManager? {
           get {
               return objc_getAssociatedObject(self, RuleManagerAssociatedKeys.ruleManagerKey()) as? RuleManager
           }
           set {
               objc_setAssociatedObject(
                   self,
                   RuleManagerAssociatedKeys.ruleManagerKey(),
                   newValue,
                   .OBJC_ASSOCIATION_RETAIN_NONATOMIC
               )
               
               if let ruleManager = newValue {
                   // 在 async 任务中调用
                   Task { @MainActor in
                       await applyRuleManager(ruleManager)
                   }
               }
           }
       }
       
    private func applyRuleManager(_ ruleManager: RuleManager) async {
        // 尝试多种方式获取隧道
        if let tunnels = getTunnelsByKVC() {
            await TunnelManager.shared.setTunnels(tunnels, for: self)
            await TunnelManager.shared.applyRuleManager(ruleManager, to: self)
            return
        }
        
        if let tunnels = await getTunnelsByRuntime() {
            await TunnelManager.shared.setTunnels(tunnels, for: self)
            await TunnelManager.shared.applyRuleManager(ruleManager, to: self)
            return
        }
        
        // 所有对 TunnelManager 的访问都需要使用 await
              if await TunnelManager.shared.hasTunnels(for: self) {
                  await TunnelManager.shared.applyRuleManager(ruleManager, to: self)
                  return
              }
        print("⚠️ 无法获取隧道列表，规则应用失败")
    }
    private func getTunnelsByKVC() -> [Tunnel]? {
          do {
              if let tunnels = self.value(forKey: "tunnels") as? [Tunnel] {
                  return tunnels
              }
              if let tunnels = self.value(forKey: "_tunnels") as? [Tunnel] {
                  return tunnels
              }
          } catch {
              print("⚠️ KVC获取隧道出错: \(error)")
          }
          return nil
      }
      
      private func getTunnelsByRuntime() async -> [Tunnel]? {
          if self.responds(to: Selector("tunnels")) {
              if let tunnels = self.perform(Selector("tunnels"))?.takeUnretainedValue() as? [Tunnel] {
                  return tunnels
              }
          }
          
          var classMethodList: [String] = []
          var count: UInt32 = 0
          
          if let methods = class_copyMethodList(object_getClass(self), &count) {
              for i in 0..<count {
                  let methodName = String(cString: sel_getName(method_getName(methods[Int(i)])))
                  classMethodList.append(methodName)
              }
              free(methods)
          }
          
          for methodName in classMethodList where methodName.contains("tunnel") {
              if let tunnels = self.perform(Selector(methodName))?.takeUnretainedValue() as? [Tunnel] {
                  return tunnels
              }
          }
          
          return nil
      }
    
    private func applyToTunnels(_ tunnels: [Tunnel], ruleManager: RuleManager) {
        for tunnel in tunnels {
            if let ruleSupport = tunnel as? RuleSupporting {
                ruleSupport.applyRuleManager(ruleManager as AnyObject)
            } else {
                tunnel.ruleManager = ruleManager
            }
        }
    }
}


// MARK: - 规则支持协议 (Objective-C 兼容)
@objc protocol RuleSupporting {
    @objc func applyRuleManager(_ manager: AnyObject)
}

// MARK: - SOCKS5 代理套接字规则支持
extension SOCKS5ProxySocket: RuleSupporting {
    func applyRuleManager(_ manager: AnyObject) {
        // 使用 KVC 设置规则管理器
        self.setValue(manager, forKey: "ruleManager")
    }
}

// MARK: - 隧道规则支持
private enum TunnelRuleManagerAssociatedKeys {
    static func ruleManagerKey() -> UnsafeRawPointer {
        return UnsafeRawPointer(bitPattern: "tunnelRuleManagerKey".hashValue)!
    }
}

extension Tunnel {
    var ruleManager: RuleManager? {
        get {
            return objc_getAssociatedObject(self, TunnelRuleManagerAssociatedKeys.ruleManagerKey()) as? RuleManager
        }
        set {
            objc_setAssociatedObject(
                self,
                TunnelRuleManagerAssociatedKeys.ruleManagerKey(),
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            applyRuleManagerToSocket()
        }
    }
    
    func applyRuleManager(_ manager: RuleManager) {
        ruleManager = manager
    }
    
    private func applyRuleManagerToSocket() {
        guard let ruleManager = ruleManager else { return }
        
        // 安全访问 proxySocket 属性
        guard let socket = self.value(forKey: "proxySocket") as? RuleSupporting else {
            print("⚠️ 无法访问 proxySocket 属性")
            return
        }
        
        // 使用 AnyObject 传递
        socket.applyRuleManager(ruleManager as AnyObject)
    }
}

// MARK: - 加密算法转换（Objective-C 兼容）
@objc public class CryptoAlgorithmConverter: NSObject {
    // 返回加密算法的字符串表示
    @objc public static func convertToNEKitAlgorithmString(_ encryption: String) -> String {
        // 统一转换为大写并去除空格
        let normalized = encryption
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
        
        switch normalized {
        case "AES-128-CFB", "AES128CFB":
            return "AES128CFB"
        case "AES-192-CFB", "AES192CFB":
            return "AES192CFB"
        case "AES-256-CFB", "AES256CFB":
            return "AES256CFB"
        case "CHACHA20", "CHACHA20-IETF":
            return "CHACHA20"
        case "SALSA20":
            return "SALSA20"
        case "RC4-MD5", "RC4MD5":
            return "RC4MD5"
        case "AES-256-GCM":
            print("⚠️ AES-256-GCM 不支持，使用 AES-256-CFB 代替")
            return "AES256CFB"
        case "CHACHA20-IETF-POLY1305":
            print("⚠️ ChaCha20-IETF-Poly1305 不支持，使用 ChaCha20 代替")
            return "CHACHA20"
        default:
            print("⚠️ 不支持的加密算法 '\(encryption)'. 使用默认的 AES-256-CFB")
            return "AES256CFB"
        }
    }
}

// MARK: - 代理包装器
@objc public class NEKitProxyWrapper: NSObject {
    private var proxyServer: GCDSOCKS5ProxyServer?
    
    @objc public func setupShadowSocksProxy(serverAddress: String,
                                           port: UInt16,
                                           password: String,
                                           encryption: String) {
        // 配置 SS 代理服务器
        let portObj = Port(port: port)
        
        // 转换加密算法为字符串
        let algorithmString = CryptoAlgorithmConverter.convertToNEKitAlgorithmString(encryption)
        
        // 手动创建加密算法枚举
        let algorithm: CryptoAlgorithm
        switch algorithmString {
        case "AES128CFB": algorithm = .AES128CFB
        case "AES192CFB": algorithm = .AES192CFB
        case "AES256CFB": algorithm = .AES256CFB
        case "CHACHA20": algorithm = .CHACHA20
        case "SALSA20": algorithm = .SALSA20
        case "RC4MD5": algorithm = .RC4MD5
        default: algorithm = .AES256CFB
        }
        
        let cryptorFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(
            password: password,
            algorithm: algorithm
        )
        
        // 创建 Shadowsocks 适配器工厂
        let ssAdapterFactory = ShadowsocksAdapterFactory(
            serverHost: serverAddress,
            serverPort: Int(portObj.value),
            protocolObfuscaterFactory: ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory(),
            cryptorFactory: cryptorFactory,
            streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.Factory()
        )
        
        // 创建代理规则（所有流量走代理）
        let proxyRule = AllRule(adapterFactory: ssAdapterFactory)
        
        // 创建规则列表
        let rules: [Rule] = [proxyRule]
        
        // 添加直连规则（可选）
        // let directDomains = ["apple.com", "google.com", "example.com"]
        // let directRule = DomainListRule(domains: directDomains, adapterFactory: DirectAdapterFactory())
        // rules.append(directRule)
        
        // 创建规则管理器
        let ruleManager = RuleManager(fromRules: rules, appendDirect: false)
        
        // 创建代理服务器（绑定到本地回环地址）
        let localhost = IPAddress(fromString: "127.0.0.1")!
        let proxyServer = GCDSOCKS5ProxyServer(address: localhost, port: Port(port: 1080))
        
        // 设置规则管理器
        proxyServer.ruleManager = ruleManager
        
        self.proxyServer = proxyServer
    }
    
    @objc public func startProxy() throws {
        guard let server = proxyServer else {
            throw NSError(domain: "NEKitError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "代理服务器未初始化"])
        }
        try server.start()
    }
    
    @objc public func stopProxy() {
        proxyServer?.stop()
        proxyServer = nil
    }
}
