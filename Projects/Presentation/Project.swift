import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(module: Module.presentation,
                                dependencies: [Module.domain.project]
                                + [.snapKit, .kingfisher],
                                resources: .default)
