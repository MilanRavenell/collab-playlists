//
//  ViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController {
    // MARK: Properties
    
    //var session: SPTSession!
    //var player: SPTAudioStreamingController?
    var loginURL: URL?
    var userId: String?
    var svc: SFSafariViewController?
    var deviceToken: String?
    var isFirstTime = false
    @IBOutlet weak var mainImage: UIImageView!
    static private let kAccessTokenKey = "access-token-key"
    var accessToken: String?
    var refreshToken: String?
    
    var appRemote: SPTAppRemote!
    var sessionManager: SPTSessionManager!
    
    let SpotifyClientID = "003f496ec27d4f20961bf866071fb6fe"
    let SpotifyRedirectURL = URL(string: "collabplaylists-login://callback")!
    
    lazy var configuration = SPTConfiguration(
        clientID: SpotifyClientID,
        redirectURL: SpotifyRedirectURL
    )
    
    // MARK: Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mainImage.frame = CGRect(x: 0, y: 0, width: self.view.frame.width , height: self.view.frame.height)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.loginSuccessful), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.loginFailed), name: NSNotification.Name(rawValue: "loginFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateDeviceToken), name: NSNotification.Name(rawValue: "tokenRegistered"), object: nil)
        
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
                self.sessionManager = sd.sessionManager
                self.appRemote = sd.appRemote
            }
        } else {
            // Fallback on earlier versions
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.appRemote = appDelegate.appRemote
            self.sessionManager = appDelegate.sessionManager
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userDefaults = UserDefaults.standard
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            renewSM(session: session)
        } else {
            let alert = UIAlertController(title: "You are not logged into a spotify account", message: "Log into your spotify prime account to continue", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: presentLogin))
            
            self.present(alert, animated: true)
        }
    }
    
    // Set up session manager and app remote
    func renewSM(session : SPTSession) {
        self.sessionManager.session = session
//        self.session = session
//
//        let _ = Globals.renewSession(sessionManager: self.sessionManager)
    }
    
    // Assume we have a valid session manager and app remote at this point
    @objc func loginSuccessful() {
        NSLog("loginSuccessful")
        isFirstTime = false
        
        DispatchQueue.main.async { [self] in
            if #available(iOS 13.0, *) {
                let scene = UIApplication.shared.connectedScenes.first
                if let sd : SceneDelegate = (scene?.delegate as? SceneDelegate) {
//                    self.sessionManager = sd.sessionManager
//                    self.appRemote = sd.appRemote
//                    self.session = sd.sessionManager.session
                    self.accessToken = sd.accessToken
                    self.refreshToken = sd.refreshToken
                }
            } else {
                // Fallback on earlier versions
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                self.appRemote = appDelegate.appRemote
                self.sessionManager = appDelegate.sessionManager
                // self.session = appDelegate.sessionManager.session
            }
            
            self.userId = self.getUserId(accessToken: self.accessToken!)
            
//            if let session = self.session {
//                let userDefaults = UserDefaults.standard
//                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
//                userDefaults.set(sessionData, forKey: "SpotifySession")
//                userDefaults.synchronize()
//            }
            
            self.performSegue(withIdentifier: "unwindLoginSegue", sender: self)
        }
    }
    
    func presentLogin(alert: UIAlertAction!) {
        let requestedScopes: SPTScope = [.appRemoteControl, .streaming, .playlistReadPrivate, .playlistModifyPublic, .playlistModifyPrivate, .userTopRead, .userLibraryRead, .userLibraryModify]
        if #available(iOS 11.0, *) {
            self.sessionManager.initiateSession(with: requestedScopes, options: .default)
        } else {
            // Fallback on earlier versions
            self.sessionManager.initiateSession(with: requestedScopes, options: .default, presenting: self)
        }
    }
    
    @objc func loginFailed() {
        let alert = UIAlertController(title: "You are not connected to the Internet", message: "Please connect and retry to continue", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: presentLogin))
        
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if (segue.identifier == "unwindLoginSegue") {
            let destinationVC = segue.destination as! NetworkTableViewController
            
            let user = User(id: userId!, name: nil)
            
            let state = State(group: nil, user: user!, session: nil, sessionManager: self.sessionManager, appRemote: appRemote, accessToken: self.accessToken!, refreshToken: self.refreshToken!)
            state?.user.name = Globals.getUsersName(id: userId!, state: state!)
            DispatchQueue.global().async {
                state?.user.getSavedSongs(state: state!)
            }
            
            if let networks = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.networksFilePath) as? [Group] {
                for network in networks {
                    network.state = state
                    state?.userNetworks[network.id] = network
                }
            } else {
                let networks = Globals.getGroupsById(ids: Globals.getUserGroups(userId: userId!), state: state!)
                
                for network in networks {
                    let networkSongs = Globals.getPlaylistSongs(userId: userId!, groupId: network.id, state: state!)
                    if networkSongs.count > 0 {
                        network.songs = [networkSongs[0]]
                    }
                    
                    state?.userNetworks[network.id] = network
                }
            }
            
            DispatchQueue.global().async {
                // Add defaults
                Globals.getUserSongs(user: user!, groupId: -1, state: state!)
                state!.user.getPlaylists(state: state!)
                Globals.getUserSelectedPlaylists(user: user!, groupId: -1, state: state!)

                if let playlists = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.playlistsFilePath) as? [Playlist] {
                    for playlist in playlists {
                        playlist.state = state
                        if let selectedPlaylists = state!.user.selectedPlaylists[-1], selectedPlaylists.contains(playlist.id) {
                            state!.user.songs[-1]?.append(contentsOf: playlist.getSongs()  )
                        }
                    }
                }
                
                state!.user.defaultsLoaded = true
                if let songsVC = state!.songsVC {
                    songsVC.mySongsDidFinishLoading()
                }
            }

            destinationVC.state = state
            destinationVC.doFirstTimeAlert = isFirstTime
            if (self.deviceToken != nil) {
                addDeviceToken(token: self.deviceToken!, userId: self.userId!)
            }
        }
    }
    
    @objc func updateDeviceToken() {
        let userDefaults = UserDefaults.standard
        if let tokenObj:AnyObject = userDefaults.object(forKey: "DeviceToken") as AnyObject? {
            let tokenDataObj = tokenObj as! Data
            
            self.deviceToken = NSKeyedUnarchiver.unarchiveObject(with: tokenDataObj) as! String
        }

    }
    
    func addDeviceToken(token: String, userId: String) {
        let requestURL = URL(string: "http://autocollabservice.com/adddevicetoken")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "&spotifyId=" + userId
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
    }
    
    func getUserId(accessToken: String) -> String? {
        let query = "https://api.spotify.com/v1/me"
        let url = URL(string: query)
        let request = NSMutableURLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var responseUserId: String?
        
        Globals.sendRequest(request: request, postParameters: nil, method: "GET", completion: { (response) in
            let responseDict = response as? [String: AnyObject]
            responseUserId = responseDict?["id"] as? String
        }, isAsync: 0)
        
        if (responseUserId == nil) {
            print("Could not retrieve userId")
            return nil
        }
        
        return responseUserId
    }
}

