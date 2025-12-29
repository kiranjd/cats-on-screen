// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CatOnScreen",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "CatOnScreen", targets: ["CatOnScreen"])
    ],
    targets: [
        .executableTarget(
            name: "CatOnScreen",
            exclude: ["Resources/Info.plist"],
            resources: [
                .copy("Resources/Assets")
            ]
        )
    ]
)
