//
//  SceneDelegate.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 4/5/20.
//  Copyright © 2020 Ravenell, Milan. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, SPTSessionManagerDelegate {
    var window: UIWindow?
    
    static private let kAccessTokenKey = "access-token-key"
    static private let kRefreshTokenKey = "refresh-token-key"
    let SpotifyClientID = "003f496ec27d4f20961bf866071fb6fe"
    let SpotifyRedirectURL = URL(string: "collabplaylists-login://callback")!
    var isInitialized = false
    
    lazy var configuration = SPTConfiguration(
        clientID: SpotifyClientID,
        redirectURL: SpotifyRedirectURL
    )
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: "http://autocollabservice.com/swap"),
            let tokenRefreshURL = URL(string: "http://autocollabservice.com/refresh") {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = Globals.silentTrack
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: SceneDelegate.kAccessTokenKey)
        }
    }
    
    var refreshToken = UserDefaults.standard.string(forKey: kRefreshTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(refreshToken, forKey: SceneDelegate.kRefreshTokenKey)
        }
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let accessToken = self.accessToken {
            self.appRemote.connectionParameters.accessToken = accessToken
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        let parameters = appRemote.authorizationParameters(from: url);

        if let code = parameters?["code"] {
            let (access_token, refresh_token) = Globals.getTokens(code: code)
            
            // appRemote.connectionParameters.accessToken = access_token
            self.accessToken = access_token
            self.refreshToken = refresh_token
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
        } else if let error = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print (error)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "loginFailed"), object: nil)
        }

//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            self.appRemote.connect()
//        }
//        self.sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
//        if (self.isInitialized) {
//            if let _ = self.appRemote.connectionParameters.accessToken {
//              self.appRemote.connect()
//            }
//        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
//      if self.appRemote.isConnected {
//        self.appRemote.disconnect()
//      }
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        // Connection was successful, you can begin issuing commands
        print("connected")
        
        self.appRemote = appRemote
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            }
        })
        
        if let _ = self.appRemote.playerAPI  {
            NSLog("Got player API")
        }
        
        self.isInitialized = true
        
        //self.semaphore.signal()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("app remote connection disconnected")
    }
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("app remote connection failed")
        //self.semaphore.signal()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loginFailed"), object: nil)
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        debugPrint("Track name: %@", playerState.track.name)
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        self.accessToken = session.accessToken
        self.appRemote.connectionParameters.accessToken = session.accessToken
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.appRemote.connect()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print(manager.description)
        print(error)
        //TODO: Custom erorr messager when login fails
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loginFailed"), object: nil)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        self.accessToken = session.accessToken
        self.appRemote.connectionParameters.accessToken = session.accessToken
        SPTAppRemote.checkIfSpotifyAppIsActive({(isActive: Bool) -> Void in
            if !isActive && !self.appRemote.authorizeAndPlayURI(Globals.silentTrack) {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "loginFailed"), object: nil)
                return
            }
            
            self.appRemote.connect()
        })
    }
    
    func sessionManager(manager: SPTSessionManager, shouldRequestAccessTokenWith code: String) -> Bool {
        return true
    }
}
