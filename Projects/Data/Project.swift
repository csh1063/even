import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(module: Module.data,
                                dependencies: [Module.domain.project]
                                + [.moya, .combineMoya],
                                resources: .default
)
