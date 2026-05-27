// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LifeZonesMap",
    platforms: [
        .iOS(.v15) // Targets iOS 15 and up
    ],
    dependencies: [
        // Pulls the official Firebase library directly from GitHub
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
    ],
    targets: [
        .executableTarget(
            name: "LifeZonesMap",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk") // Useful if you plan to use maps/database later
            ],
            path: "LifeZonesMap" // Points to the folder containing your Swift files
        )
    ]
)
