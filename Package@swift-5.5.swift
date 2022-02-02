// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "libPhoneNumber",
    platforms: [
        .macOS(.v10_10),
        .macCatalyst(.v13),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(
            name: "libPhoneNumber",
            targets: ["libPhoneNumber"]
        ),
        .library(
            name: "libPhoneNumberShortNumber",
            targets: ["libPhoneNumberShortNumber"]
        )
    ],
    targets: [
        .target(
            name: "libPhoneNumber",
            path: "libPhoneNumber",
            exclude: ["GeneratePhoneNumberHeader.sh", "NBPhoneNumberMetadata.plist", "Info.plist"],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Internal")
            ],
            linkerSettings: [
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS, .macOS, .macCatalyst])),
            ]
        ),
        .target(
            name: "libPhoneNumberShortNumber",
            path: "libPhoneNumberShortNumber",
            exclude: ["README.md", "Info.plist"],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../libPhoneNumber"),
                .headerSearchPath("../libPhoneNumber/Internal")
            ]
        ),
        .testTarget(
            name: "libPhoneNumberTests",
            dependencies: ["libPhoneNumber"],
            path: "libPhoneNumberTests",
            sources: [
                "NBAsYouTypeFormatterTest.m",
                "NBPhoneNumberParsingPerfTest.m",
                "NBPhoneNumberUtil+ShortNumberTestHelper.h",
                "NBPhoneNumberUtil+ShortNumberTestHelper.m",
                "NBPhoneNumberUtilTest.m",
                "NBShortNumberInfoTest.m"
            ]
        )
    ]
)
