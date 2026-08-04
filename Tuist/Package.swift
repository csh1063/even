// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [
            "Alamofire": .framework,
            "Moya": .framework,
            "CombineMoya": .framework,
            "SnapKit": .framework,
//            "Kingfisher": .framework,
//            "Lottie": .framework
            "FirebaseCore": .framework,
            "FirebaseCoreInternal": .framework,
            "FirebaseCoreExtension": .framework,
            "FirebaseInstallations": .framework,
            "FirebaseSharedSwift": .framework,
            "GoogleUtilities": .framework,
            // GoogleUtilities는 세부 기능별로 별도 SPM 프로덕트("GoogleUtilities-XXX")로
            // 쪼개져 있어서, 위 "GoogleUtilities" 하나만 지정해서는 안 먹힌다 — App과
            // FirebaseCoreInternal 양쪽에서 정적으로 각각 링크되면서 카테고리(NSData+gzip 등)
            // 등록이 유실돼 실기기에서 "unrecognized selector" 크래시가 났다. 전부 동적으로 강제.
            "GoogleUtilities-AppDelegateSwizzler": .framework,
            "GoogleUtilities-Environment": .framework,
            "GoogleUtilities-Logger": .framework,
            "GoogleUtilities-MethodSwizzler": .framework,
            "GoogleUtilities-Network": .framework,
            "GoogleUtilities-NSData": .framework,
            "GoogleUtilities-Reachability": .framework,
            "GoogleUtilities-UserDefaults": .framework
        ]
        ,
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug"),
                .release(name: "Release")
            ])
    )
#endif

let package = Package(
    name: "Projects",
    dependencies: [
//        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit", from: "5.0.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.17.0")
//        .package(url: "https://github.com/onevcat/Kingfisher", from: "5.15.6"),
//        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "3.2.1")
    ]
)
