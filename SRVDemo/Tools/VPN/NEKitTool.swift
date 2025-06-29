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

// MARK: - 安全的隧道管理器
private class TunnelManager {
    @MainActor static let shared = TunnelManager()
    private init() {}
    
    private var tunnelsMap: [ObjectIdentifier: [WeakTunnelRef]] = [:]
    
    func setTunnels(_ tunnels: [Tunnel], for server: GCDSOCKS5ProxyServer) {
        let weakRefs = tunnels.map { WeakTunnelRef(tunnel: $0) }
        tunnelsMap[ObjectIdentifier(server)] = weakRefs
    }
    
    func hasTunnels(for server: GCDSOCKS5ProxyServer) -> Bool {
        return !(tunnelsMap[ObjectIdentifier(server)]?.isEmpty ?? true)
    }
    
    func applyRuleManager(_ ruleManager: RuleManager, to server: GCDSOCKS5ProxyServer) async {
        guard let weakRefs = tunnelsMap[ObjectIdentifier(server)] else { return }
        
        // 过滤掉已被释放的隧道
        let activeTunnels = weakRefs.compactMap { $0.tunnel }
        
        await MainActor.run {
            for tunnel in activeTunnels {
                if let ruleSupport = tunnel as? RuleSupporting {
                    ruleSupport.applyRuleManager(ruleManager as AnyObject)
                } else {
                    tunnel.ruleManager = ruleManager
                }
            }
        }
    }
}

// 弱引用包装器
private class WeakTunnelRef {
    weak var tunnel: Tunnel?
    init(tunnel: Tunnel) {
        self.tunnel = tunnel
    }
}

// MARK: - 规则管理器支持
private enum RuleManagerAssociatedKeys {
    static var ruleManagerKey: UInt8 = 0
}

extension GCDSOCKS5ProxyServer {
    public var ruleManager: RuleManager? {
        get {
            return objc_getAssociatedObject(self, &RuleManagerAssociatedKeys.ruleManagerKey) as? RuleManager
        }
        set {
            objc_setAssociatedObject(
                self,
                &RuleManagerAssociatedKeys.ruleManagerKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            
            if let ruleManager = newValue {
                Task { @MainActor in
                    await applyRuleManager(ruleManager)
                }
            }
        }
    }
    
    // 修改 GCDSOCKS5ProxyServer 扩展
    private func applyRuleManager(_ ruleManager: RuleManager) async {
        // 先尝试直接设置规则（优先级最高）
        do {
            try await attemptDirectRuleApplication(ruleManager)
            print("✅ 直接规则设置成功")
            return
        } catch {
            print("⚠️ 直接规则设置失败: \(error.localizedDescription)")
        }
        
        // 再尝试通过隧道设置规则
        let maxAttempts = 5
        var tunnels: [Tunnel]?
        
        for attempt in 1...maxAttempts {
            tunnels = getTunnelsByRuntime()
            if let tunnels = tunnels, !tunnels.isEmpty {
                print("✅ 获取隧道成功 (数量: \(tunnels.count))")
                await TunnelManager.shared.setTunnels(tunnels, for: self)
                await TunnelManager.shared.applyRuleManager(ruleManager, to: self)
                return
            }
            
            if attempt < maxAttempts {
                print("⚠️ 隧道获取失败 (尝试 \(attempt)/\(maxAttempts))，等待重试...")
                try? await Task.sleep(nanoseconds: 300 * 1_000_000) // 300ms
            }
        }
        
        // 最终回退到直接设置
        print("⚠️ 最终尝试直接设置规则")
        try? await attemptDirectRuleApplication(ruleManager)
    }

    // 增强的直接规则应用方法
    private func attemptDirectRuleApplication(_ ruleManager: RuleManager) async throws {
        // 尝试多种设置方式
        let selectors = [
            "setRuleManager:", "applyRuleManager:",
            "configureWithRules:", "updateRules:"
        ]
        
        for selectorName in selectors {
            let selector = Selector(selectorName)
            if responds(to: selector) {
                print("✅ 通过 \(selectorName) 设置规则")
                perform(selector, with: ruleManager)
                return
            }
        }
        
        // 尝试 KVC 方式
        if responds(to: Selector("setRuleManager:")) {
            setValue(ruleManager, forKey: "ruleManager")
            print("✅ 通过 KVC 设置规则")
            return
        }
        
        throw NSError(domain: "NEKitError", code: 3001, userInfo: [
            NSLocalizedDescriptionKey: "无可用规则设置方法"
        ])
    }
    
    private func getTunnelsByRuntime() -> [Tunnel]? {
        // 1. 尝试直接调用tunnels方法
        if responds(to: Selector("tunnels")),
           let result = perform(Selector("tunnels")),
           let tunnels = result.takeUnretainedValue() as? [Tunnel] {
            return tunnels
        }
        
        // 2. 尝试其他可能的方法名
        let possibleSelectors = [
            "activeTunnels", "currentTunnels", "getTunnels",
            "allTunnels", "_tunnels", "tunnelList"
        ]
        
        for selectorName in possibleSelectors {
            let selector = Selector(selectorName)
            if responds(to: selector),
               let result = perform(selector),
               let tunnels = result.takeUnretainedValue() as? [Tunnel] {
                return tunnels
            }
        }
        
        // 3. 打印可用方法名用于调试
        #if DEBUG
        printAvailableMethods()
        #endif
        
        return nil
    }
    
    #if DEBUG
    private func printAvailableMethods() {
        var methodList: [String] = []
        var count: UInt32 = 0
        
        guard let methods = class_copyMethodList(object_getClass(self), &count) else { return }
        
        defer { free(methods) }
        
        print("⚠️ 可用方法列表:")
        for i in 0..<Int(count) {
            let methodName = String(cString: sel_getName(method_getName(methods[i])))
            methodList.append(methodName)
            print("- \(methodName)")
        }
    }
    #endif
}

// MARK: - 规则支持协议
@objc protocol RuleSupporting {
    @objc func applyRuleManager(_ manager: AnyObject)
}

// MARK: - SOCKS5 代理套接字规则支持
extension SOCKS5ProxySocket: RuleSupporting {
    func applyRuleManager(_ manager: AnyObject) {
        // 使用安全的方法调用
        if responds(to: Selector("setRuleManager:")) {
            perform(Selector("setRuleManager:"), with: manager)
        }
    }
    
}

// MARK: - 隧道规则支持
private enum TunnelRuleManagerAssociatedKeys {
    static var ruleManagerKey: UInt8 = 0
}

extension Tunnel {
    var ruleManager: RuleManager? {
        get {
            return objc_getAssociatedObject(self, &TunnelRuleManagerAssociatedKeys.ruleManagerKey) as? RuleManager
        }
        set {
            objc_setAssociatedObject(
                self,
                &TunnelRuleManagerAssociatedKeys.ruleManagerKey,
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
        
        // 安全访问proxySocket属性
        let socket = getProxySocketSafely()
        socket?.applyRuleManager(ruleManager as AnyObject)
    }
    
    private func getProxySocketSafely() -> RuleSupporting? {
        // 尝试多种可能的访问方式
        if responds(to: Selector("proxySocket")),
           let result = perform(Selector("proxySocket")),
           let socket = result.takeUnretainedValue() as? RuleSupporting {
            return socket
        }
        
        if responds(to: Selector("socket")),
           let result = perform(Selector("socket")),
           let socket = result.takeUnretainedValue() as? RuleSupporting {
            return socket
        }
        
        if responds(to: Selector("currentSocket")),
           let result = perform(Selector("currentSocket")),
           let socket = result.takeUnretainedValue() as? RuleSupporting {
            return socket
        }
        
        print("⚠️ 无法访问 proxySocket 属性")
        return nil
    }
}

// MARK: - 加密算法转换
@objc public class CryptoAlgorithmConverter: NSObject {
    @objc public static func convertToNEKitAlgorithmString(_ encryption: String) -> String {
        let normalized = encryption
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
        
        switch normalized {
        case "AES-128-CFB", "AES128CFB": return "AES128CFB"
        case "AES-192-CFB", "AES192CFB": return "AES192CFB"
        case "AES-256-CFB", "AES256CFB": return "AES256CFB"
        case "CHACHA20", "CHACHA20-IETF": return "CHACHA20"
        case "SALSA20": return "SALSA20"
        case "RC4-MD5", "RC4MD5": return "RC4MD5"
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
        let portObj = Port(port: port)
        // 添加对 ChaCha20-IETF-Poly1305 的支持
           let algorithmString = encryption.uppercased().replacingOccurrences(of: " ", with: "")
           
           let algorithm: CryptoAlgorithm
           switch algorithmString {
           case "AES-128-CFB", "AES128CFB": algorithm = .AES128CFB
           case "AES-192-CFB", "AES192CFB": algorithm = .AES192CFB
           case "AES-256-CFB", "AES256CFB": algorithm = .AES256CFB
           case "CHACHA20", "CHACHA20-IETF": algorithm = .CHACHA20
           case "CHACHA20-IETF-POLY1305":
               algorithm = .CHACHA20  // 使用 ChaCha20 替代
               print("⚠️ 使用 ChaCha20 替代 ChaCha20-IETF-Poly1305")
           case "SALSA20": algorithm = .SALSA20
           case "RC4-MD5", "RC4MD5": algorithm = .RC4MD5
           case "AES-256-GCM":
               algorithm = .CHACHA20  // 将 GCM 回退到 ChaCha20
               print("⚠️ 使用 ChaCha20 替代 AES-256-GCM")
           default:
               algorithm = .AES256CFB
               print("⚠️ 使用默认算法 AES-256-CFB")
           }
        let cryptorFactory = ShadowsocksAdapter.CryptoStreamProcessor.Factory(
            password: password,
            algorithm: algorithm
        )
        
        let ssAdapterFactory = ShadowsocksAdapterFactory(
            serverHost: serverAddress,
            serverPort: Int(portObj.value),
            protocolObfuscaterFactory: ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory(),
            cryptorFactory: cryptorFactory,
            streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.Factory()
        )
        
        let proxyRule = AllRule(adapterFactory: ssAdapterFactory)
        let ruleManager = RuleManager(fromRules: [proxyRule], appendDirect: false)
        let localhost = IPAddress(fromString: "127.0.0.1")!
        // 使用随机端口避免冲突
         let randomLocalPort = UInt16.random(in: 10000..<60000)
         let proxyServer = GCDSOCKS5ProxyServer(
             address: localhost,
             port: Port(port: randomLocalPort)  // 使用随机端口
         )
         
         print("xh✅ 使用本地端口: \(randomLocalPort)")
        
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
