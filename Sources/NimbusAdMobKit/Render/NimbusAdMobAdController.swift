//
//  NimbusAdMobAdController.swift
//  NimbusAdMobKit
//  Created on 9/3/24
//  Copyright © 2024 Nimbus Advertising Solutions Inc. All rights reserved.
//

import UIKit
import NimbusKit
import GoogleMobileAds

final class NimbusAdMobAdController: AdController,
                                     BannerViewDelegate,
                                     NativeAdLoaderDelegate,
                                     FullScreenContentDelegate,
                                     NativeAdDelegate {
    
    // MARK: - Properties
    
    // MARK: AdMob properties
    private var bannerAd: BannerView?
    private var interstitialAd: GoogleMobileAds.InterstitialAd?
    private var rewardedAd: GoogleMobileAds.RewardedAd?
    private var nativeAdLoader: AdLoader?
    private var nativeAd: NativeAd?
    
    override class func setup(
        response: NimbusResponse,
        container: UIView,
        adPresentingViewController: UIViewController?
    ) -> AdController {
        let adController = Self.init(
            response: response,
            isBlocking: false,
            isRewarded: false,
            container: container,
            adPresentingViewController: adPresentingViewController
        )
        
        return adController
    }
    
    override class func setupBlocking(
        response: NimbusResponse,
        isRewarded: Bool,
        adPresentingViewController: UIViewController
    ) -> AdController {
        let adController = Self.init(
            response: response,
            isBlocking: true,
            isRewarded: isRewarded,
            container: nil,
            adPresentingViewController: adPresentingViewController
        )
        
        return adController
    }
    
    override func load() {
        switch adRenderType {
        case .banner:
            let bannerAd = BannerView()
            bannerAd.rootViewController = adPresentingViewController
            bannerAd.delegate = self
            self.bannerAd = bannerAd
            self.adState = .ready
            bannerAd.load(with: response.bid.adm)
            presentIfNeeded()
        case .interstitial:
            GoogleMobileAds.InterstitialAd.load(with: response.bid.adm) { [weak self] gadInterstitial, error in
                Task { @MainActor in
                    if let gadInterstitial {
                        self?.interstitialAd = gadInterstitial
                        self?.interstitialAd?.fullScreenContentDelegate = self
                        self?.adState = .ready
                        self?.sendNimbusEvent(.loaded)
                        self?.presentIfNeeded()
                    } else {
                        let message: String
                        if let error { message = error.localizedDescription }
                        else { message = "Received neither an AdMob interstitial ad nor an error." }
                        
                        self?.sendNimbusError(.admob(reason: .invalidState, stage: .render, detail: message) )
                    }
                }
            }
        case .rewarded:
            RewardedAd.load(with: response.bid.adm) { [weak self] gadRewarded, error in
                Task { @MainActor in
                    if let gadRewarded {
                        self?.rewardedAd = gadRewarded
                        self?.rewardedAd?.fullScreenContentDelegate = self
                        self?.adState = .ready
                        self?.sendNimbusEvent(.loaded)
                        self?.presentIfNeeded()
                    } else {
                        let message: String
                        if let error { message = error.localizedDescription }
                        else { message = "Received neither an AdMob rewarded ad nor an error." }
                        
                        self?.sendNimbusError(.admob(reason: .invalidState, stage: .render, detail: message) )
                    }
                }
            }
        case .native:
            guard let _ = AdMobExtension.nativeAdViewProvider else {
                sendNimbusError(.admob(reason: .misconfiguration, stage: .render, detail: "AdMobExtension.nativeAdViewProvider must be set to render native ads"))
                return
            }

            nativeAdLoader = AdLoader(rootViewController: adPresentingViewController)
            nativeAdLoader?.delegate = self
            nativeAdLoader?.load(with: response.bid.adm)
        @unknown default:
            sendNimbusError(.admob(reason: .unsupported, stage: .render, detail: "adRenderType: \(adRenderType.rawValue)"))
        }
    }
    
    func presentIfNeeded() {
        guard started, adState == .ready else { return }
        
        adState = .resumed
        
        if let bannerAd {
            adView.addSubview(bannerAd)
        } else if let nativeAd, let nativeAdViewProvider = AdMobExtension.nativeAdViewProvider {
            let nativeAdView = nativeAdViewProvider(adView, nativeAd)
            adView.addSubview(nativeAdView)
            
            NSLayoutConstraint.activate([
                nativeAdView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
                nativeAdView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
                nativeAdView.topAnchor.constraint(equalTo: adView.topAnchor),
                nativeAdView.bottomAnchor.constraint(equalTo: adView.bottomAnchor)
            ])
        } else if let interstitialAd, let adPresentingViewController {
            interstitialAd.present(from: adPresentingViewController)
        } else if let rewardedAd, let adPresentingViewController {
            rewardedAd.present(from: adPresentingViewController) { [weak self] in
                Nimbus.Log.ad.debug("AdMob Event: user earned reward")
                self?.sendNimbusEvent(.completed)
            }
        } else {
            sendNimbusError(.admob(reason: .invalidState, stage: .render, detail: "Ad \(adRenderType) is invalid and could not be presented."))
        }
    }
    
    override func onStart() {
        presentIfNeeded()
    }
    
    override func onDestroy() {
        bannerAd = nil
        nativeAd = nil
        nativeAdLoader = nil
        interstitialAd = nil
        rewardedAd = nil
    }
    
    // MARK: - GADBannerViewDelegate
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        sendNimbusEvent(.loaded)
    }
    
    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        sendNimbusEvent(.impression)
    }
    
    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        sendNimbusEvent(.clicked)
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
        sendNimbusError(.admob(stage: .render, detail: error.localizedDescription))
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
        sendNimbusEvent(.impression)
    }
    
    func adDidRecordClick(_ ad: any FullScreenPresentingAd) {
        sendNimbusEvent(.clicked)
    }
    
    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        sendNimbusError(.admob(stage: .render, detail: error.localizedDescription))
    }
    
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        destroy()
    }
    
    // MARK: - GADNativeAdLoaderDelegate
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.rootViewController = adPresentingViewController
        nativeAd.delegate = self
        self.nativeAd = nativeAd
        self.adState = .ready
        presentIfNeeded()
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        sendNimbusError(.admob(reason: .misconfiguration, stage: .render, detail: "Failed to receive native ad, error: \(error.localizedDescription)"))
    }
    
    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        sendNimbusEvent(.loaded)
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        sendNimbusEvent(.impression)
    }
    
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        sendNimbusEvent(.clicked)
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToLoadWithError error: Error) {
        sendNimbusError(.admob(stage: .render, detail: "Failed to receive native ad, error: \(error.localizedDescription)"))
    }
}

// GoogleMobileAds does not provide Swift Concurrency annotations for these ad objects.
// In Swift 6, the completion passed to `load(...)` is treated as nonisolated (and the compiler
// applies sendability checking), so moving the returned ad objects into @MainActor state
// produces warnings.
//
// We retroactively mark these types as @unchecked Sendable to silence those warnings.
// Contract: we only ever interact with these objects on MainActor / main thread.
extension GoogleMobileAds.InterstitialAd: @unchecked @retroactive Sendable {}
extension GoogleMobileAds.RewardedAd: @unchecked @retroactive Sendable {}

// Internal: Do NOT implement delegate conformance as separate extensions as the methods won't not be found in runtime when built as a static library
