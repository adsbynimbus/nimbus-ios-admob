//
//  NimbusAdMobRequestInterceptorTests.swift
//  NimbusAdMobKitTests
//  Created on 9/12/24
//  Copyright © 2024 Nimbus Advertising Solutions Inc. All rights reserved.
//

@testable import NimbusAdMobKit
@testable import NimbusKit
import NimbusKit
import GoogleMobileAds
import Testing

@Suite("AdMob interceptor tests")
struct NimbusAdMobInterceptorAsyncTests {
    @Test func signalDoesntGetAttachedWhenSignalFailed() async {
        let interceptor = NimbusAdMobRequestInterceptor(
            adUnitId: "adUnit",
            adRenderType: .interstitial,
            bridge: MockRequestBridge { _ in throw SignalError() }
        )
        
        await #expect(throws: SignalError.self) {
            let info = try await NimbusRequest(from: Nimbus.bannerAd(position: "pos", size: .banner).adRequest!.request)
            _ = try await interceptor.modifyRequest(request: info)
        }
    }
    
    @Test func signalGetsAttachedToRequest() async throws {
        let interceptor = NimbusAdMobRequestInterceptor(
            adUnitId: "adUnit",
            adRenderType: .banner,
            bridge: MockRequestBridge { _ in "signalData" }
        )
        
        let request = try await NimbusRequest(from: Nimbus.bannerAd(position: "pos", size: .banner).adRequest!.request)
        let deltas = try await interceptor.modifyRequest(request: request)
        
        #expect(deltas.count == 1)
        #expect(deltas[0].target == .user)
        #expect(deltas[0].key == "admob_gde_signals")
        #expect(deltas[0].value as? String == "signalData")
    }
    
    @Test func bannerGeneratesCorrectSignalRequest() async throws {
        let adType = AdController.AdRenderType.banner
        var request = try await NimbusRequest(from: Nimbus.bannerAd(position: "pos", size: .banner).adRequest!.request)
        var signalRequest = try adType.adMobSignalRequest(from: request, adUnitId: "adUnit") as? BannerSignalRequest
        
        #expect(signalRequest != nil)
        assertSignal(request: signalRequest)
        #expect(signalRequest?.adSize.size.width == 320)
        #expect(signalRequest?.adSize.size.height == 50)
        
        request = try await NimbusRequest(from: Nimbus.bannerAd(position: "pos", size: .mrec).adRequest!.request)
        signalRequest = try adType.adMobSignalRequest(from: request, adUnitId: "adUnit") as? BannerSignalRequest
        #expect(signalRequest != nil)
        assertSignal(request: signalRequest)
        #expect(signalRequest?.adSize.size.width == 300)
        #expect(signalRequest?.adSize.size.height == 250)
    }
    
    @Test func nativeGeneratesCorrectSignalRequest() async throws {
        let options = AdMobNativeAdOptions(
            disableImageLoading: true,
            shouldRequestMultipleImages: true,
            mediaAspectRatio: .portrait,
            preferredAdChoicesPosition: .bottomLeftCorner,
            customMuteThisAdRequested: true)
        
        let adType = AdController.AdRenderType.native
        
        let ad = try await Nimbus.inlineAd(position: "pos") { native() }
        let info = try await NimbusRequest(from: ad.adRequest!.request)
        var signalRequest = try adType.adMobSignalRequest(
            from: info,
            adUnitId: "adUnit",
            nativeAdOptions: options
        ) as? NativeSignalRequest
        
        #expect(signalRequest != nil)
        assertSignal(request: signalRequest)
        #expect(signalRequest?.isImageLoadingDisabled == options.disableImageLoading)
        #expect(signalRequest?.shouldRequestMultipleImages == options.shouldRequestMultipleImages)
        #expect(signalRequest?.mediaAspectRatio == options.mediaAspectRatio)
        #expect(signalRequest?.preferredAdChoicesPosition == options.preferredAdChoicesPosition)
        #expect(signalRequest?.isCustomMuteThisAdRequested == options.customMuteThisAdRequested)
        
        // Test default native ad options
        signalRequest = try adType.adMobSignalRequest(
            from: info,
            adUnitId: "adUnit",
            nativeAdOptions: AdMobNativeAdOptions()
        ) as? NativeSignalRequest
        
        #expect(signalRequest != nil)
        assertSignal(request: signalRequest)
        #expect(signalRequest?.isImageLoadingDisabled == false)
        #expect(signalRequest?.shouldRequestMultipleImages == false)
        #expect(signalRequest?.mediaAspectRatio == .unknown)
        #expect(signalRequest?.preferredAdChoicesPosition == .topRightCorner)
        #expect(signalRequest?.isCustomMuteThisAdRequested == false)
    }
    
    @Test func invalidBannerObjectThrownWhenBannerIsMissing() async throws {
        let request = try await NimbusRequest(from: Nimbus.inlineAd(position: "pos").adRequest!.request)
        
        let error = #expect(throws: NimbusError.self) {
            try AdController.AdRenderType.banner.adMobSignalRequest(from: request, adUnitId: "adUnit")
        }
        #expect(error!.domain == .admob)
        #expect(error!.reason == .invalidState)
        #expect(error!.stage == .request)
        #expect(error!.detail == "Ad size is missing")
    }
    
    @Test func missingNativeAdOptionsThrown() async throws {
        let ad = try await Nimbus.inlineAd(position: "pos") { native() }
        
        let request = try await NimbusRequest(from: ad.adRequest!.request)
        
        let error = #expect(throws: NimbusError.self) {
            try AdController.AdRenderType.native.adMobSignalRequest(from: request, adUnitId: "adUnit")
        }
        
        #expect(error!.domain == .admob)
        #expect(error!.reason == .configuration)
        #expect(error!.stage == .request)
        #expect(error!.detail == "Native ad options are missing")
    }
    
    @Test func interstitialGeneratesCorrectSignalRequest() async throws {
        var request = try await Nimbus.interstitialAd(position: "pos").adRequest!.request
        request.impressions[0].video = nil
        
        let info = try NimbusRequest(from: request)
        
        let signalRequest = try AdController.AdRenderType.interstitial.adMobSignalRequest(from: info, adUnitId: "adUnit") as? InterstitialSignalRequest
        #expect(signalRequest != nil)
        assertSignal(request: signalRequest)
    }
    
    @Test func rewardedGeneratesCorrectSignalRequest() async throws {
        let info = try await NimbusRequest(from: Nimbus.rewardedAd(position: "pos").adRequest!.request)
        
        let signalRequest = try AdController.AdRenderType.rewarded.adMobSignalRequest(from: info, adUnitId: "adUnit") as? RewardedSignalRequest
        #expect(signalRequest != nil)
        assertSignal(request: signalRequest)
    }
    
    private func assertSignal(request: SignalRequest?, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(request?.adUnitID == "adUnit", sourceLocation: sourceLocation)
        #expect(request?.requestAgent == "nimbus", sourceLocation: sourceLocation)
    }
}

private struct SignalError: Error {}

private final class MockRequestBridge: AdMobRequestBridgeType {    
    let onGenerateSignal: (@Sendable (SignalRequest) async throws -> String)
    
    init(_ onGenerateSignal: @escaping @Sendable (SignalRequest) async throws -> String) {
        self.onGenerateSignal = onGenerateSignal
    }
    
    func generateSignal(request: SignalRequest) async throws -> String {
        try await onGenerateSignal(request)
    }
}
