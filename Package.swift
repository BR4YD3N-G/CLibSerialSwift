// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CLibSerialSwift",
    products: [
        .library(
            name: "CLibSerialSwift",
            targets: ["CLibSerialSwift"]
        ),
    ],
    targets: [
        // C libserialport
        .target(
            name: "libserialport",
            path: "Sources/libserialport",
            sources: {
                #if os(Windows)
                ["windows.c"]
                #elseif os(macOS)
                ["macosx.c"]
                #elseif os(Linux)
                ["linux.c", "linux_termios.c"]
                #else
                []
                #endif
            }(),
            publicHeadersPath: ".",
            cSettings: [
                .define("BUILDING_LIBSERIALPORT"),
                .define("SP_PRIV", to: ""),
                .unsafeFlags([
                    "-Wno-macro-redefined" // for the DEBUG warning
                ])
            ]
        ),

        // Swift wrapper
        .target(
            name: "CLibSerialSwift",
            dependencies: ["libserialport"],
            path: "Sources/CLibSerialSwift",
            publicHeadersPath: ".",
            cSettings: [
                .unsafeFlags([
                    "-fmodule-map-file=Sources/CLibSerialSwift/module.modulemap"
                ])
            ]
        ),

        .testTarget(
            name: "CLibSerialSwiftTests",
            dependencies: ["CLibSerialSwift"]
        ),
    ]
)
