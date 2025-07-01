//
//  Logging.swift
//  PacketTunnel
//
//  Created by yyf on 2025/7/1.
//

import Foundation
import os.log

struct Logger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.your.vpn"
    
    static func log(level: OSLogType, message: String, category: String = "Default") {
        let log = OSLog(subsystem: subsystem, category: category)
        os_log("%{public}@", log: log, type: level, message)
    }
    
    static func info(_ message: String, category: String = "Default") {
        log(level: .info, message: "ℹ️ \(message)", category: category)
    }
    
    static func debug(_ message: String, category: String = "Default") {
        log(level: .debug, message: "🐞 \(message)", category: category)
    }
    
    static func error(_ message: String, category: String = "Default") {
        log(level: .error, message: "❌ \(message)", category: category)
    }
}
