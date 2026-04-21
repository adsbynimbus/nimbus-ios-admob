//
//  NimbusRequestAdMobTests.swift
//  NimbusAdMobKitTests
//  Created on 9/16/24
//  Copyright © 2024 Nimbus Advertising Solutions Inc. All rights reserved.
//

import XCTest
@testable import NimbusAdMobKit
@testable import NimbusKit
import NimbusKit
import GoogleMobileAds

final class NimbusRequestAdMobTests: XCTestCase {
    @MainActor
    func test_admob_banner_interceptor_gets_added() throws {
        let ad = try Nimbus.bannerAd(position: "pos", size: .banner) {
            admob(bannerAdUnitId: "bannerPlacement")
        }
        
        let interceptor = ad.adRequest!.request.interceptors[0] as! NimbusAdMobRequestInterceptor
        
        XCTAssertEqual(interceptor.adUnitId, "bannerPlacement")
        XCTAssertEqual(interceptor.adRenderType, .banner)
    }
    
    @MainActor
    func test_admob_native_interceptor_gets_added() throws {
        let options = AdMobNativeAdOptions(
            disableImageLoading: false,
            shouldRequestMultipleImages: true,
            mediaAspectRatio: .landscape,
            preferredAdChoicesPosition: .topLeftCorner,
            customMuteThisAdRequested: false)
        
        let ad = try Nimbus.inlineAd(position: "pos") {
            native()
            admob(nativeAdUnitId: "nativePlacement", options: options)
        }
        
        let interceptor = ad.adRequest!.request.interceptors[0] as! NimbusAdMobRequestInterceptor
        
        XCTAssertEqual(interceptor.adUnitId, "nativePlacement")
        XCTAssertEqual(interceptor.adRenderType, .native)
        XCTAssertEqual(interceptor.nativeAdOptions?.disableImageLoading, options.disableImageLoading)
        XCTAssertEqual(interceptor.nativeAdOptions?.shouldRequestMultipleImages, options.shouldRequestMultipleImages)
        XCTAssertEqual(interceptor.nativeAdOptions?.mediaAspectRatio, options.mediaAspectRatio)
        XCTAssertEqual(interceptor.nativeAdOptions?.preferredAdChoicesPosition, options.preferredAdChoicesPosition)
        XCTAssertEqual(interceptor.nativeAdOptions?.customMuteThisAdRequested, options.customMuteThisAdRequested)
    }
    
    @MainActor
    func test_admob_interstitial_interceptor_gets_added() throws {
        let ad = try Nimbus.interstitialAd(position: "pos") {
            admob(interstitialAdUnitId: "interstitialPlacement")
        }
        
        let interceptor = ad.adRequest!.request.interceptors[0] as! NimbusAdMobRequestInterceptor
        
        XCTAssertEqual(interceptor.adUnitId, "interstitialPlacement")
        XCTAssertEqual(interceptor.adRenderType, .interstitial)
    }
    
    @MainActor
    func test_admob_rewarded_interceptor_gets_added() throws {
        let ad = try Nimbus.rewardedAd(position: "pos") {
            admob(rewardedAdUnitId: "rewardedPlacement")
        }
        let interceptor = ad.adRequest!.request.interceptors[0] as! NimbusAdMobRequestInterceptor
        
        XCTAssertEqual(interceptor.adUnitId, "rewardedPlacement")
        XCTAssertEqual(interceptor.adRenderType, .rewarded)
    }
}

extension AdMobNativeAdOptions: Equatable {
    public static func == (lhs: AdMobNativeAdOptions, rhs: AdMobNativeAdOptions) -> Bool {
        lhs.disableImageLoading == rhs.disableImageLoading &&
        lhs.shouldRequestMultipleImages == rhs.shouldRequestMultipleImages &&
        lhs.mediaAspectRatio == rhs.mediaAspectRatio &&
        lhs.preferredAdChoicesPosition == rhs.preferredAdChoicesPosition &&
        lhs.customMuteThisAdRequested == rhs.customMuteThisAdRequested
    }
}
