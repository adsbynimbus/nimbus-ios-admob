//
//  AdMobDemand.swift
//  Nimbus
//  Created on 8/28/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit

/// Adds AdMob bidding to a Nimbus request.
///
/// Call from within a demand block:
/// ```swift
/// let bannerAd = Nimbus.bannerAd(position: "position") {
///     demand {
///         admob(bannerAdUnitId: "<adUnitId>")
///     }
/// }
/// ```
/// - Parameter bannerAdUnitId: The AdMob banner ad unit ID.
/// - Returns: A demand component representing AdMob bidding.
public func admob(bannerAdUnitId: String) -> DemandComponent {
    AdMob(adRenderType: .banner, adUnitId: bannerAdUnitId, nativeAdOptions: nil)
}

/// Adds AdMob bidding to a Nimbus request.
///
/// Call from within a demand block:
/// ```swift
/// let bannerAd = Nimbus.nativeAd(position: "position") {
///     demand {
///         admob(nativeAdUnitId: "<adUnitId>", options: NimbusAdMobNativeAdOptions())
///     }
/// }
/// ```
/// - Parameters:
///   - nativeAdUnitId: The AdMob native ad unit ID.
///   - options: Native ad options
/// - Returns: A demand component representing AdMob bidding.
public func admob(nativeAdUnitId: String, options: NimbusAdMobNativeAdOptions) -> DemandComponent {
    AdMob(adRenderType: .native, adUnitId: nativeAdUnitId, nativeAdOptions: options)
}

/// Adds AdMob bidding to a Nimbus request.
///
/// Call from within a demand block:
/// ```swift
/// let bannerAd = Nimbus.interstitialAd(position: "position") {
///     demand {
///         admob(interstitialAdUnitId: "<adUnitId>")
///     }
/// }
/// ```
/// - Parameter interstitialAdUnitId: The AdMob interstitial ad unit ID.
/// - Returns: A demand component representing AdMob bidding.
public func admob(interstitialAdUnitId: String) -> DemandComponent {
    AdMob(adRenderType: .interstitial, adUnitId: interstitialAdUnitId, nativeAdOptions: nil)
}

/// Adds AdMob bidding to a Nimbus request.
///
/// Call from within a demand block:
/// ```swift
/// let bannerAd = Nimbus.rewardedAd(position: "position") {
///     demand {
///         admob(rewardedAdUnitId: "<adUnitId>")
///     }
/// }
/// ```
/// - Parameter rewardedAdUnitId: The AdMob banner ad unit ID.
/// - Returns: A demand component representing AdMob bidding.
public func admob(rewardedAdUnitId: String) -> DemandComponent {
    AdMob(adRenderType: .rewarded, adUnitId: rewardedAdUnitId, nativeAdOptions: nil)
}

private struct AdMob: DemandComponent {
    let adRenderType: AdController.AdRenderType
    let adUnitId: String
    let nativeAdOptions: NimbusAdMobNativeAdOptions?
    
    func apply(to adRequest: AdRequest) -> AdRequest {
        var modified = adRequest
        modified.request.interceptors.append(NimbusAdMobRequestInterceptor(
            adUnitId: adUnitId,
            adRenderType: adRenderType,
            nativeAdOptions: nativeAdOptions
        ))
        
        return modified
    }
}
