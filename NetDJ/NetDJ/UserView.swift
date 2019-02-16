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
    var viewRequests: UIButton!
    var facebookBtn: UIButton!
    var groupSearch: UIButton!
    var logOut: UIButton!
    var userPicView: UIImageView!
    var name: UILabel!
    var nameTextField: UITextField!
    weak var parent: NetworkTableViewController!
    
    init (frame : CGRect, parent: NetworkTableViewController) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 70))
        
        self.parent = parent
        
        self.backgroundColor = UIColor.white
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        scrollView.contentSize = self.bounds.size
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.saveName))
        scrollView.addGestureRecognizer(tapGesture)
        self.addSubview(scrollView)
        
        userPicView = UIImageView(frame: CGRect(x: 0, y: 20, width: 200, height: 200))
        userPicView.center.x = self.frame.width/2
        
        let path = UIBezierPath(roundedRect: userPicView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        userPicView.layer.mask = mask
        
        parent.state!.user.assignPicToView(imageView: userPicView, animated: false)
        
        userPicView.contentMode = .scaleAspectFill
        
        let picGesture = UITapGestureRecognizer(target: self, action: #selector(self.triggerPicAlert))
        userPicView?.isUserInteractionEnabled = true
        userPicView?.addGestureRecognizer(picGesture)

        // Create Subviews
        let nameView = UIView(frame: CGRect(x: 0, y: userPicView.frame.maxY + Globals.medOffset, width: self.frame.width, height: 50))
        let nameGesture = UITapGestureRecognizer(target: self, action: #selector(self.showEditAlert))
        nameView.addGestureRecognizer(nameGesture)
        nameView.backgroundColor = UIColor.white
        nameView.layer.borderWidth = 1
        nameView.layer.borderColor = Globals.getThemeColor2().cgColor
        
        let defaultSongsView = UIView(frame: CGRect(x: 0, y: nameView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        defaultSongsView.backgroundColor = UIColor.white
        
        let requestsView = UIView(frame: CGRect(x: 0, y: defaultSongsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        requestsView.backgroundColor = UIColor.white
        
        let searchView = UIView(frame: CGRect(x: 0, y: requestsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        searchView.backgroundColor = UIColor.white
        
        let fbView = UIView(frame: CGRect(x: 0, y: searchView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        fbView.backgroundColor = UIColor.white
        
        var logOutView: UIView!
        if Globals.useFB {
            logOutView = UIView(frame: CGRect(x: 0, y: fbView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        } else {
            logOutView = UIView(frame: CGRect(x: 0, y: searchView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        }
        logOutView.backgroundColor = UIColor.white
        
        let iconLinkLabel = UIButton(type: .system)
        iconLinkLabel.frame = CGRect(x: 0, y: logOutView.frame.maxY + Globals.bigOffset + Globals.bigOffset, width: self.frame.width, height: 70)
        iconLinkLabel.setTitleColor(UIColor.gray, for: .normal)
        iconLinkLabel.setTitle("All custom icons from Icons8", for: .normal)
        iconLinkLabel.addTarget(self, action: #selector(iconLink), for: .touchUpInside)
        
        
        scrollView.addSubview(userPicView!)
        scrollView.addSubview(nameView)
        scrollView.addSubview(defaultSongsView)
        scrollView.addSubview(requestsView)
        scrollView.addSubview(searchView)
        if Globals.useFB { scrollView.addSubview(fbView) }
        scrollView.addSubview(logOutView)
        scrollView.addSubview(iconLinkLabel)
        
        // Create images
        let defaultSongsImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        defaultSongsImage.image = UIImage(named: "user_icon.png")
        
        // color the icons green
        if let image = defaultSongsImage.image {
            let maskImage = image.cgImage!
            
            let width = image.size.width
            let height = image.size.height
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
            
            context.clip(to: bounds, mask: maskImage)
            context.setFillColor(Globals.getThemeColor1().cgColor)
            context.fill(bounds)
            
            if let cgImage = context.makeImage() {
                defaultSongsImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        defaultSongsView.addSubview(defaultSongsImage)
        
        let requestsImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        requestsImage.image = UIImage(named: "user_icon.png")
        
        if let image = requestsImage.image {
            let maskImage = image.cgImage!
            
            let width = image.size.width
            let height = image.size.height
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
            
            context.clip(to: bounds, mask: maskImage)
            context.setFillColor(Globals.getThemeColor1().cgColor)
            context.fill(bounds)
            
            if let cgImage = context.makeImage() {
                requestsImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        requestsView.addSubview(requestsImage)
        
        
        let searchImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        searchImage.image = UIImage(named: "user_icon.png")
        
        if let image = searchImage.image {
            let maskImage = image.cgImage!
            
            let width = image.size.width
            let height = image.size.height
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
            
            context.clip(to: bounds, mask: maskImage)
            context.setFillColor(Globals.getThemeColor1().cgColor)
            context.fill(bounds)
            
            if let cgImage = context.makeImage() {
                searchImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        searchView.addSubview(searchImage)
        
        let logOutImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        logOutImage.image = UIImage(named: "user_icon.png")
        
        if let image = logOutImage.image {
            let maskImage = image.cgImage!
            
            let width = image.size.width
            let height = image.size.height
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
            
            context.clip(to: bounds, mask: maskImage)
            context.setFillColor(Globals.getThemeColor1().cgColor)
            context.fill(bounds)
            
            if let cgImage = context.makeImage() {
                logOutImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        logOutView.addSubview(logOutImage)
        
        // Create Name Label
        name = UILabel(frame: CGRect(x: 0, y: 0, width: nameView.frame.width, height: nameView.frame.height))
        name.text = Globals.getUsersName(id: parent.state!.user.id, state: parent.state!)
        name.textAlignment = .center
        nameView.addSubview(name)
        
        nameTextField = UITextField(frame: CGRect(x: 0, y: 0, width: nameView.frame.width, height: nameView.frame.height))
        nameTextField.placeholder = "Set Display Name"
        nameTextField.textAlignment = .center
        nameTextField.delegate = parent
        
        nameTextField.isHidden = true
        name.text = parent.state!.user.name
        
        nameView.addSubview(nameTextField)
        
        // Create Buttons
        setDefaultSongs = UIButton(type: .system)
        setDefaultSongs.frame = CGRect(x: 50, y: 0, width: defaultSongsView.frame.width, height: defaultSongsView.frame.height)
        setDefaultSongs.setTitle("Default Songs", for: .normal)
        setDefaultSongs.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        setDefaultSongs.setTitleColor(Globals.getThemeColor1(), for: .normal)
        setDefaultSongs.contentHorizontalAlignment = .left
        defaultSongsView.addSubview(setDefaultSongs)
        
        viewRequests = UIButton(type: .system)
        viewRequests.frame = CGRect(x: 50, y: 0, width: requestsView.frame.width, height: requestsView.frame.height)
        viewRequests.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        viewRequests.setTitleColor(Globals.getThemeColor1(), for: .normal)
        viewRequests.setTitle("View Network Requests", for: .normal)
        viewRequests.contentHorizontalAlignment = .left
        requestsView.addSubview(viewRequests)
        
        groupSearch = UIButton(type: .system)
        groupSearch.frame = CGRect(x: 50, y: 0, width: requestsView.frame.width, height: requestsView.frame.height)
        groupSearch.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        groupSearch.setTitleColor(Globals.getThemeColor1(), for: .normal)
        groupSearch.setTitle("Submit an Invite Code", for: .normal)
        groupSearch.contentHorizontalAlignment = .left
        searchView.addSubview(groupSearch)
        
        if Globals.useFB {
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
        
        logOut = UIButton(type: .system)
        logOut.frame = CGRect(x: 50, y: 0, width: requestsView.frame.width, height: requestsView.frame.height)
        logOut.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        logOut.setTitleColor(Globals.getThemeColor1(), for: .normal)
        logOut.setTitle("Log Out", for: .normal)
        logOut.contentHorizontalAlignment = .left
        logOutView.addSubview(logOut)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func btnPressed (sender: UIButton!) {
        if (sender == self.setDefaultSongs) {
            parent.performSegue(withIdentifier: "defaultSongsSegue", sender: self)
        }
        if (sender == self.viewRequests) {
            parent.performSegue(withIdentifier: "viewGroupRequestsSegue", sender: self)
        }
        if (sender == self.groupSearch) {
            let alert = UIAlertController(title: "Submit Network Invite Key", message: "Use an invite key to join a Network!", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "Invite Key"
            }

            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert, unowned self] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                
                if let group = self.getGroupByInviteKey(inviteKey: textField!.text!) {
                    self.parent.state!.userNetworks[group.id] = group
                    self.parent.state!.group = group
                    DispatchQueue.global().async {
                        group.isJoining = true
                        Globals.addGroupUsers(groupId: group.id, userIds: [self.parent.state!.user.id])
                        Globals.addUserDefaults(user: self.parent.state!.user, group: group, state: self.parent.state!)
                        Globals.updateNetwork(group: group, state: self.parent.state!)
                        group.songs = [Song]()
                        Globals.generateSongs(group: group, numSongs: 10, lastSong: nil, state: self.parent.state!, viewPlaylistVC: nil)
                        Globals.addPlaylistSongs(songs: group.songs!, groupId: group.id, userId: self.parent.state!.user.id)
                        group.isJoining = false
                        self.parent.state?.viewPlaylistVC?.networkSetup()
                        self.parent.state?.archiveGroups()
                        
                    }
                    self.parent.performSegue(withIdentifier: "viewPlaylistSegue", sender: self.parent)
                } else {
                    Globals.showAlert(text: "Invalid invite code", view: self.parent.view)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
            parent.present(alert, animated: true, completion: nil)
        }
        
        if sender == self.logOut {
            logOutBtnPressed()
        }
    }
    
    // MARK: Actions
    func facebookBtnPressed(_ sender: Any) {
        if AccessToken.current != nil {
            let alert = UIAlertController(title: "Disconnect", message: "Do you want to disconnect?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: parent.facebookBtnLogin))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
            
            parent.present(alert, animated: true)
        } else {
            parent.facebookBtnLogin(alert: nil)
        }
    }
    
    func logOutBtnPressed() {
        let alert = UIAlertController(title: "Log Out?", message: "Do you want to log out of your Spotify account?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak self] (_) in
            self?.parent.triggerDismiss()
            Globals.deleteStorage()
            self?.parent.state = nil
            if AccessToken.current != nil {
                LoginManager().logOut()
            }
            let userDefaults = UserDefaults.standard
            userDefaults.set(nil, forKey: "SpotifySession")
            userDefaults.synchronize()
            self?.parent.playlistVC?.updateIsPlaying(update: false)
            self?.parent.performSegue(withIdentifier: "loginSegue", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        parent.present(alert, animated: true)
    }
    
    func triggerPicAlert() {
        let alert = UIAlertController(title: "Change profile picture?", message: "Select a method", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: addPhotoFromLibrary))
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler: addPhotoFromCamera))
        alert.addAction(UIAlertAction(title: "Delete Picture", style: .default , handler: deleteGroupPhoto))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        
        parent.present(alert, animated: true)
    }
    
    func addPhotoFromLibrary(alert: UIAlertAction!) {
        Globals.addPhotoFromLibrary(controller: parent)
    }
    
    func addPhotoFromCamera(alert: UIAlertAction!) {
        Globals.addPhotoFromCamera(controller: parent)
    }
    
    func deleteGroupPhoto(alert: UIAlertAction!) {
        parent.state!.user.getProfPic()
        self.userPicView!.image = UIImage(named: Globals.defaultPic)
        parent.state!.user.assignPicToView(imageView: self.userPicView!, animated: false)
        
        let requestURL = URL(string: "http://autocollabservice.com/removemapping")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "spotifyId=" + parent.state!.user.id + "&mapping=pic"
    
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 0)
    }
    
    func getGroupByInviteKey(inviteKey: String) -> Group? {
        
        var group: Group?
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "method=invite&inviteKey=" + inviteKey
        
        var groups: [[String: AnyObject]]?
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            groups = response as? [[String: AnyObject]]
        }, isAsync: 0)
        
        if (groups == nil || groups!.count == 0 ){
            return group
        } else {
            let responseGroup = groups!.first!
            let name = responseGroup["name"] as? String
            let admin = responseGroup["admin"] as! String
            let id = responseGroup["id"] as! Int
            let inviteKey = responseGroup["invite_key"] as! String
            group = Group(name: name, admin: admin, id: id, picURL: nil, inviteKey: inviteKey, state: parent.state!)
        }
        
        return group
    }
    
    func showEditAlert() {
        let alert = UIAlertController(title: parent.state!.user.name, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Change Name", style: .default, handler: beginEdit))
        alert.addAction(UIAlertAction(title: "Update Phone Number", style: .default, handler: changePhoneNumber))
        alert.addAction(UIAlertAction(title: "Copy Spotify Id", style: .default, handler: copySpotifyId))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        parent.present(alert, animated: true)
    }
    
    func copySpotifyId(alert: UIAlertAction!) {
        UIPasteboard.general.string = parent.state!.user.id
        Globals.showAlert(text: "Copied!", view: parent.view)
    }
    
    func beginEdit(alert: UIAlertAction!) {
        self.nameTextField.text = self.name.text
        self.name.isHidden = true
        self.nameTextField.isHidden = false
        self.nameTextField.becomeFirstResponder()
    }
    
    func changePhoneNumber(alert: UIAlertAction!) {
//        let alert = UIAlertController(title: "Update Phone Number", message: "", preferredStyle: .alert)
//        alert.addTextField { (textField) in
//            textField.placeholder = "Only digits (ex. XXXXXXXXXX)"
//        }
//        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert, weak self] (_) in
//            let textField = alert?.textFields![0]
//            if let state = self?.parent.state {
//                Globals.addPhoneNumber(id: state.user.id, number: textField!.text!)
//            }
//        }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
//        parent.present(alert, animated: true)
        parent.presentUserView(present: false)
        parent.presentUpdatePhoneNumberAlert()
    }
    
    func saveName() {
        if (self.nameTextField.isHidden == false) {
            if (self.nameTextField.text != "") {
                self.name.text = self.nameTextField.text
                self.name.isHidden = false
                self.nameTextField.isHidden = true
                parent.state!.user.name = self.nameTextField.text!
                Globals.setDisplayName(id: parent.state!.user.id, name: self.nameTextField.text!)
            } else {
                self.name.text = parent.state!.user.name
                self.name.isHidden = false
                self.nameTextField.isHidden = true
            }
            self.endEditing(true)
            Globals.showAlert(text: "Saved!", view: parent.view)
        }
    }
    
    func iconLink() {
        if let url = URL(string:"https://icons8.com/") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
