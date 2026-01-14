// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NimbusAdMobKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(
           name: "NimbusAdMobKit",
           targets: ["NimbusAdMobKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/adsbynimbus/internal-nimbus-ios-sdk", exact: "3.0.0-split"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "NimbusAdMobKit",
            dependencies: [
                .product(name: "NimbusKit", package: "internal-nimbus-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ])
    ]
)
