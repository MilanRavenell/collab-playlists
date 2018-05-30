//
//  ViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    // MARK: Properties
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var loginURL: URL?
    var userId: String?
    var svc: SFSafariViewController?
    
    
    // MARK: Outlets
    
    @IBOutlet weak var loginButton: UIButton!
    
    
    // MARK: Functions
    
    func setup () {
        SPTAuth.defaultInstance().clientID = "003f496ec27d4f20961bf866071fb6fe"
        SPTAuth.defaultInstance().redirectURL = URL(string: "collabplaylists-login://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthUserReadTopScope]
        loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()
        let userDefaults = UserDefaults.standard
        if let _:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            loginButton.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let userDefaults = UserDefaults.standard
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            loginButton.isHidden = true
            if login(sessionObj: sessionObj) {
                self.performSegue(withIdentifier: "loginSegue", sender: self)
            } else {
                loginButton.isHidden = false
            }
        }
    }
    
    func initializePlayer(authSession:SPTSession) {
        if self.player == nil {
            
            NSLog("player")
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
            
        }
    }
    
    func updateAfterFirstLogin() {
        NSLog("updateafterfirstlogin")
        loginButton.isHidden = true
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
            let destinationVC = navVC.viewControllers.first as! EventTableViewController
            destinationVC.session = session
            destinationVC.userId = userId!
            destinationVC.player = player!
        }
    }
    
    
    //MARK: Actions
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        self.svc = SFSafariViewController(url: loginURL!)
        self.present(svc!, animated:true, completion: nil)
        if auth.canHandle(auth.redirectURL) {
            // TODO - error handling
        }
    }
    
    //MARK: Helpers
    func login(sessionObj: AnyObject) -> Bool{
        let sessionDataObj = sessionObj as! Data
        
        let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        
        self.session = firstTimeSession
        
        initializePlayer(authSession: session)
        
        
        // Get user Id
        
        let request = try? SPTUser.createRequestForCurrentUser(withAccessToken: session.accessToken)
        
        if (request == nil) {
            NSLog("failed")
            return false
        }
        
        let response: AutoreleasingUnsafeMutablePointer<URLResponse?>? = nil
        
        let data = try? NSURLConnection.sendSynchronousRequest(request!, returning: response)
        
        if (data == nil) {
            return false
        }
        
        do {
            if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] {
                if let _ = jsonResult["error"] {
                    return false
                }
                userId = jsonResult["id"] as! String
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return true
    }
}

