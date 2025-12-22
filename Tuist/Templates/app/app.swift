import ProjectDescription

// command line 입력 --name 파라미터에 들어가는 값
// ex) tuist scaffold jake --name1 hihi
let nameAttribute: Template.Attribute = .required("name")
let orgAttribute: Template.Attribute = .optional("org", default: "sanghyeon")

let template = Template(
    description: "my template",
    attributes: [
        nameAttribute,
        orgAttribute
    ],
    items: [
        // template
        .file(
            path: "README.md",
            templatePath: "stencil/README.stencil"
        ),
        .file(
            path: "Tuist.swift",
            templatePath: "stencil/Tuist.stencil"
        ),
        .file(
            path: "Workspace.swift",
            templatePath: "stencil/Workspace.stencil"
        ),
        // template/tuist
        .file(
            path: "Tuist/Package.swift",
            templatePath: "stencil/Tuist/Package.stencil"
        ),
        // template/tuist/ProjectDescriptionHelpers
        .file(
            path: "Tuist/ProjectDescriptionHelpers/Project+Template.swift",
            templatePath: "stencil/Tuist/ProjectDescriptionHelpers/Project+Template.stencil"
        ),
        .file(
            path: "Tuist/ProjectDescriptionHelpers/ProjectName.swift",
            templatePath: "stencil/Tuist/ProjectDescriptionHelpers/ProjectName.stencil"
        ),
        .file(
            path: "Tuist/ProjectDescriptionHelpers/ResourceExtensions.swift",
            templatePath: "stencil/Tuist/ProjectDescriptionHelpers/ResourceExtensions.stencil"
        ),
        // project/app
        .file(
            path: "Projects/App/Project.swift",
            templatePath: "stencil/Projects/App/Project.stencil"
        ),
        .file(
            path: "Projects/App/Sources/AppDelegate.swift",
            templatePath: "stencil/Projects/App/Sources/AppDelegate.stencil"
        ),
        .file(
            path: "Projects/App/Sources/SceneDelegate.swift",
            templatePath: "stencil/Projects/App/Sources/SceneDelegate.stencil"
        ),
        .file(
            path: "Projects/App/Resources/Assets.xcassets/Contents.json",
            templatePath: "stencil/Projects/App/Resources/Asset.stencil"
        ),
        .file(
            path: "Projects/App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json",
            templatePath: "stencil/Projects/App/Resources/Asset.stencil"
        ),
        // project/Supporting Files
        .file(
            path: "Projects/App/SupportingFiles/Info.plist",
            templatePath: "stencil/Projects/App/SupportingFiles/Info.stencil"
        ),
        // project/domain
        .file(
            path: "Projects/Domain/Project.swift",
            templatePath: "stencil/Projects/Domain/Project.stencil"
        ),
        .file(
            path: "Projects/Domain/Sources/Domain.swift",
            templatePath: "stencil/Tuist/SourceTemplate.stencil"
        ),
        // project/data
        .file(
            path: "Projects/Data/Project.swift",
            templatePath: "stencil/Projects/Data/Project.stencil"
        ),
        .file(
            path: "Projects/Data/Sources/Data.swift",
            templatePath: "stencil/Tuist/SourceTemplate.stencil"
        ),
        // project/designStytem
        // .file(
        //     path: "Projects/DesignStytem/Project.swift",
        //     templatePath: "stencil/Projects/DesignStytem/Project.stencil"
        // ),
        // .file(
        //     path: "Projects/DesignStytem/Sources/Data.swift",
        //     templatePath: "stencil/Tuist/SourceTemplate.stencil"
        // ),
        // .file(
        //     path: "Projects/DesignStytem/Resources/Assets.xcassets/Contents.json",
        //     templatePath: "stencil/Projects/DesignStytem/Resources/Asset.stencil"
        // ),
        // .file(
        //     path: "Projects/DesignStytem/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json",
        //     templatePath: "stencil/Projects/DesignStytem/Resources/Asset.stencil"
        // ),
        // project/presentation
        .file(
            path: "Projects/Presentation/Project.swift",
            templatePath: "stencil/Projects/Presentation/Project.stencil"
        ),
        .file(
            path: "Projects/Presentation/Sources/ViewController.swift",
            templatePath: "stencil/Projects/Presentation/Sources/ViewController.stencil"
        ),
        .file(
            path: "Projects/Presentation/Resources/Assets.xcassets/Contents.json",
            templatePath: "stencil/Projects/Presentation/Resources/Asset.stencil"
        ),
        .file(
            path: "Projects/Presentation/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json",
            templatePath: "stencil/Projects/Presentation/Resources/Asset.stencil"
        ),
    ]
)

