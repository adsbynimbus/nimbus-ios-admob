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
    let nativeAdOptions: AdMobNativeAdOptions?
    private let bridge: AdMobRequestBridgeType
    
    init(
        adUnitId: String,
        adRenderType: AdController.AdRenderType,
        nativeAdOptions: AdMobNativeAdOptions? = nil,
        bridge: AdMobRequestBridgeType = AdMobRequestBridge()
    ) {
        self.adUnitId = adUnitId
        self.adRenderType = adRenderType
        self.nativeAdOptions = nativeAdOptions
        self.bridge = bridge
    }
}

extension NimbusAdMobRequestInterceptor: NimbusRequest.Interceptor {
    func modifyRequest(request: NimbusRequest) async throws -> [NimbusRequest.Delta] {
        let signalRequest = try adRenderType.adMobSignalRequest(from: request, adUnitId: adUnitId, nativeAdOptions: nativeAdOptions)
        let signal = try await bridge.generateSignal(request: signalRequest)
        
        try Task.checkCancellation()
        return [.init(target: .user, key: "admob_gde_signals", value: signal)]
    }
}
