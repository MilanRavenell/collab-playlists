//
//  AppDelegate.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var auth = SPTAuth()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        auth.redirectURL = URL(string: "collabplaylists-login://callback")
        auth.sessionUserDefaultsKey = "current session"
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        //registerForPushNotifications()
        //UNUserNotificationCenter.current().delegate = self
        
        // If user opened app from push notification
//        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
//            // 2
//            let aps = notification["aps"] as! [String: AnyObject]
//        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Called when a user logs into Spotify
        if url.absoluteString.contains("collabplaylists-login://callback/") && auth.canHandle(auth.redirectURL) {
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { [unowned self] (error, _) in
                
                if error != nil {
                    print(error)
                }

                var code = ""
                if let startIndex = url.absoluteString.range(of: "collabplaylists-login://callback/?code=")?.upperBound {
                    code = url.absoluteString[startIndex ..< url.absoluteString.endIndex]
                }
                
                let tokens = Globals.getTokens(code: code)
                print(tokens.1)
                if let userName = self.getUserId(accessToken: tokens.0) {
                    Globals.createUser(userId: userName)
                    
                    
                    let session = SPTSession(userName: userName, accessToken: tokens.0, encryptedRefreshToken: tokens.1, expirationDate: Date.init(timeIntervalSinceNow: 3600))
                    
                    if (session == nil) {
                        print("session init failed!")
                        return
                    }
                    
                    let userDefaults = UserDefaults.standard
                    let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                    
                    userDefaults.set(sessionData, forKey: "SpotifySession")
                    userDefaults.synchronize()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
                }
            })
            return true
            
        } else if url.absoluteString.contains("fb1886072364788623://") {
            return FBSDKApplicationDelegate.sharedInstance().application(_:app, open: url, options: options)
        }
        
        
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        FBSDKAppEvents.activateApp()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        
        let userDefaults = UserDefaults.standard
        let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
        print(tokenData)
        userDefaults.set(tokenData, forKey: "DeviceToken")
        userDefaults.synchronize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tokenRegistered"), object: nil)
        
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    // When a user receives push notification while in app
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let aps = userInfo["aps"] as! [String: AnyObject]
        
        // use this to check for silent notification, 1 means is silent
        if aps["content-available"] as? Int == 1 {

        } else  {

        }
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            
            // 1
            let viewAction = UNNotificationAction(identifier: "viewAction",
                                                  title: "View",
                                                  options: [.foreground])
            
            // 2
            let newsCategory = UNNotificationCategory(identifier: "NEWS_CATEGORY",
                                                      actions: [viewAction],
                                                      intentIdentifiers: [],
                                                      options: [])
            // 3
            UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
            
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func getUserId(accessToken: String) -> String? {
        // Get user Id
        let request = try? SPTUser.createRequestForCurrentUser(withAccessToken: accessToken)
        
        if (request == nil) {
            NSLog("failed")
            return nil
        }
        
        let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
        
        let data = try? NSURLConnection.sendSynchronousRequest(request!, returning: response)
        
        if (data == nil) {
            return nil
        }
        
        do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] {
                if let _ = jsonResult["error"] {
                    return nil
                }
                return jsonResult["id"] as! String
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
        return nil
    }
}

// Respond to push notification action
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 1
        let userInfo = response.notification.request.content.userInfo
        let aps = userInfo["aps"] as! [String: AnyObject]
        
//        // 2
//        if let newsItem = NewsItem.makeNewsItem(aps) {
//            (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
//
//            // 3
//            if response.actionIdentifier == viewActionIdentifier,
//                let url = URL(string: newsItem.link) {
//                let safari = SFSafariViewController(url: url)
//                window?.rootViewController?.present(safari, animated: true, completion: nil)
//            }
//        }
        
        // 4
        completionHandler()
    }
}

