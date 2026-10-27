//
//  AdMobAdControllerTests.swift
//  NimbusAdMobKitTests
//  Created on 10/23/26
//  Copyright © 2026 Nimbus Advertising Solutions Inc. All rights reserved.
//

import Testing
@testable import NimbusAdMobKit
@testable import NimbusKit
import UIKit
import GoogleMobileAds

private let adResponse = "test-ad-response-string"

/// GoogleMobileAds is Objective-C, so `AdMobSDKStub` swaps out the SDK calls that would hit the
/// network or present UI (loads, presents) for the length of one test, recording what was passed.
/// Callbacks are then fired through the delegates the adapter wired on the real SDK objects.
@Suite("AdMob AdController tests")
@MainActor
struct AdMobAdControllerTests {

    // MARK: - Banner

    @Test func bannerAdEventsGetFired() throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.banner)
        adController.load()

        #expect(adController.nativeAdLoader == nil)
        #expect(adController.interstitialAd == nil)
        #expect(adController.rewardedAd == nil)

        let banner = try #require(adController.bannerAd)
        #expect(sdk.bannerLoadedResponse == adResponse)
        #expect(banner.rootViewController === presenter)

        let admob = try #require(banner.delegate, "banner delegate not wired")
        #expect(admob === adController)

        // The banner is added on start, and fills in once AdMob receives the ad
        #expect(adController.adView.subviews.isEmpty)
        adController.start()
        #expect(adController.adView.subviews.first === banner)

        admob.bannerViewDidReceiveAd?(banner)
        #expect(delegate.events == [.loaded])

        admob.bannerViewDidRecordImpression?(banner)
        #expect(delegate.events == [.loaded, .impression])

        admob.bannerViewDidRecordClick?(banner)
        #expect(delegate.events == [.loaded, .impression, .clicked])
        #expect(delegate.lastError == nil)
    }

    @Test func bannerAdGetsDestroyedOnError() throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.banner)
        adController.load()

        let banner = try #require(adController.bannerAd)
        let admob = try #require(banner.delegate, "banner delegate not wired")

        admob.bannerView?(banner, didFailToReceiveAdWithError: adMobError)

        expectAdMobError(delegate, detail: "AdMob test error")
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Native

    @Test func nativeAdEventsGetFired() throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let nativeView = GoogleMobileAds.NativeAdView()
        var providedAd: GoogleMobileAds.NativeAd?
        AdMobExtension.nativeAdViewProvider = { _, ad in
            providedAd = ad
            return nativeView
        }
        defer { AdMobExtension.nativeAdViewProvider = nil }

        let (adController, delegate) = makeAdController(.native)
        adController.load()

        #expect(adController.bannerAd == nil)
        #expect(adController.interstitialAd == nil)
        #expect(adController.rewardedAd == nil)

        let loader = try #require(adController.nativeAdLoader)
        #expect(sdk.adLoaderLoadedResponse == adResponse)

        let admob = try #require(loader.delegate as? GoogleMobileAds.NativeAdLoaderDelegate, "ad loader delegate not wired")
        #expect(admob === adController)

        let nativeAd = GoogleMobileAds.NativeAd()
        admob.adLoader(loader, didReceive: nativeAd)
        #expect(delegate.events == [.loaded])
        #expect(adController.nativeAd === nativeAd)
        #expect(nativeAd.rootViewController === presenter)

        // Only one loaded event, even though AdMob also reports the loader finished
        admob.adLoaderDidFinishLoading?(loader)
        #expect(delegate.events == [.loaded])

        #expect(adController.adView.subviews.isEmpty)
        adController.start()
        #expect(adController.adView.subviews.first === nativeView)
        #expect(providedAd === nativeAd)
        #expect(!nativeView.translatesAutoresizingMaskIntoConstraints)

        let native = try #require(nativeAd.delegate, "native ad delegate not wired")
        #expect(native === adController)

        native.nativeAdDidRecordImpression?(nativeAd)
        #expect(delegate.events == [.loaded, .impression])

        native.nativeAdDidRecordClick?(nativeAd)
        #expect(delegate.events == [.loaded, .impression, .clicked])

        #expect(delegate.lastError == nil)

        let video = try #require(sdk.videoController.delegate, "video controller delegate not wired")
        #expect(video === adController)

        video.videoControllerDidEndVideoPlayback?(sdk.videoController)
        #expect(delegate.events == [.loaded, .impression, .clicked, .completed])
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.lastError == nil)
    }

    @Test func nativeAdRendersWhenStartedBeforeLoad() throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let nativeView = GoogleMobileAds.NativeAdView()
        AdMobExtension.nativeAdViewProvider = { _, _ in nativeView }
        defer { AdMobExtension.nativeAdViewProvider = nil }

        let (adController, delegate) = makeAdController(.native)
        adController.load()
        adController.start()
        #expect(adController.adView.subviews.isEmpty)

        let loader = try #require(adController.nativeAdLoader)
        let admob = try #require(loader.delegate as? GoogleMobileAds.NativeAdLoaderDelegate, "ad loader delegate not wired")

        admob.adLoader(loader, didReceive: GoogleMobileAds.NativeAd())

        #expect(delegate.events == [.loaded])
        #expect(delegate.lastError == nil)
        #expect(adController.adView.subviews.first === nativeView)
    }

    @Test func nativeAdWithoutViewProviderFailsToLoad() {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }
        AdMobExtension.nativeAdViewProvider = nil

        let (adController, delegate) = makeAdController(.native)
        adController.load()

        #expect(adController.nativeAdLoader == nil)
        #expect(sdk.adLoaderLoadedResponse == nil)
        #expect(delegate.lastError?.reason == .configuration)
        #expect(delegate.events.last == .destroyed)
    }

    @Test func nativeAdGetsDestroyedOnLoadError() throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }
        AdMobExtension.nativeAdViewProvider = { _, _ in GoogleMobileAds.NativeAdView() }
        defer { AdMobExtension.nativeAdViewProvider = nil }

        let (adController, delegate) = makeAdController(.native)
        adController.load()

        let loader = try #require(adController.nativeAdLoader)
        let admob = try #require(loader.delegate as? GoogleMobileAds.NativeAdLoaderDelegate, "ad loader delegate not wired")

        admob.adLoader(loader, didFailToReceiveAdWithError: adMobError)

        expectAdMobError(delegate, detail: "Failed to receive native ad, error: AdMob test error")
        #expect(!delegate.events.contains(.loaded))
        #expect(delegate.events.last == .destroyed)
    }

    /// `adLoader(_:didFailToLoadWithError:)` is not part of AdLoaderDelegate, so AdMob never calls it and it
    /// can't be fired through the delegate. It's kept as a safety net, so verify it still maps to an error.
    @Test func nativeAdGetsDestroyedOnFailToLoadError() throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }
        AdMobExtension.nativeAdViewProvider = { _, _ in GoogleMobileAds.NativeAdView() }
        defer { AdMobExtension.nativeAdViewProvider = nil }

        let (adController, delegate) = makeAdController(.native)
        adController.load()
        let loader = try #require(adController.nativeAdLoader)

        adController.adLoader(loader, didFailToLoadWithError: adMobError)

        expectAdMobError(delegate, detail: "Failed to receive native ad, error: AdMob test error")
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Interstitial

    @Test func interstitialAdEventsGetFired() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.interstitial)
        adController.load()

        #expect(adController.bannerAd == nil)
        #expect(adController.nativeAdLoader == nil)
        #expect(sdk.interstitialLoadedResponse == adResponse)

        let interstitial = MockInterstitialAd()
        let completion: (GoogleMobileAds.InterstitialAd?, Error?) -> Void = try #require(sdk.interstitialCompletion)
        completion(interstitial, nil)
        await waitUntil { delegate.events.contains(.loaded) }

        #expect(delegate.events == [.loaded])
        #expect(adController.interstitialAd === interstitial)
        #expect(interstitial.presentedFrom == nil)

        let admob = try #require(interstitial.fullScreenContentDelegate, "fullscreen delegate not wired")
        #expect(admob === adController)

        adController.start()
        #expect(delegate.lastError == nil)
        #expect(interstitial.presentCount == 1)
        #expect(interstitial.presentedFrom === presenter)

        admob.adDidRecordImpression?(interstitial)
        #expect(delegate.events == [.loaded, .impression])

        admob.adDidRecordClick?(interstitial)
        #expect(delegate.events == [.loaded, .impression, .clicked])
        #expect(delegate.lastError == nil)

        admob.adDidDismissFullScreenContent?(interstitial)
        #expect(delegate.lastError == nil)
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.events.last == .destroyed)
        #expect(adController.interstitialAd == nil)
    }

    @Test func interstitialAdGetsDestroyedOnLoadError() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.interstitial)
        adController.load()

        let completion: (GoogleMobileAds.InterstitialAd?, Error?) -> Void = try #require(sdk.interstitialCompletion)
        completion(nil, adMobError)
        await waitUntil { delegate.lastError != nil }

        expectAdMobError(delegate, detail: "AdMob test error")
        #expect(delegate.events.last == .destroyed)
    }

    @Test func interstitialAdGetsDestroyedWhenLoadReturnsNothing() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.interstitial)
        adController.load()

        let completion: (GoogleMobileAds.InterstitialAd?, Error?) -> Void = try #require(sdk.interstitialCompletion)
        completion(nil, nil)
        await waitUntil { delegate.lastError != nil }

        expectAdMobError(delegate, detail: "Received neither an AdMob interstitial ad nor an error.")
        #expect(delegate.events.last == .destroyed)
    }

    @Test func interstitialAdGetsDestroyedOnPresentError() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.interstitial)
        adController.load()

        let interstitial = MockInterstitialAd()
        let completion: (GoogleMobileAds.InterstitialAd?, Error?) -> Void = try #require(sdk.interstitialCompletion)
        completion(interstitial, nil)
        await waitUntil { delegate.events.contains(.loaded) }
        adController.start()

        let admob = try #require(interstitial.fullScreenContentDelegate, "fullscreen delegate not wired")
        admob.ad?(interstitial, didFailToPresentFullScreenContentWithError: adMobError)

        expectAdMobError(delegate, detail: "AdMob test error")
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Rewarded

    @Test func rewardedAdEventsGetFired() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.rewarded)
        adController.load()

        #expect(adController.bannerAd == nil)
        #expect(adController.nativeAdLoader == nil)
        #expect(adController.interstitialAd == nil)
        #expect(sdk.rewardedLoadedResponse == adResponse)

        let rewarded = MockRewardedAd()
        let completion: (GoogleMobileAds.RewardedAd?, Error?) -> Void = try #require(sdk.rewardedCompletion)
        completion(rewarded, nil)
        await waitUntil { delegate.events.contains(.loaded) }

        #expect(delegate.events == [.loaded])
        #expect(adController.rewardedAd === rewarded)

        let admob = try #require(rewarded.fullScreenContentDelegate, "fullscreen delegate not wired")
        #expect(admob === adController)

        adController.start()
        #expect(delegate.lastError == nil)
        #expect(rewarded.presentCount == 1)
        #expect(rewarded.presentedFrom === presenter)

        admob.adDidRecordImpression?(rewarded)
        #expect(delegate.events == [.loaded, .impression])

        admob.adDidRecordClick?(rewarded)
        #expect(delegate.events == [.loaded, .impression, .clicked])

        // The reward comes through the handler passed to present(from:userDidEarnRewardHandler:)
        let earnReward: () -> Void = try #require(rewarded.rewardHandler, "reward handler not passed")
        earnReward()
        #expect(delegate.events == [.loaded, .impression, .clicked, .rewardEarned])
        #expect(delegate.lastError == nil)

        admob.adDidDismissFullScreenContent?(rewarded)
        #expect(delegate.lastError == nil)
        #expect(delegate.events.last == .destroyed)
        #expect(adController.rewardedAd == nil)
    }

    @Test func rewardedAdGetsDestroyedOnLoadError() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.rewarded)
        adController.load()

        let completion: (GoogleMobileAds.RewardedAd?, Error?) -> Void = try #require(sdk.rewardedCompletion)
        completion(nil, adMobError)
        await waitUntil { delegate.lastError != nil }

        expectAdMobError(delegate, detail: "AdMob test error")
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.events.last == .destroyed)
    }

    @Test func rewardedAdGetsDestroyedWhenLoadReturnsNothing() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.rewarded)
        adController.load()

        let completion: (GoogleMobileAds.RewardedAd?, Error?) -> Void = try #require(sdk.rewardedCompletion)
        completion(nil, nil)
        await waitUntil { delegate.lastError != nil }

        expectAdMobError(delegate, detail: "Received neither an AdMob rewarded ad nor an error.")
        #expect(delegate.events.last == .destroyed)
    }

    @Test func rewardedAdGetsDestroyedOnPresentError() async throws {
        let sdk = AdMobSDKStub()
        defer { sdk.restore() }

        let (adController, delegate) = makeAdController(.rewarded)
        adController.load()

        let rewarded = MockRewardedAd()
        let completion: (GoogleMobileAds.RewardedAd?, Error?) -> Void = try #require(sdk.rewardedCompletion)
        completion(rewarded, nil)
        await waitUntil { delegate.events.contains(.loaded) }
        adController.start()

        let admob = try #require(rewarded.fullScreenContentDelegate, "fullscreen delegate not wired")
        admob.ad?(rewarded, didFailToPresentFullScreenContentWithError: adMobError)

        expectAdMobError(delegate, detail: "AdMob test error")
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Helpers

    /// Fresh per test: Swift Testing creates a new suite instance for every @Test.
    private let container = UIView()

    /// AdController holds adPresentingViewController weakly, so it must outlive the test body.
    private let presenter = UIViewController()

    private let adMobError = NSError(
        domain: "com.google.admob.test",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "AdMob test error"]
    )

    enum Format { case banner, native, interstitial, rewarded }

    private func makeAdController(_ format: Format) -> (NimbusAdMobAdController, MockDelegate) {
        let mtype: NimbusResponse.Bid.MarkupType = switch format {
        case .banner, .interstitial: .static
        case .native: .native
        case .rewarded: .video
        }

        let adController = NimbusAdMobAdController(
            response: NimbusResponse(id: "", bid: .init(
                mtype: mtype,
                adm: adResponse,
                price: 0,
                ext: .init(),
                w: 320,
                h: 50
            )),
            isBlocking: format == .interstitial || format == .rewarded,
            isRewarded: format == .rewarded,
            container: container,
            adPresentingViewController: presenter
        )
        let delegate = MockDelegate()
        adController.delegate = delegate
        return (adController, delegate)
    }

    /// AdMob's fullscreen load completion is handled in a main-actor Task; let it run.
    private func waitUntil(
        _ condition: () -> Bool,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        var attempts = 0
        while !condition(), attempts < 100 {
            attempts += 1
            try? await Task.sleep(nanoseconds: 10_000_000) // iOS 15 target: no Task.sleep(for:)
        }
        #expect(condition(), "timed out waiting for the load completion to be handled", sourceLocation: sourceLocation)
    }

    private func expectAdMobError(
        _ delegate: MockDelegate,
        detail: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let error = delegate.lastError
        #expect(error != nil, sourceLocation: sourceLocation)
        #expect(error!.domain == NimbusError.Domain(rawValue: "admob"), sourceLocation: sourceLocation)
        #expect(error!.detail == detail, sourceLocation: sourceLocation)
    }
}

// MARK: - Mocks

class MockDelegate: AdController.Delegate {
    var events: [AdEvent] = []
    var lastError: NimbusError?

    func didReceiveNimbusEvent(event: NimbusKit.AdEvent) {
        events.append(event)
    }

    func didReceiveNimbusError(error: NimbusKit.NimbusError) {
        lastError = error
    }
}

/// Stubs the GoogleMobileAds calls the adapter makes that would load from the network.
/// Presenting is covered by `MockInterstitialAd` / `MockRewardedAd`, handed to the adapter through the load completion.
/// Restore with `defer`: each swap applies to every instance of the class until restored.
final class AdMobSDKStub {
    private(set) var bannerLoadedResponse: String?
    private(set) var adLoaderLoadedResponse: String?

    private(set) var interstitialLoadedResponse: String?
    private(set) var interstitialCompletion: ((GoogleMobileAds.InterstitialAd?, Error?) -> Void)?
    private(set) var rewardedLoadedResponse: String?
    private(set) var rewardedCompletion: ((GoogleMobileAds.RewardedAd?, Error?) -> Void)?

    /// Returned as every native ad's `mediaContent.videoController`, so tests can reach the delegate the adapter sets.
    let videoController = GoogleMobileAds.VideoController()
    private let mediaContent = GoogleMobileAds.MediaContent()

    private var stubs: [MethodStub] = []

    init() {
        stubs = [
            MethodStub(GoogleMobileAds.BannerView.self, "loadWithAdResponseString:", with: { [weak self] (_: AnyObject, response: NSString) in
                self?.bannerLoadedResponse = response as String
            } as @convention(block) (AnyObject, NSString) -> Void),

            MethodStub(GoogleMobileAds.AdLoader.self, "loadWithAdResponseString:", with: { [weak self] (_: AnyObject, response: NSString) in
                self?.adLoaderLoadedResponse = response as String
            } as @convention(block) (AnyObject, NSString) -> Void),

            MethodStub(classMethodOf: GoogleMobileAds.InterstitialAd.self, "loadWithAdResponseString:completionHandler:", with: {
                [weak self] (_: AnyObject, response: NSString, completion: @escaping @convention(block) (GoogleMobileAds.InterstitialAd?, NSError?) -> Void) in
                self?.interstitialLoadedResponse = response as String
                self?.interstitialCompletion = { ad, error in completion(ad, error as NSError?) }
            } as @convention(block) (AnyObject, NSString, @escaping @convention(block) (GoogleMobileAds.InterstitialAd?, NSError?) -> Void) -> Void),

            MethodStub(classMethodOf: GoogleMobileAds.RewardedAd.self, "loadWithAdResponseString:completionHandler:", with: {
                [weak self] (_: AnyObject, response: NSString, completion: @escaping @convention(block) (GoogleMobileAds.RewardedAd?, NSError?) -> Void) in
                self?.rewardedLoadedResponse = response as String
                self?.rewardedCompletion = { ad, error in completion(ad, error as NSError?) }
            } as @convention(block) (AnyObject, NSString, @escaping @convention(block) (GoogleMobileAds.RewardedAd?, NSError?) -> Void) -> Void),
        ]

        // A GoogleMobileAds.NativeAd made in a test has no media content; give every one the same media content and video controller.
        let mediaContent = mediaContent
        let videoController = videoController
        stubs += [
            MethodStub(GoogleMobileAds.NativeAd.self, "mediaContent", with: { (_: AnyObject) -> GoogleMobileAds.MediaContent in
                mediaContent
            } as @convention(block) (AnyObject) -> GoogleMobileAds.MediaContent),
            MethodStub(GoogleMobileAds.MediaContent.self, "videoController", with: { (_: AnyObject) -> GoogleMobileAds.VideoController in
                videoController
            } as @convention(block) (AnyObject) -> GoogleMobileAds.VideoController),
        ]
    }

    func restore() {
        stubs.reversed().forEach { $0.restore() }
    }
}

/// Records `present(from:)` instead of presenting.
final class MockInterstitialAd: GoogleMobileAds.InterstitialAd, @unchecked Sendable {
    private(set) var presentCount = 0
    private(set) weak var presentedFrom: UIViewController?

    override func present(from rootViewController: UIViewController?) {
        presentCount += 1
        presentedFrom = rootViewController
    }
}

/// Records `present(from:userDidEarnRewardHandler:)` instead of presenting, keeping the reward handler.
final class MockRewardedAd: GoogleMobileAds.RewardedAd, @unchecked Sendable {
    private(set) var presentCount = 0
    private(set) weak var presentedFrom: UIViewController?
    private(set) var rewardHandler: GADUserDidEarnRewardHandler?

    override func present(
        from rootViewController: UIViewController?,
        userDidEarnRewardHandler: @escaping GADUserDidEarnRewardHandler
    ) {
        presentCount += 1
        presentedFrom = rootViewController
        rewardHandler = userDidEarnRewardHandler
    }
}

/// Swaps an Objective-C method implementation until `restore()`.
final class MethodStub {
    private let method: Method
    private let original: IMP

    init(_ cls: AnyClass, _ selector: String, with block: Any) {
        method = class_getInstanceMethod(cls, NSSelectorFromString(selector))!
        original = method_setImplementation(method, imp_implementationWithBlock(block))
    }

    init(classMethodOf cls: AnyClass, _ selector: String, with block: Any) {
        method = class_getClassMethod(cls, NSSelectorFromString(selector))!
        original = method_setImplementation(method, imp_implementationWithBlock(block))
    }

    func restore() {
        method_setImplementation(method, original)
    }
}
