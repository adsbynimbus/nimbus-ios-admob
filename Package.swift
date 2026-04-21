// swift-tools-version: 6.1

import PackageDescription

var package = Package(
    name: "NimbusAdMobKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(
           name: "NimbusAdMobKit",
           targets: ["NimbusAdMobKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "13.0.0")
    ],
    targets: [
        .target(
            name: "NimbusAdMobKit",
            dependencies: [
                .product(name: "NimbusKit", package: "nimbus-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ]
        ),
        .testTarget(
            name: "NimbusAdMobKitTests",
            dependencies: ["NimbusAdMobKit"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)

package.dependencies.append(.package(url: "https://github.com/adsbynimbus/nimbus-ios-sdk", from: "3.0.0-rc.1"))
