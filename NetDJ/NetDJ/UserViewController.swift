//
//  UserViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/9/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class UserViewController: UIViewController {
    
    // MARK: Properties
    var setDefaultSongs: UIButton!
    var setDefaultPlaylists: UIButton!
    var viewRequests: UIButton!
    var facebookBtn: UIButton!
    var groupRequests = [Group]()
    
    var state: State?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Globals.getThemeColor2()
        
        self.title = Globals.getUsersName(id: self.state!.user.id, session: self.state!.session)
        self.groupRequests = getUserGroupRequests()
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        // Create Subviews
        let defaultSongsView = UIView(frame: CGRect(x: 0, y: 125, width: self.view.frame.width, height: 50))
        defaultSongsView.backgroundColor = UIColor.white
        
        let defaultPlaylistsView = UIView(frame: CGRect(x: 0, y: 180, width: self.view.frame.width, height: 50))
        defaultPlaylistsView.backgroundColor = UIColor.white
        
        let requestsView = UIView(frame: CGRect(x: 0, y: 280, width: self.view.frame.width, height: 50))
        requestsView.backgroundColor = UIColor.white
        
        let fbView = UIView(frame: CGRect(x: 0, y: 375, width: self.view.frame.width, height: 50))
        fbView.backgroundColor = UIColor.white
        
        self.view.addSubview(defaultSongsView)
        self.view.addSubview(defaultPlaylistsView)
        self.view.addSubview(requestsView)
        self.view.addSubview(fbView)
        
        
        // Create Buttons
        setDefaultSongs = UIButton(type: .system)
        setDefaultSongs.frame = CGRect(x: 0, y: 0, width: defaultSongsView.frame.width, height: defaultSongsView.frame.height)
        setDefaultSongs.setTitle("Set Default Songs", for: .normal)
        setDefaultSongs.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        setDefaultSongs.setTitleColor(Globals.getThemeColor1(), for: .normal)
        defaultSongsView.addSubview(setDefaultSongs)
        
        setDefaultPlaylists = UIButton(type: .system)
        setDefaultPlaylists.frame = CGRect(x: 0, y: 0, width: defaultSongsView.frame.width, height: defaultSongsView.frame.height)
        setDefaultPlaylists.setTitle("Set Default Playlists", for: .normal)
        setDefaultPlaylists.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        setDefaultPlaylists.setTitleColor(Globals.getThemeColor1(), for: .normal)
        defaultPlaylistsView.addSubview(setDefaultPlaylists)
        
        viewRequests = UIButton(type: .system)
        viewRequests.frame = CGRect(x: 0, y: 0, width: requestsView.frame.width, height: requestsView.frame.height)
        viewRequests.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        viewRequests.setTitleColor(Globals.getThemeColor1(), for: .normal)
        viewRequests.setTitle("View Group Requests(" + String(self.groupRequests.count) + ")", for: .normal)
        requestsView.addSubview(viewRequests)
        
        
        facebookBtn = UIButton(type: .system)
        facebookBtn.frame = CGRect(x: 0, y: 0, width: fbView.frame.width, height: fbView.frame.height)
        facebookBtn.addTarget(self, action: #selector(facebookBtnPressed), for: .touchUpInside)
        facebookBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        if (AccessToken.current == nil) {
            facebookBtn.setTitle("Connect Facebook Account", for: .normal)
        } else {
            facebookBtn.setTitle("Disconnect Facebook Account", for: .normal)
        }
        fbView.addSubview(facebookBtn)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func btnPressed (sender: UIButton!) {
        if (sender == self.setDefaultSongs) {
            performSegue(withIdentifier: "defaultSongsSegue", sender: self)
        }
        if (sender == self.setDefaultPlaylists) {
            performSegue(withIdentifier: "defaultPlaylistsSegue", sender: self)
        }
        if (sender == self.viewRequests) {
            performSegue(withIdentifier: "viewGroupRequestsSegue", sender: self)
        }
    }
    
    // MARK: Actions
    func facebookBtnPressed(_ sender: Any) {
        if (AccessToken.current == nil) {
            Globals.logIntoFacebook(viewController: self, userId: self.state!.user.id)
            if (AccessToken.current != nil) {
                self.facebookBtn.setTitle("Disconnect Facebook Account", for: .normal)
            }
        } else {
            LoginManager().logOut()
            self.facebookBtn.setTitle("Connect Facebook Account", for: .normal)
        }
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "defaultSongsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongTableViewController
            destinationVC.prevController = "User"
            self.state?.group = Group(name: nil, admin: self.state!.user.id, id: -1, pic: nil, users: nil, inviteKey: nil)
            destinationVC.state = state
        }
        if (segue.identifier == "defaultPlaylistsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! UserPlaylistsTableViewController
            destinationVC.prevController = "User"
            self.state?.group = Group(name: nil, admin: self.state!.user.id, id: -1, pic: nil, users: nil, inviteKey: nil)
            destinationVC.state = state
        }
        if (segue.identifier == "viewGroupRequestsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupRequestTableViewController
            destinationVC.state = state
            destinationVC.groups = groupRequests
        }
        if (segue.identifier == "viewUserBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! EventTableViewController
            destinationVC.state = state
        }
    }
    
    // MARK: Helpers
}
