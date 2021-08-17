// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BitcloutIdentity",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BitcloutIdentity",
            targets: ["BitcloutIdentity"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "KeychainAccess", url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(name: "CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.0")),
        .package(name: "SwiftECC", url: "https://github.com/leif-ibsen/SwiftECC", from: "1.0.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BitcloutIdentity",
            dependencies: ["KeychainAccess", "CryptoSwift", "SwiftECC"]),
        .testTarget(
            name: "BitcloutIdentityTests",
            dependencies: ["BitcloutIdentity"]),
    ]
)
