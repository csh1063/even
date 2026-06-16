import ProjectDescription

public extension ProjectDescription.ResourceFileElements {
    static let `default`: ProjectDescription.ResourceFileElements = ["Resources/**"]
    static func added(paths: [ResourceFileElement]) -> ProjectDescription.ResourceFileElements {
        .resources(["Resources/**"] + paths)
    }
}
