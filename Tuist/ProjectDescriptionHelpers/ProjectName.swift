import ProjectDescription

public enum Module {
    case app

    // Repository|DataStore
    case data

    // Domain
    case domain

    // Design|UI|View
    case presentation

    // 앱 <-> Live Activity 위젯 익스텐션이 공유하는 ActivityAttributes만 담는 초경량 모듈
    case photoAnalysisActivity
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
        case .photoAnalysisActivity:
            return "PhotoAnalysisActivity"
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
