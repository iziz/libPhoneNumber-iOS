// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "libPhoneNumber",
    platforms: [
        .macOS(.v10_13),
        .macCatalyst(.v13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "libPhoneNumber",
            targets: ["libPhoneNumber"]
        ),
        .library(
            name: "libPhoneNumberGeocoding",
            targets: ["libPhoneNumberGeocoding"]
        ),
        .library(
            name: "libPhoneNumberShortNumber",
            targets: ["libPhoneNumberShortNumber"]
        ),
        .library(
            name: "libPhoneNumberCarrier",
            targets: ["libPhoneNumberCarrier"]
        ),
        .library(
            name: "libPhoneNumberTimeZones",
            targets: ["libPhoneNumberTimeZones"]
        ),
        .library(
            name: "libPhoneNumberSwiftCore",
            targets: ["libPhoneNumberSwiftCore"]
        ),
        .library(
            name: "libPhoneNumberSwiftGeocoding",
            targets: ["libPhoneNumberSwiftGeocoding"]
        ),
        .library(
            name: "libPhoneNumberSwiftShortNumber",
            targets: ["libPhoneNumberSwiftShortNumber"]
        ),
        .library(
            name: "libPhoneNumberSwiftCarrier",
            targets: ["libPhoneNumberSwiftCarrier"]
        ),
        .library(
            name: "libPhoneNumberSwiftTimeZones",
            targets: ["libPhoneNumberSwiftTimeZones"]
        ),
        .library(
            name: "libPhoneNumberSwiftUI",
            targets: ["libPhoneNumberSwiftUI"]
        ),
        .library(
            name: "libPhoneNumberSwiftUIEnrichment",
            targets: ["libPhoneNumberSwiftUIEnrichment"]
        ),
        .library(
            name: "libPhoneNumberIOSSwift",
            targets: ["libPhoneNumberIOSSwift"]
        )
    ],
    targets: [
        .target(
            name: "libPhoneNumberTestsCommon",
            path: "libPhoneNumberTestsCommon",
            resources: [
                .copy("libPhoneNumberMetaDataForTesting.zip")
            ],
            publicHeadersPath: "."
        ),
        .target(
            name: "libPhoneNumberInternal",
            path: "libPhoneNumberInternal",
            publicHeadersPath: "."
        ),
        .target(
            name: "libPhoneNumber",
            dependencies: ["libPhoneNumberInternal"],
            path: "libPhoneNumber",
            exclude: ["Info.plist"],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Internal")
            ],
            linkerSettings: [
                .linkedFramework("Contacts", .when(platforms: [.iOS, .macOS, .macCatalyst, .watchOS])),
            ]
        ),
        .testTarget(
            name: "libPhoneNumberTests",
            dependencies: [
                "libPhoneNumber",
                "libPhoneNumberTestsCommon",
            ],
            path: "libPhoneNumberTests"
        ),
        .target(
            name: "libPhoneNumberGeocodingMetaData",
            path: "libPhoneNumberGeocodingMetaData",
            resources: [
                .copy("GeocodingMetaData.bundle")
            ],
            publicHeadersPath: "."
        ),
        .target(
            name: "libPhoneNumberGeocoding",
            dependencies: [
                "libPhoneNumber",
                "libPhoneNumberGeocodingMetaData",
            ],
            path: "libPhoneNumberGeocoding",
            exclude: [
                "README.md",
                "Info.plist",
            ],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "libPhoneNumberGeocodingTests",
            dependencies: [
                "libPhoneNumberGeocoding",
                "libPhoneNumberTestsCommon",
            ],
            path: "libPhoneNumberGeocodingTests",
            resources: [
                .copy("TestingSource.bundle")
            ]
        ),
        .target(
            name: "libPhoneNumberShortNumberInternal",
            dependencies: [
                "libPhoneNumber",
            ],
            path: "libPhoneNumberShortNumberInternal",
            publicHeadersPath: "."
        ),
        .target(
            name: "libPhoneNumberShortNumber",
            dependencies: [
                "libPhoneNumberShortNumberInternal",
            ],
            path: "libPhoneNumberShortNumber",
            exclude: [
                "README.md",
                "Info.plist",
            ],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "libPhoneNumberShortNumberTests",
            dependencies: [
                "libPhoneNumberShortNumber",
                "libPhoneNumberTestsCommon",
            ],
            path: "libPhoneNumberShortNumberTests"
        ),
        .target(
            name: "libPhoneNumberCarrierMetaData",
            path: "libPhoneNumberCarrierMetaData",
            resources: [
                .copy("CarrierMetaData.bundle")
            ],
            publicHeadersPath: "."
        ),
        .target(
            name: "libPhoneNumberCarrier",
            dependencies: [
                "libPhoneNumber",
                "libPhoneNumberCarrierMetaData",
            ],
            path: "libPhoneNumberCarrier",
            exclude: [
                "Info.plist",
            ],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "libPhoneNumberCarrierTests",
            dependencies: [
                "libPhoneNumberCarrier",
            ],
            path: "libPhoneNumberCarrierTests"
        ),
        .target(
            name: "libPhoneNumberTimeZonesMetaData",
            path: "libPhoneNumberTimeZonesMetaData",
            resources: [
                .copy("TimeZonesMetaData.bundle")
            ],
            publicHeadersPath: "."
        ),
        .target(
            name: "libPhoneNumberTimeZones",
            dependencies: [
                "libPhoneNumber",
                "libPhoneNumberTimeZonesMetaData",
            ],
            path: "libPhoneNumberTimeZones",
            exclude: [
                "Info.plist",
            ],
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "libPhoneNumberTimeZonesTests",
            dependencies: [
                "libPhoneNumberTimeZones",
            ],
            path: "libPhoneNumberTimeZonesTests"
        ),
        .target(
            name: "libPhoneNumberSwiftCore",
            dependencies: [
                "libPhoneNumber",
            ],
            path: "libPhoneNumberSwiftCore"
        ),
        .target(
            name: "libPhoneNumberSwiftGeocoding",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberGeocoding",
            ],
            path: "libPhoneNumberSwiftGeocoding"
        ),
        .target(
            name: "libPhoneNumberSwiftShortNumber",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberShortNumber",
            ],
            path: "libPhoneNumberSwiftShortNumber"
        ),
        .target(
            name: "libPhoneNumberSwiftCarrier",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberCarrier",
            ],
            path: "libPhoneNumberSwiftCarrier"
        ),
        .target(
            name: "libPhoneNumberSwiftTimeZones",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberTimeZones",
            ],
            path: "libPhoneNumberSwiftTimeZones"
        ),
        .target(
            name: "libPhoneNumberIOSSwift",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberSwiftGeocoding",
                "libPhoneNumberSwiftShortNumber",
            ],
            path: "libPhoneNumberIOSSwift"
        ),
        .target(
            name: "libPhoneNumberSwiftUI",
            dependencies: [
                "libPhoneNumberSwiftCore",
            ],
            path: "libPhoneNumberSwiftUI"
        ),
        .target(
            name: "libPhoneNumberSwiftUIEnrichment",
            dependencies: [
                "libPhoneNumberSwiftUI",
                "libPhoneNumberSwiftCarrier",
                "libPhoneNumberSwiftTimeZones",
            ],
            path: "libPhoneNumberSwiftUIEnrichment"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftCoreTests",
            dependencies: [
                "libPhoneNumberSwiftCore",
            ],
            path: "libPhoneNumberSwiftCoreTests"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftGeocodingTests",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberSwiftGeocoding",
            ],
            path: "libPhoneNumberSwiftGeocodingTests"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftShortNumberTests",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberSwiftShortNumber",
            ],
            path: "libPhoneNumberSwiftShortNumberTests"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftCarrierTests",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberSwiftCarrier",
            ],
            path: "libPhoneNumberSwiftCarrierTests"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftTimeZonesTests",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberSwiftTimeZones",
            ],
            path: "libPhoneNumberSwiftTimeZonesTests"
        ),
        .testTarget(
            name: "libPhoneNumberIOSSwiftTests",
            dependencies: [
                "libPhoneNumberIOSSwift",
            ],
            path: "libPhoneNumberIOSSwiftTests"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftUITests",
            dependencies: [
                "libPhoneNumberSwiftCore",
                "libPhoneNumberSwiftUI",
            ],
            path: "libPhoneNumberSwiftUITests"
        ),
        .testTarget(
            name: "libPhoneNumberSwiftUIEnrichmentTests",
            dependencies: [
                "libPhoneNumberSwiftUIEnrichment",
            ],
            path: "libPhoneNumberSwiftUIEnrichmentTests"
        ),
    ]
)
