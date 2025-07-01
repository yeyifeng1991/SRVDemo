//
//  TrojanAdapter.swift
//  PacketTunnel
//
//  Created by yyf on 2025/7/1.
//

import Foundation
import NEKit
import Network
import CryptoKit

class TrojanAdapter: AdapterSocket {
    enum TrojanError: Error {
        case invalidAddress
        case connectionFailed
        case authenticationFailed
        case invalidResponse
        case encryptionError
        case invalidSession
    }
    
    private let config: TrojanConfiguration
    private var connection: NWConnection?
    private var state: State = .idle
    private var pendingData: Data?
    
    private enum State {
        case idle
        case connecting
        case authenticating
        case readingResponse
        case ready
        case stopped
    }
    
    init(config: TrojanConfiguration) {
        self.config = config
        super.init()
    }
    
    // 使用正确的方法签名覆盖基类方法
    override func openSocketWith(session: ConnectSession) {
        super.openSocketWith(session: session)
        
        Logger.info("开始创建Trojan连接: \(session.host):\(session.port)", category: "TrojanAdapter")
        
        guard let port = NWEndpoint.Port(rawValue: UInt16(config.port)) else {
            let error = TrojanError.invalidAddress
            Logger.error("无效的端口: \(config.port)", category: "TrojanAdapter")
            delegate?.didBecomeReadyToForwardWith(socket: self)
            delegate?.didDisconnectWith(socket: self)
            return
        }
        
        let host = NWEndpoint.Host(config.server)
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 10
        
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.prohibitedInterfaceTypes = [.cellular]
        
        connection = NWConnection(host: host, port: port, using: parameters)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        state = .connecting
        connection?.start(queue: .global(qos: .userInitiated))
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            Logger.info("Trojan连接已建立", category: "TrojanAdapter")
            sendAuthentication()
            
        case .failed(let error):
            Logger.error("Trojan连接失败: \(error.localizedDescription)", category: "TrojanAdapter")
            disconnect(becauseOf: error)
            
        case .cancelled:
            Logger.info("Trojan连接已取消", category: "TrojanAdapter")
            self.state = .stopped
            delegate?.didDisconnectWith(socket: self)
            
        default:
            break
        }
    }
    
    private func sendAuthentication() {
        guard let session = self.session else {
            Logger.error("会话信息缺失", category: "TrojanAdapter")
            disconnect(becauseOf: TrojanError.invalidSession)
            return
        }
        
        state = .authenticating
        
        // 1. 创建认证数据 (SHA-224哈希)
        let passwordData = Data(config.password.utf8)
        let hash = SHA224.hash(data: passwordData)  // 使用自定义的SHA224实现
        let hexHash = hash.map { String(format: "%02hhx", $0) }.joined()
        
        // 2. 创建请求数据 (认证哈希 + CRLF + 目标地址)
        var requestData = Data(hexHash.utf8)
        requestData.append(contentsOf: [0x0D, 0x0A]) // CRLF
        
        // 3. 添加目标地址信息
        let destinationHost = session.host
        let destinationPort = session.port
        
        // 判断目标地址类型
        if let ipv4 = IPv4Address(destinationHost) {
            requestData.append(0x01) // IPv4
            requestData.append(contentsOf: ipv4.rawValue)
        } else if let ipv6 = IPv6Address(destinationHost) {
            requestData.append(0x04) // IPv6
            requestData.append(contentsOf: ipv6.rawValue)
        } else {
            // 域名
            requestData.append(0x03) // Domain
            let domainData = Data(destinationHost.utf8)
            requestData.append(UInt8(domainData.count))
            requestData.append(domainData)
        }
        
        // 4. 添加端口 (大端序)
        requestData.append(UInt8(destinationPort >> 8))
        requestData.append(UInt8(destinationPort & 0xFF))
        
        // 5. 发送认证数据
        connection?.send(content: requestData, completion: .contentProcessed { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.error("Trojan认证发送失败: \(error.localizedDescription)", category: "TrojanAdapter")
                self.disconnect(becauseOf: error)
            } else {
                Logger.debug("Trojan认证信息已发送", category: "TrojanAdapter")
                self.state = .readingResponse
                self.readDataFromRemote()
            }
        })
    }
    
    private func readDataFromRemote() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, _, error in
            guard let self = self else { return }
            
            if let error = error {
                Logger.error("从Trojan服务器接收数据失败: \(error.localizedDescription)", category: "TrojanAdapter")
                self.disconnect(becauseOf: error)
                return
            }
            
            if let data = data, !data.isEmpty {
                self.handleRemoteData(data)
            } else {
                // 没有数据，可能是连接关闭
                Logger.debug("从Trojan服务器接收空数据，可能连接已关闭", category: "TrojanAdapter")
                self.disconnect()
            }
        }
    }
    
    private func handleRemoteData(_ data: Data) {
        Logger.debug("从Trojan服务器收到数据: \(data.count) 字节", category: "TrojanAdapter")
        
        // 这里可以添加解密逻辑
        let decryptedData = decryptData(data)
        
        // 转发给本地客户端
        delegate?.didRead(data: decryptedData, from: self)
        
        // 继续读取数据
        readDataFromRemote()
    }
    
    override func didRead(data: Data, from: any RawTCPSocketProtocol) {
        Logger.debug("从本地客户端收到数据: \(data.count) 字节", category: "TrojanAdapter")
        
        // 这里可以添加加密逻辑
        let encryptedData = encryptData(data)
        
        // 发送到Trojan服务器
        connection?.send(content: encryptedData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.handleSendError(error)
            }
        })
    }
    

    
    private func encryptData(_ data: Data) -> Data {
        // 这里应该实现Trojan的加密逻辑
        // 简化版：直接返回原始数据（实际应用中应该使用加密）
        return data
    }
    
    private func decryptData(_ data: Data) -> Data {
        // 这里应该实现Trojan的解密逻辑
        // 简化版：直接返回原始数据（实际应用中应该使用解密）
        return data
    }
    
    private func handleSendError(_ error: Error) {
        Logger.error("向Trojan服务器发送数据失败: \(error.localizedDescription)", category: "TrojanAdapter")
        disconnect(becauseOf: error)
    }
    
    override func disconnect(becauseOf error: (any Error)? = nil) {
        Logger.info("Trojan适配器断开连接", category: "TrojanAdapter")
        state = .stopped
        connection?.cancel()
        connection = nil
        super.disconnect()
    }
    
  
    override func didDisconnectWith(socket: any RawTCPSocketProtocol) {
//        Logger.info("Trojan适配器已断开: \(sock ?? "无错误")", category: "TrojanAdapter")
        disconnect()
    }
    

    
    deinit {
        disconnect()
    }
}

// SHA224 自定义实现
struct SHA224 {
    static func hash(data: Data) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: 28)
        data.withUnsafeBytes { bytes in
            var context = SHA224_CTX()
            SHA224_Init(&context)
            SHA224_Update(&context, bytes.baseAddress, bytes.count)
            SHA224_Final(&hash, &context)
        }
        return hash
    }
}

// SHA224 结构体和函数声明
struct SHA224_CTX {
    var state: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0, 0, 0)
    var count: UInt64 = 0
    var buffer: [UInt8] = Array(repeating: 0, count: 64)
}

func SHA224_Init(_ context: inout SHA224_CTX) {
    context.state = (
        0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
        0xffc00b31, 0x68581511, 0x64f98fa7
    )
    context.count = 0
}

func SHA224_Update(_ context: inout SHA224_CTX, _ data: UnsafeRawPointer?, _ len: Int) {
    // 简化的实现，实际需要完整处理数据块
}

func SHA224_Final(_ md: inout [UInt8], _ context: inout SHA224_CTX) {
    // 简化的实现，实际需要完成哈希计算
}
