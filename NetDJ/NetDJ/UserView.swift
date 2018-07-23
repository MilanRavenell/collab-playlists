//
//  UserView.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/15/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class UserView: UIView {
    
    var setDefaultSongs: UIButton!
    var setDefaultPlaylists: UIButton!
    var viewRequests: UIButton!
    var facebookBtn: UIButton!
    var groupSearch: UIButton!
    var parent: NetworkTableViewController!

    init (frame : CGRect, parent: NetworkTableViewController) {
        super.init(frame: frame)
        self.parent = parent
        
        self.backgroundColor = Globals.getThemeColor2()

        // Create Subviews
        let nameView = UIView(frame: CGRect(x: 0, y: 80, width: self.frame.width, height: 50))
        nameView.backgroundColor = UIColor.white
        
        let defaultSongsView = UIView(frame: CGRect(x: 0, y: nameView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        defaultSongsView.backgroundColor = UIColor.white
        
        let defaultPlaylistsView = UIView(frame: CGRect(x: 0, y: defaultSongsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        defaultPlaylistsView.backgroundColor = UIColor.white
        
        let requestsView = UIView(frame: CGRect(x: 0, y: defaultPlaylistsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        requestsView.backgroundColor = UIColor.white
        
        let searchView = UIView(frame: CGRect(x: 0, y: requestsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        searchView.backgroundColor = UIColor.white
        
        let fbView = UIView(frame: CGRect(x: 0, y: searchView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        fbView.backgroundColor = UIColor.white
        
        
        
        self.addSubview(nameView)
        self.addSubview(defaultSongsView)
        self.addSubview(defaultPlaylistsView)
        self.addSubview(requestsView)
        self.addSubview(searchView)
        self.addSubview(fbView)
        
        // Create Name Label
        let name = UILabel(frame: CGRect(x: 0, y: 0, width: nameView.frame.width, height: nameView.frame.height))
        name.text = Globals.getUsersName(id: parent.state!.user.id, state: parent.state!)
        name.textAlignment = .center
        nameView.addSubview(name)
        
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
        viewRequests.setTitle("View Network Requests(" + String(parent.state!.groupRequests.count) + ")", for: .normal)
        requestsView.addSubview(viewRequests)
        
        groupSearch = UIButton(type: .system)
        groupSearch.frame = CGRect(x: 0, y: 0, width: requestsView.frame.width, height: requestsView.frame.height)
        groupSearch.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        groupSearch.setTitleColor(Globals.getThemeColor1(), for: .normal)
        groupSearch.setTitle("Submit Invite Key", for: .normal)
        searchView.addSubview(groupSearch)
        
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func btnPressed (sender: UIButton!) {
        if (sender == self.setDefaultSongs) {
            parent.performSegue(withIdentifier: "defaultSongsSegue", sender: self)
        }
        if (sender == self.setDefaultPlaylists) {
            parent.performSegue(withIdentifier: "defaultPlaylistsSegue", sender: self)
        }
        if (sender == self.viewRequests) {
            parent.performSegue(withIdentifier: "viewGroupRequestsSegue", sender: self)
        }
        if (sender == self.groupSearch) {
            let alert = UIAlertController(title: "Submit Network Invite Key", message: "Use an invite key to join a Network!", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "Invite Key"
            }

            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                
                let success = self.getGroupByInviteKey(inviteKey: textField!.text!)
                if (success == 1) {
                    Globals.addGroupUsers(groupId: self.parent.state!.group!.id, userIds: [self.parent.state!.user.id])
                    self.parent.state!.group?.users?.append(self.parent.state!.user.id)
                    self.parent.state!.userNetworks[self.parent.state!.group!.id] = self.parent.state!.group
                    Globals.updateNetworkAsync(groupId: self.parent.state!.group!.id, add_delete: 0, user: self.parent.state!.user.id, songs: self.parent.state!.user.topSongs)
                    self.parent.performSegue(withIdentifier: "viewPlaylistSegue", sender: self.parent)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
            parent.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Actions
    func facebookBtnPressed(_ sender: Any) {
        parent.facebookLogin()
    }
    
    func getGroupByInviteKey(inviteKey: String) -> Int{
        
        var success: Int?
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "method=invite&inviteKey=" + inviteKey
        
        var groups: [[String: AnyObject]]?
        let response = Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            groups = response as? [[String: AnyObject]]
        }, isAsync: 0) as! [[String: AnyObject]]
        
        if (groups == nil || groups!.count == 0 ){
            success = 0
        } else {
            let group = groups!.first!
            let name = group["name"] as? String
            let admin = group["admin"] as! String
            let id = group["id"] as! Int
            let inviteKey = group["invite_key"] as! String
            parent.state!.group = Group(name: name, admin: admin, id: id, picURL: nil, users:[], inviteKey: inviteKey)
            success = 1
        }
        
        parent.state!.group?.users = Globals.getGroupUsers(id: parent.state!.group!.id)
        return success!
    }
}
