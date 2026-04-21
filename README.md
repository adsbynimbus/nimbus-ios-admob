# NimbusAdMobKit

A Nimbus SDK extension for **AdMob bidding and rendering**. It enriches Nimbus ad requests with AdMob demand and handles ad rendering through the Google Mobile Ads SDK when it wins the auction.

## Versioning
 
NimbusAdMobKit **major versions are kept in sync** with the GoogleMobileAds SDK. For example, NimbusAdMobKit `12.x.x` depends on GoogleMobileAds SDK `12.x.x`.
 
Minor and patch versions are independent — a NimbusAdMobKit patch release does not necessarily correspond to a GoogleMobileAds SDK patch release, and vice versa.
 
| NimbusAdMobKit | GoogleMobileAds SDK |
|---|---|
| 12.x.x | 12.x.x |

## Installation

### Swift Package Manager

#### Xcode Project

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter the repository URL:
   ```
   https://github.com/adsbynimbus/nimbus-ios-admob
   ```
3. Set the dependency rule to **Up to Next Major Version** and enter `12.0.0` as the minimum.
4. Click **Add Package** and select the **NimbusAdMobKit** library when prompted.

#### Package.swift

If you're managing dependencies through a `Package.swift` file, add the following:

```swift
dependencies: [
    .package(url: "https://github.com/adsbynimbus/nimbus-ios-admob", from: "12.0.0")
]
```

Then add the product to your target:

```swift
.product(name: "NimbusAdMobKit", package: "nimbus-ios-admob")
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'NimbusAdMobKit'
```

Then run:

```sh
pod install
```

## Usage

### Initialization
 
Navigate to where you call `Nimbus.initialize` and register the `AdMobExtension`:
 
```swift
import NimbusAdMobKit
 
Nimbus.initialize(publisher: "<publisher>", apiKey: "<apiKey>") {
    AdMobExtension(autoInitialize: true)
}
```
 
Make sure your `Info.plist` includes the following:
 
- `GADApplicationIdentifier` — set to your AdMob app ID.
- `GADIsAdManagerApp` — must either be absent or set to `NO`.

### Ad Request

AdMob requires an ad unit ID when an ad is requested. The example below shows how to request a banner ad:

```swift
self.bannerAd = try await Nimbus.bannerAd(position: "banner", size: .banner, refreshInterval: 30) {
    demand {
        admob(bannerAdUnitId: "<bannerAdUnitId>")
    }
}
.show(in: view)
```

That's it — AdMob is now enabled in this banner request.

## Documentation

- [Nimbus iOS SDK Documentation](https://docs.adsbynimbus.com/docs/sdk/ios) — integration guides, configuration, and API reference.
- [DocC API Reference](https://iosdocs.adsbynimbus.com) — auto-generated documentation for the latest release.

## Sample App

See NimbusAdMobKit in action in our public [sample app repository](https://github.com/adsbynimbus/nimbus-ios-sample), which demonstrates end-to-end integration including setup, bid requests, and ad rendering.
