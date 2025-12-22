import ProjectDescription

public enum Module {
    case app
    
    // Repository|DataStore
    case data
    
    // Domain
    case domain
    
    // Design|UI|View
    case presentation
}

extension Module {
    public var name: String {
        switch self {
        case .app:
            return "App"
        case .data:
            return "Data"
        case .domain:
            return "Domain"
        case .presentation:
            return "Presentation"
        }
    }
    
    public var path: ProjectDescription.Path {
        return .relativeToRoot("Projects/" + self.name)
    }
    
    public var project: TargetDependency {
        return .project(target: self.name, path: self.path)
    }
}

extension Module: CaseIterable { }
