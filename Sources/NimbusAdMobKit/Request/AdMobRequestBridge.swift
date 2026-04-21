//
//  AdMobRequestBridge.swift
//  Nimbus
//  Created on 3/7/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import GoogleMobileAds

protocol AdMobRequestBridgeType: Sendable {
    func generateSignal(request: SignalRequest) async throws -> String
}

final class AdMobRequestBridge: AdMobRequestBridgeType {
    public init() {}
    
    @inlinable
    public static func set(coppa: Bool) {
        MobileAds
            .shared
            .requestConfiguration.tagForChildDirectedTreatment = NSNumber(booleanLiteral: coppa)
    }
    
    public func generateSignal(request: SignalRequest) async throws -> String {
        try await MobileAds.generateSignal(request).signal
    }
}
