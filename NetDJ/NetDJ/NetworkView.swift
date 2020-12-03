//
//  NetworkView.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/15/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class NetworkView: UIView {

    //MARK: Properties
    var nameTextField: UITextField!
    var nameLabel: UILabel!
    var groupPicView: UIImageView!
    var refreshBtn: UIButton!
    var deleteLeaveBtn: UIButton!
    var inviteBtn: UIButton!
    var viewUsersBtn: UIButton!
    var searchBtn: UIButton!
    var totalSongsBtn: UIButton!
    weak var parent: ViewPlaylistViewController!
    
    init (frame : CGRect, parent: ViewPlaylistViewController) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 70))
        
        self.parent = parent
        self.backgroundColor = UIColor.white
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        scrollView.contentSize = self.bounds.size
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.emptySpaceTapped))
        scrollView.addGestureRecognizer(tapGesture)
        self.addSubview(scrollView)
        
        // Add picture subview
        groupPicView = UIImageView(frame: CGRect(x: 0, y: 20, width: 200, height: 200))
        groupPicView.center.x = self.frame.width/2
        scrollView.addSubview(groupPicView!)
        parent.state!.group?.assignPicToView(imageView: groupPicView!)
        
        let path = UIBezierPath(roundedRect: groupPicView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        groupPicView.layer.mask = mask
        
        groupPicView.contentMode = .scaleAspectFill
        
        let picGesture = UITapGestureRecognizer(target: self, action: #selector(self.triggerPicAlert))
        groupPicView.isUserInteractionEnabled = true
        groupPicView.addGestureRecognizer(picGesture)
        
        // Add name label subview
        let nameLabelView = UIView(frame: CGRect(x: 0, y: groupPicView!.frame.maxY + Globals.medOffset, width: self.frame.width, height: 50))
        nameLabelView.backgroundColor = UIColor.white
        let nameGesture = UITapGestureRecognizer(target: self, action: #selector(self.showEditAlert))
        nameLabelView.addGestureRecognizer(nameGesture)
        nameLabelView.layer.borderWidth = 1
        nameLabelView.layer.borderColor = Globals.getThemeColor2().cgColor
        scrollView.addSubview(nameLabelView)
        
        nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: nameLabelView.frame.width, height: nameLabelView.frame.height))
        nameLabel.textAlignment = .center
        
        nameTextField = UITextField(frame: CGRect(x: 0, y: 0, width: nameLabelView.frame.width, height: nameLabelView.frame.height))
        nameTextField.placeholder = "Set Network Name"
        nameTextField.textAlignment = .center
        nameTextField.delegate = parent
        
        if (parent.state?.group != nil) {
            if (parent.state!.group?.name == nil || parent.state!.group?.name == "") {
                nameLabel.isHidden = true
            } else {
                nameTextField.isHidden = true
                nameLabel.text = parent.state!.group?.name
            }
        }
        
        nameLabelView.addSubview(nameLabel)
        nameLabelView.addSubview(nameTextField)
        
        // Add search subview
        let searchView = UIView(frame: CGRect(x: 0, y: nameLabelView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        searchView.backgroundColor = UIColor.white
        scrollView.addSubview(searchView)
        
        let searchImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        searchImage.image = UIImage(named: "icons8-search-filled-50.png")
        
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
        
        searchBtn = UIButton(type: .system)
        searchBtn.frame = CGRect(x: 50, y: 0, width: searchView.frame.width, height: searchView.frame.height)
        searchBtn.setTitle("Search for Songs", for: .normal)
        searchBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        searchBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        searchBtn.contentHorizontalAlignment = .left
        searchView.addSubview(searchBtn)
        
        // Add total songs view
        let totalSongsView = UIView(frame: CGRect(x: 0, y: searchView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        totalSongsView.backgroundColor = UIColor.white
        scrollView.addSubview(totalSongsView)
        
        let totalSongsImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        totalSongsImage.image = UIImage(named: "everybody_icon.png")
        
        if let image = totalSongsImage.image {
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
                totalSongsImage.image = UIImage(cgImage: cgImage)
            }
        }
        totalSongsView.addSubview(totalSongsImage)
        
        totalSongsBtn = UIButton(type: .system)
        totalSongsBtn.frame = CGRect(x: 50, y: 0, width: totalSongsView.frame.width, height: totalSongsView.frame.height)
        totalSongsBtn.setTitle("Network Songs", for: .normal)
        totalSongsBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        totalSongsBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        totalSongsBtn.contentHorizontalAlignment = .left
        totalSongsView.addSubview(totalSongsBtn)
        
        // Add members subview
        let membersView = UIView(frame: CGRect(x: 0, y: totalSongsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        membersView.backgroundColor = UIColor.white
        scrollView.addSubview(membersView)
        
        let membersImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        membersImage.image = UIImage(named: "icons8-people-30.png")
        
        if let image = membersImage.image {
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
                membersImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        membersView.addSubview(membersImage)
        
        viewUsersBtn = UIButton(type: .system)
        viewUsersBtn.frame = CGRect(x: 50, y: 0, width: membersView.frame.width, height: membersView.frame.height)
        viewUsersBtn.setTitle("Members", for: .normal)
        viewUsersBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        viewUsersBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        viewUsersBtn.contentHorizontalAlignment = .left
        membersView.addSubview(viewUsersBtn)
        
        // Add invite key subview
        let inviteKeyView = UIView(frame: CGRect(x: 0, y: membersView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        inviteKeyView.backgroundColor = UIColor.white
        scrollView.addSubview(inviteKeyView)
        
        let inviteKeyImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        inviteKeyImage.image = UIImage(named: "icons8-paste-50.png")
        
        if let image = inviteKeyImage.image {
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
                inviteKeyImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        inviteKeyView.addSubview(inviteKeyImage)
        
        inviteBtn = UIButton(type: .system)
        inviteBtn.frame = CGRect(x: 50, y: 0, width: inviteKeyView.frame.width, height: inviteKeyView.frame.height)
        inviteBtn.setTitle("Copy Invite Code", for: .normal)
        inviteBtn.addTarget(self, action: #selector(copyInviteKey), for: .touchUpInside)
        inviteBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        inviteBtn.contentHorizontalAlignment = .left
        inviteKeyView.addSubview(inviteBtn)
        
        // Add delete/leave subview
        let deleteLeaveView = UIView(frame: CGRect(x: 0, y: inviteKeyView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        deleteLeaveView.backgroundColor = UIColor.white
        scrollView.addSubview(deleteLeaveView)
        
        let deleteLeaveImage = UIImageView(frame: CGRect(x: 10, y: 10, width: 30, height: 30))
        deleteLeaveImage.image = UIImage(named: "icons8-waste-32.png")
        
        if let image = deleteLeaveImage.image {
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
                deleteLeaveImage.image = UIImage(cgImage: cgImage)
            }
        }
        
        deleteLeaveView.addSubview(deleteLeaveImage)
        
        deleteLeaveBtn = UIButton(type: .system)
        deleteLeaveBtn.frame = CGRect(x: 50, y: 0, width: deleteLeaveView.frame.width, height: deleteLeaveView.frame.height)
        deleteLeaveBtn.addTarget(self, action: #selector(deleteLeaveAlarm), for: .touchUpInside)
        deleteLeaveBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        deleteLeaveBtn.contentHorizontalAlignment = .left
        deleteLeaveView.addSubview(deleteLeaveBtn)
        
        // If admin, then allow admin to delete
        // If not admin, then let user leave
        self.deleteLeaveBtn.setTitle("Leave Group", for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func btnPressed(sender: UIButton!) {
        if (sender == totalSongsBtn) {
            parent.performSegue(withIdentifier: "totalSongsSegue", sender: self)
        }
        if (sender == searchBtn) {
            parent.performSegue(withIdentifier: "searchSegue", sender: self)
        }

        if (sender == viewUsersBtn) {
            parent.performSegue(withIdentifier: "viewUsersSegue", sender: self)
        }
    }
    
    @objc func deleteLeaveAlarm() {
        var alert: UIAlertController?
        if let usersLoaded = parent.state?.group?.usersLoaded, usersLoaded &&  parent.state?.group?.users.count == 1 {
            alert = UIAlertController(title: "Delete Network", message: "Are you sure you want to delete?", preferredStyle: .alert)
        } else {
            alert = UIAlertController(title: "Leave Network", message: "Are you sure you want to leave?", preferredStyle: .alert)
        }
        
        alert?.addAction(UIAlertAction(title: "Confirm", style: .default, handler: deleteLeaveBtnPressed))
        alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        
        parent.present(alert!, animated: true)
    }
    
    @objc func triggerPicAlert() {
        let alert = UIAlertController(title: "Change Picture?", message: "Select a method", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: addPhotoFromLibrary))
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler: addPhotoFromCamera))
        alert.addAction(UIAlertAction(title: "Delete Picture", style: .default , handler: deleteGroupPhoto))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        
        parent.present(alert, animated: true)
    }
    
    //MARK: Actions
    func refreshBtnPressed(_ sender: Any) {
        let initialCount = self.parent.songs.count
        refreshBtn.isEnabled = false
        DispatchQueue.global().async { [unowned self] in
            var n = 10
            if self.parent.state?.group?.id == self.parent.state?.curActiveId {
                if let songs = self.parent.state!.group?.songs, songs.count > 0 {
                    self.parent.state!.group?.songs = [songs[0]]
                    n -= 1
                }
            } else {
                self.parent.state!.group?.songs = []
            }
            
            Globals.generateSongs(group: self.parent.state!.group, numSongs: n, lastSong: self.parent.state!.group?.songs?.first, state: self.parent.state!, viewPlaylistVC: nil)
            self.parent.songs = self.parent.state!.group?.songs ?? [Song]()
            if let id = self.parent.state!.group?.id {
                Globals.addPlaylistSongs(songs: self.parent.songs, groupId: id, userId: self.parent.state!.user.id)
            }
            
            
            DispatchQueue.main.async {
                if (self.parent.songs.count > 0) {
                    self.parent.songsTable.beginUpdates()
                    var deletePaths = [IndexPath]()
                    var insertPaths = [IndexPath]()
                    for i in (10 - n)..<initialCount {
                        deletePaths.append(IndexPath(row: i, section: 0))
                    }
                    for i in (10 - n)..<self.parent.songs.count {
                        insertPaths.append(IndexPath(row: i, section: 0))
                    }
                    self.parent.songsTable.deleteRows(at: deletePaths, with: .fade)
                    self.parent.songsTable.insertRows(at: insertPaths, with: .fade)
                    self.parent.songsTable.endUpdates()
                } else {
                    self.parent.updateIsPlaying(update: false)
                    self.parent.state!.currentActiveGroup = nil
                }
                self.refreshBtn.isEnabled = true
            }
        }
    }
    
    func deleteLeaveBtnPressed(alert: UIAlertAction!) {
        if parent.state!.group?.id == parent.state!.curActiveId {
            parent.updateIsPlaying(update: false)
        }
        parent.groupToDelete = parent.state!.group?.id
        if (deleteLeaveBtn.titleLabel?.text == "Leave Network") {
            if let id = parent.state!.group?.id {
                Globals.deleteGroupUser(userId: parent.state!.user.id, groupId: id)
                Globals.deleteUserFromGroup(userId: parent.state!.user.id, groupId: id)
            }
            parent.state!.group = nil
        }
        
        if (deleteLeaveBtn.titleLabel?.text == "Delete Network") {
            if let group = self.parent.state!.group {
                Globals.deleteGroup(group: group)
            }
            parent.state!.group = nil
        }
        
        parent.performSegue(withIdentifier: "unwindToNetworkTableFromPlaylist", sender: parent)
        
    }
    
    func addPhotoFromLibrary(alert: UIAlertAction!) {
        Globals.addPhotoFromLibrary(controller: parent)
    }
    
    func addPhotoFromCamera(alert: UIAlertAction!) {
        Globals.addPhotoFromCamera(controller: parent)
    }
    
    func deleteGroupPhoto(alert: UIAlertAction!) {
        parent.state!.group?.pic = UIImage(named: Globals.defaultPic)!
        self.groupPicView?.image = UIImage(named: Globals.defaultPic)
        
        let requestURL = URL(string: "http://autocollabservice.com/deletegrouppic")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "groupId=\(parent.state!.group?.id ?? -2)"
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
    }
    
    @objc func copyInviteKey(_ sender: Any) {
        UIPasteboard.general.string = parent.state!.group?.inviteKey
        Globals.showAlert(text: "Copied!", view: parent.view)
    }
    
    @objc func emptySpaceTapped() {
        saveName()
    }
    
    func saveName() {
        if (self.nameTextField.isHidden == false) {
            if (self.nameTextField.text != "") {
                self.nameLabel.text = self.nameTextField.text
                self.nameLabel.isHidden = false
                self.nameTextField.isHidden = true
                Globals.setGroupName(name: self.nameTextField.text!, groupId: parent.state!.group?.id ?? -2)
                parent.state!.group?.name = self.nameTextField.text!
                parent.title = self.nameTextField.text!
            } else {
                self.nameLabel.text = parent.state!.group?.name
                self.nameLabel.isHidden = false
                self.nameTextField.isHidden = true
            }
            self.endEditing(true)
            Globals.showAlert(text: "Saved!", view: parent.view)
            parent.state!.archiveGroups()
        }
    }
    
    // MARK: HELPERS
    @objc func showEditAlert() {
        let alert = UIAlertController(title: "Change network name?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: beginEdit))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        parent.present(alert, animated: true)
    }
    func beginEdit(alert: UIAlertAction!) {
        self.nameTextField.text = self.nameLabel.text
        self.nameLabel.isHidden = true
        self.nameTextField.isHidden = false
        self.nameTextField.becomeFirstResponder()
    }
}
