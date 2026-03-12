// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "airport-data",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "AirportData",
            targets: ["AirportData"]
        )
    ],
    targets: [
        .target(
            name: "AirportData",
            resources: [
                .copy("Resources/airports.json")
            ]
        ),
        .testTarget(
            name: "AirportDataTests",
            dependencies: ["AirportData"]
        )
    ]
)
