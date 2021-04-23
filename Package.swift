// swift-tools-version:4.1
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "libPhoneNumber",
    products: [
        .library(
            name: "libPhoneNumber",
            targets: ["libPhoneNumber"]
        )
    ],
    targets: [
        .target(
            name: "libPhoneNumber",
            path: "libPhoneNumber",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Internal")
            ],
            linkerSettings: [
                .linkedFramework("CoreTelephony"),
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
