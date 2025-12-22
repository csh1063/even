import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(module: Module.app,
                          dependencies: [
                            Module.data,
                            Module.domain,
                            Module.presentation
                          ].map(\.project),
                          resources: .default)
