import ProjectDescription

extension Project {
    
    static let bundleId = "com.sanghyeon.moa"
    static let iosVersion = "15.0"
    
    /// Helper function to create the Project for this ExampleApp
    public static func app(
        module: Module,
        dependencies: [TargetDependency] = [],
        resources: ProjectDescription.ResourceFileElements? = nil,
        coreDataModels: [CoreDataModel] = []
    ) -> Project {
        return makeProject(
            module: module,
            product: .app,
            bundleId: bundleId + ".\(module.name)",
            dependencies: dependencies,
            resources: resources,
            coreDataModels: coreDataModels)
    }
    
    public static func framework(module: Module,
                                 dependencies: [TargetDependency] = [],
                                 resources: ProjectDescription.ResourceFileElements? = nil,
                                 coreDataModels: [CoreDataModel] = []
    ) -> Project {
        return makeProject(
            module: module,
            product: .framework,
            bundleId: bundleId + ".\(module.name)",
            dependencies: dependencies,
            resources: resources,
            coreDataModels: coreDataModels)
    }

    // MARK: - Private
    private static func makeProject(
        module: Module,
        product: Product,
        bundleId: String,
        schemes: [Scheme] = [],
        dependencies: [TargetDependency] = [],
        resources: ProjectDescription.ResourceFileElements? = nil,
        coreDataModels: [CoreDataModel] = []) -> Project {
            return Project(
                name: module.name,
                organizationName: "sanghyeon",
                settings: .settings(
                    configurations: [
                        .debug(name: "dev"),
                        .release(name: "prod")
                    ]),
                targets: [
                    makeTarget(
                        module: module,
                        product: product,
                        bundleId: bundleId,
                        sources: ["Sources/**"],
                        resources: resources,
                        dependencies: dependencies,
                        coreDataModels: coreDataModels
                    ),
//                    makeTarget(
//                        name: "\(name)Tests",
//                        product: .unitTests,
//                        bundleId: bundleId,
//                        sources: ["Tests/**"],
//                        resources: nil,
//                        dependencies: [
//                            .target(name: "\(name)")
//                        ]
//                    ),
                ],
                schemes: schemes)
        }
    
    private static func makeTarget(
        module: Module,
        product: Product,
        bundleId: String,
        sources: SourceFilesList?,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        coreDataModels: [CoreDataModel] = []) -> Target {
            
            return .target(
                name: module.name,
                destinations: .iOS,
                product: product,
                productName: product == .app ? module.name:nil,
                bundleId: bundleId,
                deploymentTargets: .iOS(self.iosVersion),
                infoPlist: product == .app ? .file(path: "SupportingFiles/Info.plist"):.default,
                sources: sources,
                resources: resources,
                dependencies: dependencies,
                coreDataModels: coreDataModels
            )
        }
}

public extension TargetDependency {
//    static let alamofire: TargetDependency       = .external(name: "Alamofire")
    static let moya: TargetDependency            = .external(name: "Moya")
    static let combineMoya: TargetDependency     = .external(name: "CombineMoya")
    static let snapKit: TargetDependency         = .external(name: "SnapKit")
    static let kingfisher: TargetDependency      = .external(name: "Kingfisher")
//    static let lottie: TargetDependency          = .external(name: "Lottie")
}
