import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(module: Module.presentation,
                                dependencies: [Module.domain.project, Module.photoAnalysisActivity.project]
                                + [.snapKit],// , .kingfisher],
                                resources: .default)
