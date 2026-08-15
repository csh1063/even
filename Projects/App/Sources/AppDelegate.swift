import UIKit
import BackgroundTasks
import FirebaseCore
import FirebaseAnalytics
import Presentation
import Domain

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // BGProcessingTask는 앱이 완전히 종료된 뒤 순수 백그라운드 실행으로 재시작될 수도 있어
    // SceneDelegate/코디네이터 경로에 의존할 수 없다 — AppDelegate가 자체 DI 그래프를 하나 들고 있는다.
    private var backgroundDIContainer: DefaultAppDIContainer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)

        AnalyticsTracker.shared.logHandler = { pageTitle in
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: pageTitle,
                AnalyticsParameterScreenClass: pageTitle
            ])
        }

        let diContainer = DefaultAppDIContainer()
        self.backgroundDIContainer = diContainer
        let analysisUseCase = DefaultPhotoAnalysisUseCase(
            libraryRepository: diContainer.photoLibraryRepository,
            analysisRepository: diContainer.photoAnalysisRepository,
            dataRepository: diContainer.photoDataRepository,
            geoRepository: diContainer.geoRepository,
            userDefaultRepository: diContainer.userDefaultRepository
        )
        BackgroundProcessingScheduler.shared.configure(analysisUseCase: analysisUseCase)
        BackgroundProcessingScheduler.shared.register()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
