//
//  AppDelegate.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/26/24.
//
//
//import UIKit
//import Firebase
//
//@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        FirebaseApp.configure()
//        
//        // Register for remote notifications
//        registerForRemoteNotifications()
//        
//        return true
//    }
//    
//    func registerForRemoteNotifications() {
//        if #available(iOS 10.0, *) {
//            // For iOS 10 and above
//            UNUserNotificationCenter.current().delegate = self
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })
//        } else {
//            // For iOS 9 and below
//            let settings: UIUserNotificationSettings =
//                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            UIApplication.shared.registerUserNotificationSettings(settings)
//        }
//        
//        UIApplication.shared.registerForRemoteNotifications()
//    }
//
//    // Implement the method to get the device token for push notifications
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Here, you might want to send the device token to server or further process it
//    }
//    
//    // Implement the method to handle failure to register for remote notifications
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for remote notifications: \(error.localizedDescription)")
//    }
//    
//    // Add other AppDelegate methods if necessary...
//}
//
//// If using iOS 10 and above, extend AppDelegate to conform to UNUserNotificationCenterDelegate
//@available(iOS 10, *)
//extension AppDelegate: UNUserNotificationCenterDelegate {
//    // Handle push notifications for iOS 10 and above
//}
