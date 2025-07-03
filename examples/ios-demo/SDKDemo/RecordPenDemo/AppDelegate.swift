import PenBleSDK
import UIKit
#if ENABLE_FIREBASE
    import FirebaseAnalytics
    import FirebaseCore
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set default language at the earliest stage of app launch
        PLLanguageManager.setupDefaultLanguageEarly()

        // Setup default language
        PLLanguageManager.shared().setupDefaultLanguage()

        BleAgent.shared.openLog(true) { message in
            debugPrint("BleAgent: \(message)")
        }

        #if ENABLE_FIREBASE
            FirebaseApp.configure()
        #endif

        // WiFiAgent.shared.openLog(true) { message in
        //  debugPrint("WiFiAgent: \(message)")
        // }

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white

        let nav = UINavigationController(rootViewController: DemoMainViewController())

        // let nav = UINavigationController(rootViewController: MainViewController())

        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
