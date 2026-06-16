import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(module: Module.data,
                                dependencies: [Module.domain.project]
                                + [.moya, .combineMoya],
                                resources: [
                                    .glob(pattern: "Resources/**", excluding: [
                                        "Resources/AdaFace_IR18.mlpackage/**",
                                        "Resources/AdaFace_IR50.mlpackage/**"
                                    ]),
                                    .folderReference(path: "Resources/AdaFace_IR18.mlpackage"),
                                    .folderReference(path: "Resources/AdaFace_IR50.mlpackage")
                                ]
)
