//
//  ViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    // MARK: Properties
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var loginURL: URL?
    
    
    // MARK: Outlets
    
    @IBOutlet weak var loginButton: UIButton!
    
    
    // MARK: Functions
    
    func setup () {
        SPTAuth.defaultInstance().clientID = "003f496ec27d4f20961bf866071fb6fe"
        SPTAuth.defaultInstance().redirectURL = URL(string: "collabplaylists-login://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
    }
    
    func initializePlayer(authSession:SPTSession) {
        if self.player == nil {
            
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
            let sessionDataObj = sessionObj as! Data
            
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            self.session = firstTimeSession
            
            initializePlayer(authSession: session)
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        
        NSLog("logged in")
        
        self.player?.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
            })
        
        performSegue(withIdentifier: "loginSegue", sender: self)
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
            let destinationVC = navVC.viewControllers.first as! SongTableViewController
            destinationVC.session = session
        }
    }
    
    
    //MARK: Actions
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        if UIApplication.shared.openURL(loginURL!) {
            if auth.canHandle(auth.redirectURL) {
                // TODO - error handling
            }
        }
    }


}

