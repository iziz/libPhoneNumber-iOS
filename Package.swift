// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "libPhoneNumber",
    platforms: [
        .macOS(.v10_11),
        .macCatalyst(.v13),
        .iOS(.v12),
        .tvOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "libPhoneNumber",
            targets: ["libPhoneNumber"],
        )
    ],
    targets: [
        .target(
            name: "libPhoneNumberTestsCommon",
            path: "libPhoneNumberTestsCommon",
            resources: [
                .copy("libPhoneNumberMetaDataForTesting.zip")
            ],
            publicHeadersPath: ".",
        ),
        .target(
            name: "libPhoneNumber",
            path: "libPhoneNumber",
            exclude: ["Info.plist"],
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
            path: "libPhoneNumberTests",
        )
    ]
)
