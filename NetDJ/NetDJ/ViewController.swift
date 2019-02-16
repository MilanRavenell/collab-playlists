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
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var loginURL: URL?
    var userId: String?
    var svc: SFSafariViewController?
    var deviceToken: String?
    var isFirstTime = false
    @IBOutlet weak var mainImage: UIImageView!
    
    // MARK: Functions
    
    func setup () {
        SPTAuth.defaultInstance().clientID = "003f496ec27d4f20961bf866071fb6fe"
        SPTAuth.defaultInstance().redirectURL = URL(string: "collabplaylists-login://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserReadTopScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope]
        SPTAuth.defaultInstance().tokenSwapURL = URL(string: "http://autocollabservice.com/swap")
        SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "http://autocollabservice.com/refresh")
        SPTAuth.defaultInstance()
        loginURL = SPTAuth.loginURL(forClientId: "003f496ec27d4f20961bf866071fb6fe", withRedirectURL: URL(string: "collabplaylists-login://callback"), scopes: [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserReadTopScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope], responseType: "code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mainImage.frame = CGRect(x: 0, y: 0, width: self.view.frame.width , height: self.view.frame.height)
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateDeviceToken), name: NSNotification.Name(rawValue: "tokenRegistered"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let userDefaults = UserDefaults.standard
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
           if login(sessionObj: sessionObj) {
                self.performSegue(withIdentifier: "unwindLoginSegue", sender: self)
                return
            } else {
                retryAlert(sessionObj: sessionObj)
            }
        } else {
            let alert = UIAlertController(title: "You are not logged into a spotify account", message: "Log into your spotify prime account to continue", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: presentLogin))
            
            self.present(alert, animated: true)
        }
    }
    
    func updateAfterFirstLogin() {
        NSLog("updateafterfirstlogin")
        let userDefaults = UserDefaults.standard
        isFirstTime = true
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            if login(sessionObj: sessionObj) {
                svc!.dismiss(animated: true, completion: {() in self.performSegue(withIdentifier: "unwindLoginSegue", sender: self)})
            }
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
            
            let state = State(group: nil, user: user!, session: session, player: player)
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
    
    func presentLogin(alert: UIAlertAction!) {
        self.svc = SFSafariViewController(url: loginURL!)
        self.present(svc!, animated: true, completion: nil)
        if auth.canHandle(auth.redirectURL) {
            // TODO - error handling
            print("URL:")
            print(auth.redirectURL)
        }
    }
    
    func retryAlert(sessionObj: AnyObject) {
        let alert = UIAlertController(title: "You are not connected to the Internet", message: "Please connect and retry to continue", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] (_) in
            if self!.login(sessionObj: sessionObj) {
                self?.performSegue(withIdentifier: "unwindLoginSegue", sender: self!)
            } else {
                self?.retryAlert(sessionObj: sessionObj)
            }
        }))
        
        self.present(alert, animated: true)
    }
    
    func login(sessionObj: AnyObject) -> Bool {
        let sessionDataObj = sessionObj as! Data
        
        self.session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        
        if (!self.session.isValid()) {
            let newSession = Globals.renewSession(session: self.session)
            
            if (newSession == nil) {
                return false
            } else {
                self.session = newSession!
            }
        }
        self.userId = self.session.canonicalUsername
        
        print(self.session.accessToken)
        
        return self.session.isValid()
    }
    
    func updateDeviceToken() {
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
    
    // MARK: Helpers
}

