//
//  TrojanAdapterFactory.swift
//  PacketTunnel
//
//  Created by yyf on 2025/7/1.
//

import Foundation
import NEKit

class TrojanAdapterFactory: AdapterFactory {
    private let config: TrojanConfiguration
    
    init(config: TrojanConfiguration) {
        self.config = config
    }
    
    override func getAdapterFor(session: ConnectSession) -> AdapterSocket {
        return TrojanAdapter(config: config)
    }
}
