import ProjectDescription
import ProjectDescriptionHelpers

let widgetExtensionName = "PhotoAnalysisWidgetExtension"

let widgetExtensionTarget = Target.target(
    name: widgetExtensionName,
    destinations: [.iPhone],
    product: .appExtension,
    bundleId: Project.bundleId + ".PhotoAnalysisWidget",
    deploymentTargets: .iOS(Project.iosVersion),
    infoPlist: .file(path: "PhotoAnalysisWidgetExtension/Info.plist"),
    sources: ["PhotoAnalysisWidgetExtension/Sources/**"],
    dependencies: [
        Module.photoAnalysisActivity.project,
        .sdk(name: "WidgetKit", type: .framework),
        .sdk(name: "SwiftUI", type: .framework)
    ],
    settings: .settings(base: [
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": SettingValue(stringLiteral: Project.developmentTeam)
    ])
)

let project = Project.app(module: Module.app,
                          dependencies: [
                            Module.data,
                            Module.domain,
                            Module.presentation,
                            Module.photoAnalysisActivity
                          ].map(\.project)
                          + [.firebaseCore, .firebaseAnalytics]
                          + [.target(name: widgetExtensionName)],
                          resources: .added(paths: [
                            "SupportingFiles/GoogleService-Info.plist",
                            "SupportingFiles/InfoPlist.xcstrings"
                          ]),
                          extraTargets: [widgetExtensionTarget])
