//
//  NimbusAdMobRequestInterceptor.swift
//  NimbusAdMobKit
//  Created on 9/3/24
//  Copyright © 2024 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit
import GoogleMobileAds

final class NimbusAdMobRequestInterceptor {
    let adUnitId: String
    let adRenderType: AdController.AdRenderType
    let nativeAdOptions: NimbusAdMobNativeAdOptions?
    private let bridge: AdMobRequestBridgeType
    
    init(
        adUnitId: String,
        adRenderType: AdController.AdRenderType,
        nativeAdOptions: NimbusAdMobNativeAdOptions? = nil,
        bridge: AdMobRequestBridgeType = AdMobRequestBridge()
    ) {
        self.adUnitId = adUnitId
        self.adRenderType = adRenderType
        self.nativeAdOptions = nativeAdOptions
        self.bridge = bridge
    }
}

extension NimbusAdMobRequestInterceptor: NimbusRequestInterceptor {
    
    func modifyRequest(request: NimbusRequest) async throws -> NimbusRequestDelta {
        bridge.set(coppa: request.regs?.coppa)
        
        let signalRequest = try adRenderType.adMobSignalRequest(from: request, adUnitId: adUnitId, nativeAdOptions: nativeAdOptions)
        let signal = try await bridge.generateSignal(request: signalRequest)
        
        try Task.checkCancellation()
        return .admob(signal: signal)
    }
    
    func didCompleteNimbusRequest(with response: NimbusResponse) {
        Nimbus.Log.request.debug("Completed NimbusRequest for AdMob")
    }
    
    func didFailNimbusRequest(with error: any NimbusError) {
        Nimbus.Log.request.error("Failed NimbusRequest for AdMob")
    }
}
