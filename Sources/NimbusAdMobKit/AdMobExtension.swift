//
//  AdMobExtension.swift
//  Nimbus
//  Created on 4/1/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit
import GoogleMobileAds

/// Nimbus extension for AdMob.
///
/// Enables AdMob rendering when included in `Nimbus.initialize(...)`.
/// Supports dynamic enable/disable at runtime.
///
/// ### Notes:
///   - Instantiate within the `Nimbus.initialize` block; the extension is installed and enabled automatically.
///   - Disable rendering with `AdMobExtension.disable()`.
///   - Re-enable rendering with `AdMobExtension.enable()`.
public struct AdMobExtension: NimbusRenderExtension {
    @_documentation(visibility: internal)
    public var enabled = true
    
    @_documentation(visibility: internal)
    public var network: String { "admob" }
    
    @_documentation(visibility: internal)
    public var controllerType: AdController.Type { NimbusAdMobAdController.self }
    
    /// Creates an AdMob extension.
    ///
    /// - Parameter autoInitialize: If true, Nimbus initializes the GoogleMobileAds SDK automatically.
    ///
    /// ##### Usage
    /// ```swift
    /// Nimbus.initialize(publisher: "<publisher>", apiKey: "<apiKey>") {
    ///     AdMobExtension(autoInitialize: true) // Enables AdMob rendering
    /// }
    /// ```
    public init(autoInitialize: Bool = false) {
        guard autoInitialize else {
            Nimbus.Log.lifecycle.debug("Skipping GoogleMobileAds SDK initialization per user request")
            return
        }
        
        MobileAds.shared.start { _ in
            Nimbus.Log.lifecycle.debug("GoogleMobileAds SDK initialization completed")
        }
    }
    
    @_documentation(visibility: internal)
    public func coppaDidChange(coppa: Bool) {
        AdMobRequestBridge.set(coppa: coppa)
    }
}

public extension AdMobExtension {
    /**
     The UIView returned from this method should have all of the data set from the native ad
     on children views such as the call to action, image data, title, privacy icon etc.
     The view returned from this method should not be attached to the container passed in as
     it will be attached at a later time during the rendering process.
     
     NOTE: DO NOT set nativeAd.delegate. Nimbus uses this delegate and forwards events as NimbusEvent. You may
     listen set AdController.delegate and listen to didReceiveNimbusEvent() and didReceiveNimbusError() instead.
     
     Please set the GADNativeAdView.nativeAd property at the appropriate time, as the correct timing may vary depending on the AdChoices settings.
     
     - Parameters:
       - container: The container the layout will be attached to
       - nativeAd: The AdMob native ad with the relevant ad information
     
     - Returns: Your custom UIView (must inherit GADNativeAdView). DO NOT attach the view to the hierarchy yourself.
     */
    @MainActor
    @preconcurrency
    static var nativeAdViewProvider: ((_ container: UIView, _ nativeAd: NativeAd) -> NativeAdView)?
}
