//
//  NimbusAdType+AdMob.swift
//  Nimbus
//  Created on 2/24/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit
import GoogleMobileAds

public extension AdController.AdRenderType {
    func adMobSignalRequest(
        adUnitId: String,
        bannerSize: CGSize? = nil,
        nativeAdOptions: AdMobNativeAdOptions? = nil
    ) throws -> SignalRequest {
        let signalRequest = try signalFromAdType(bannerSize: bannerSize, nativeAdOptions: nativeAdOptions)
        signalRequest.adUnitID = adUnitId
        signalRequest.requestAgent = "nimbus"
        
        let extras = Extras()
        extras.additionalParameters = ["query_info_type": "requester_type_2"]
        signalRequest.register(extras)
        return signalRequest
    }
    
    internal func adMobSignalRequest(
        from request: NimbusRequest,
        adUnitId: String,
        nativeAdOptions: AdMobNativeAdOptions? = nil
    ) throws -> SignalRequest {
        return try adMobSignalRequest(adUnitId: adUnitId, bannerSize: request.bannerSize, nativeAdOptions: nativeAdOptions)
    }
    
    private func signalFromAdType(
        bannerSize: CGSize? = nil,
        nativeAdOptions: AdMobNativeAdOptions? = nil
    ) throws -> SignalRequest {
        switch self {
        case .banner:
            guard let bannerSize else {
                throw NimbusError.admob(reason: .invalidState, stage: .request, detail: "Ad size is missing")
            }
            
            let signalRequest = BannerSignalRequest(signalType: "requester_type_2")
            signalRequest.adSize = adSizeFor(cgSize: bannerSize)
            return signalRequest
        case .native:
            guard let nativeAdOptions else {
                throw NimbusError.admob(reason: .misconfiguration, stage: .request, detail: "Native ad options are missing")
            }
            
            let signal = NativeSignalRequest(signalType: "requester_type_2")
            signal.isImageLoadingDisabled = nativeAdOptions.disableImageLoading
            signal.shouldRequestMultipleImages = nativeAdOptions.shouldRequestMultipleImages
            signal.mediaAspectRatio = nativeAdOptions.mediaAspectRatio
            signal.preferredAdChoicesPosition = nativeAdOptions.preferredAdChoicesPosition
            signal.isCustomMuteThisAdRequested = nativeAdOptions.customMuteThisAdRequested
            return signal
        case .interstitial:
            return InterstitialSignalRequest(signalType: "requester_type_2")
        case .rewarded:
            return RewardedSignalRequest(signalType: "requester_type_2")
        @unknown default:
            throw NimbusError.admob(reason: .unsupported, stage: .request, detail: rawValue)
        }
    }
}
