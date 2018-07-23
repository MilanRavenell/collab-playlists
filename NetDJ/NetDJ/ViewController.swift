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
    @IBOutlet weak var mainImage: UIImageView!
    
    // MARK: Functions
    
    func setup () {
        SPTAuth.defaultInstance().clientID = "003f496ec27d4f20961bf866071fb6fe"
        SPTAuth.defaultInstance().redirectURL = URL(string: "collabplaylists-login://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserReadTopScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope]
        SPTAuth.defaultInstance().tokenSwapURL = URL(string: "http://autocollabservice.com/swap")
        SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "http://autocollabservice.com/refresh")
        SPTAuth.defaultInstance()
//        loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
//        print(loginURL)
        loginURL = SPTAuth.loginURL(forClientId: "003f496ec27d4f20961bf866071fb6fe", withRedirectURL: URL(string: "collabplaylists-login://callback"), scopes: [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserReadTopScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope], responseType: "code")
//        print(loginURL)
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
                self.performSegue(withIdentifier: "loginSegue", sender: self)
                return
            }
        }
        let alert = UIAlertController(title: "You are not logged into a spotify account", message: "Log into your spotify prime account to continue", preferredStyle: .alert)
            
        alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: presentLogin))
        
        self.present(alert, animated: true)
    }
    
    func updateAfterFirstLogin() {
        NSLog("updateafterfirstlogin")
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            if login(sessionObj: sessionObj) {
                svc!.dismiss(animated: true, completion: {() in self.performSegue(withIdentifier: "loginSegue", sender: self)})
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if (segue.identifier == "loginSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            
            let groups = Globals.getGroupsById(ids: getUserGroups())
            var songs = [Int: [Song]]()
            var playlists = [Int: [Playlist]]()
            
            let user = User(id: userId!, name: nil)
            let state = State(group: nil, user: user!, session: session, player: player)
            state?.user.name = Globals.getUsersName(id: userId!, state: state!)
            
            DispatchQueue.global().async {
                // Add defaults
                songs[-1] = Globals.getUserSongs(userId: self.userId!, groupId: -1, state: state!)
                playlists[-1] = Globals.getUserPlaylists(userId: self.userId!, groupId: -1, state: state!)
                state!.user.songs = songs
                state!.user.playlists = playlists
                state!.user.topSongs = Globals.getTopSongs(userId: user!.id, num: 20, state: state!)
            }
            for group in groups {
                state?.userNetworks[group.id] = group
            }
            destinationVC.state = state
            if (self.deviceToken != nil) {
                addDeviceToken(token: self.deviceToken!, userId: self.userId!)
            }
        }
    }
    
    func presentLogin(alert: UIAlertAction!) {
        self.svc = SFSafariViewController(url: loginURL!)
        self.present(svc!, animated:true, completion: nil)
        if auth.canHandle(auth.redirectURL) {
            // TODO - error handling
            print("URL:")
            print(auth.redirectURL)
        }
    }
    
    func login(sessionObj: AnyObject) -> Bool{
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
        addSpotifyId(userId: self.userId!)
        
        return self.session.isValid()
    }
    
    func addSpotifyId(userId: String) {
        let requestURL = URL(string: "http://autocollabservice.com/addspotifyid")
        let request = NSMutableURLRequest(url: requestURL!)
        print(session.encryptedRefreshToken)
        let postParameters = "spotifyId=" + userId
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
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
    func getUserGroups() -> [Int] {
        print("usergroups")
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusergroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        let postParameters = "userId=" + userId!
        
        var responseDict: [String: AnyObject]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {(response) in
            responseDict = response as? [String: AnyObject]
        }, isAsync: 0)
        
        if (responseDict == nil) {
            return []
        }
        
        return responseDict!["groups"] as! [Int]
    }
}

