import AdSupport
import AppTrackingTransparency
import Firebase
import FirebaseCore
import FirebaseMessaging
import GoogleMobileAds
//
//  SnoozeLaneApp.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//
import SwiftUI
import UserNotifications

@main
struct SnoozeLaneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var windowSharedModel = WindowSharedModel()
    // Initialize once and share
    //    let locationManager = LocationManager()
    //    @EnvironmentObject var locationManager: LocationManager
    @StateObject var locationManager = LocationManager()
    @StateObject var loginViewModel = LoginViewModel()
    @StateObject var locationSearchViewModel = LocationSearchViewModel(
        locationManager: LocationManager())
    @StateObject var tripProgressViewModel = TripProgressViewModel(
        locationViewModel: LocationSearchViewModel(locationManager: LocationManager()))

    //    var locationSearchViewModel: LocationSearchViewModel

    init() {

        GADMobileAds.sharedInstance().start(completionHandler: nil)
        //        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["9899d44045852d6e501208b00aebe2c4"]
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "46c658083659f34c29e3a2de4abfb1d9"
        ]

        //        locationSearchViewModel = LocationSearchViewModel(locationManager: locationManager)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        //        locationManager.requestAuthorization()
        //        locationManager.startUpdatingLocation()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationSearchViewModel)
                .environmentObject(loginViewModel)
                .environmentObject(tripProgressViewModel)
                .environmentObject(locationManager)
                .environmentObject(windowSharedModel)
            //                .environmentObject(TripProgressViewModel(locationViewModel: locationSearchViewModel))
        }
    }
}

// intializing Firebase...
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate,
    UNUserNotificationCenterDelegate
{

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()

        // Register for remote notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()

        // Set up Firebase messaging delegate
        Messaging.messaging().delegate = self

        return true
    }

    func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) {
        // Handle foreground notifications
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }

        print(userInfo)
    }

    // Needed For Firebase Phone Auth....
    func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {

        // Handle background notifications
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)

        completionHandler(UIBackgroundFetchResult.newData)
    }

    // Implement the method to get the device token for push notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {

        // Here, you might want to send the device token to server or further process it
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")

        let firebaseAuth = Auth.auth()
        firebaseAuth.setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
    }

    // Implement the method to handle failure to register for remote notifications
    func application(
        _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Firebase Messaging Delegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")

        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

/// Scene Delegate
@Observable
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    weak var windowScene: UIWindowScene?

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        windowScene = scene as? UIWindowScene
    }

    /// Adding Tab Bar as an another Window
    func addTabBar(_ windowSharedModel: WindowSharedModel) {
        // Tab bar functionality removed - using floating buttons instead
    }
}
