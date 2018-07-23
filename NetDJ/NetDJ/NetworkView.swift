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
    var groupPicView: UIImageView?
    var refreshBtn: UIButton!
    var deleteLeaveBtn: UIButton!
    var inviteBtn: UIButton!
    var viewUsersBtn: UIButton!
    var songsBtn: UIButton!
    var playlistsBtn: UIButton!
    var totalSongsBtn: UIButton!
    var parent: ViewPlaylistViewController!
    
    init (frame : CGRect, parent: ViewPlaylistViewController) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 70))
        
        self.parent = parent
        self.backgroundColor = Globals.getThemeColor2()
        
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        scrollView.contentSize = self.bounds.size
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.emptySpaceTapped))
        scrollView.addGestureRecognizer(tapGesture)
        self.addSubview(scrollView)
        
        // Add picture subview
        groupPicView = UIImageView(frame: CGRect(x: 0, y: 20, width: 200, height: 200))
        groupPicView?.center.x = self.frame.width/2
        scrollView.addSubview(groupPicView!)
        
        if (parent.state!.group?.pic != nil) {
            groupPicView?.image = parent.state!.group!.pic.pointee
        } else {
            groupPicView?.image = UIImage(named: Globals.defaultPic)
        }
        
        groupPicView?.contentMode = .scaleAspectFill
        
        let picGesture = UITapGestureRecognizer(target: self, action: #selector(self.triggerPicAlert))
        groupPicView?.isUserInteractionEnabled = true
        groupPicView?.addGestureRecognizer(picGesture)
        
        // Add name label subview
        let nameLabelView = UIView(frame: CGRect(x: 0, y: groupPicView!.frame.maxY + Globals.medOffset, width: self.frame.width, height: 50))
        nameLabelView.backgroundColor = UIColor.white
        let nameGesture = UITapGestureRecognizer(target: self, action: #selector(self.beginEdit))
        nameLabelView.addGestureRecognizer(nameGesture)
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
                nameLabel.text = parent.state!.group!.name
            }
        }
        
        nameLabelView.addSubview(nameLabel)
        nameLabelView.addSubview(nameTextField)
        
        // Add total songs view
        let totalSongsView = UIView(frame: CGRect(x: 0, y: nameLabelView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        totalSongsView.backgroundColor = UIColor.white
        scrollView.addSubview(totalSongsView)
        
        totalSongsBtn = UIButton(type: .system)
        totalSongsBtn.frame = CGRect(x: 0, y: 0, width: totalSongsView.frame.width, height: totalSongsView.frame.height)
        totalSongsBtn.setTitle("Total Network Songs", for: .normal)
        totalSongsBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        totalSongsBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        totalSongsView.addSubview(totalSongsBtn)
        
        // Add refresh Btn view
        let refreshView = UIView(frame: CGRect(x: 0, y: totalSongsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        refreshView.backgroundColor = UIColor.white
        scrollView.addSubview(refreshView)
        
        refreshBtn = UIButton(type: .system)
        refreshBtn.frame = CGRect(x: 0, y: 0, width: refreshView.frame.width, height: refreshView.frame.height)
        refreshBtn.setTitle("Refresh", for: .normal)
        refreshBtn.addTarget(self, action: #selector(refreshBtnPressed), for: .touchUpInside)
        refreshBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        refreshView.addSubview(refreshBtn)
        
        // Add my songs subview
        let mySongsView = UIView(frame: CGRect(x: 0, y: refreshView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        mySongsView.backgroundColor = UIColor.white
        scrollView.addSubview(mySongsView)
        
        songsBtn = UIButton(type: .system)
        songsBtn.frame = CGRect(x: 0, y: 0, width: mySongsView.frame.width, height: mySongsView.frame.height)
        songsBtn.setTitle("My Songs", for: .normal)
        songsBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        songsBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        mySongsView.addSubview(songsBtn)
        
        // Add my playlists subview
        let myPlaylistsView = UIView(frame: CGRect(x: 0, y: mySongsView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        myPlaylistsView.backgroundColor = UIColor.white
        scrollView.addSubview(myPlaylistsView)
        
        playlistsBtn = UIButton(type: .system)
        playlistsBtn.frame = CGRect(x: 0, y: 0, width: myPlaylistsView.frame.width, height: myPlaylistsView.frame.height)
        playlistsBtn.setTitle("My Spotify Playlists", for: .normal)
        playlistsBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        playlistsBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        myPlaylistsView.addSubview(playlistsBtn)
        
        // Add members subview
        let membersView = UIView(frame: CGRect(x: 0, y: myPlaylistsView.frame.maxY + Globals.bigOffset, width: self.frame.width, height: 50))
        membersView.backgroundColor = UIColor.white
        scrollView.addSubview(membersView)
        
        viewUsersBtn = UIButton(type: .system)
        viewUsersBtn.frame = CGRect(x: 0, y: 0, width: membersView.frame.width, height: membersView.frame.height)
        viewUsersBtn.setTitle("Members", for: .normal)
        viewUsersBtn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        viewUsersBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        membersView.addSubview(viewUsersBtn)
        
        // Add invite key subview
        let inviteKeyView = UIView(frame: CGRect(x: 0, y: membersView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        inviteKeyView.backgroundColor = UIColor.white
        scrollView.addSubview(inviteKeyView)
        
        inviteBtn = UIButton(type: .system)
        inviteBtn.frame = CGRect(x: 0, y: 0, width: inviteKeyView.frame.width, height: inviteKeyView.frame.height)
        inviteBtn.setTitle("Copy Invite Key", for: .normal)
        inviteBtn.addTarget(self, action: #selector(copyInviteKey), for: .touchUpInside)
        inviteBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        inviteKeyView.addSubview(inviteBtn)
        
        // Add delete/leave subview
        let deleteLeaveView = UIView(frame: CGRect(x: 0, y: inviteKeyView.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 50))
        deleteLeaveView.backgroundColor = UIColor.white
        scrollView.addSubview(deleteLeaveView)
        
        deleteLeaveBtn = UIButton(type: .system)
        deleteLeaveBtn.frame = CGRect(x: 0, y: 0, width: deleteLeaveView.frame.width, height: deleteLeaveView.frame.height)
        deleteLeaveBtn.addTarget(self, action: #selector(deleteLeaveAlarm), for: .touchUpInside)
        deleteLeaveBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        deleteLeaveView.addSubview(deleteLeaveBtn)
        
        // If admin, then allow admin to delete
        // If not admin, then let user leave
        if (parent.state?.group == nil) {
             self.deleteLeaveBtn.setTitle("", for: .normal)
        } else if (parent.state?.group?.admin == parent.state?.user.id) {
            self.deleteLeaveBtn.setTitle("Delete Network", for: .normal)
        } else {
            self.deleteLeaveBtn.setTitle("Leave Network", for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func btnPressed(sender: UIButton!) {
        if (sender == totalSongsBtn) {
            parent.performSegue(withIdentifier: "totalSongsSegue", sender: self)
        }
        if (sender == songsBtn) {
            parent.performSegue(withIdentifier: "mySongsSegue", sender: self)
        }
        if (sender == playlistsBtn) {
            parent.performSegue(withIdentifier: "myPlaylistsSegue", sender: self)
        }
        if (sender == viewUsersBtn) {
            parent.performSegue(withIdentifier: "viewUsersSegue", sender: self)
        }
    }
    
    func deleteLeaveAlarm() {
        var alert: UIAlertController?
        if (parent.state?.group!.admin == parent.state?.user.id) {
            alert = UIAlertController(title: "Delete Network", message: "Are you sure you want to delete?", preferredStyle: .alert)
        } else {
            alert = UIAlertController(title: "Leave Network", message: "Are you sure you want to leave?", preferredStyle: .alert)
        }
        
        alert?.addAction(UIAlertAction(title: "Confirm", style: .default, handler: deleteLeaveBtnPressed))
        alert?.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        
        parent.present(alert!, animated: true)
    }
    
    func triggerPicAlert() {
        let alert = UIAlertController(title: "Add Photo?", message: "How do you want to add a Network Photo?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Library", style: .default, handler: addPhotoFromLibrary))
        alert.addAction(UIAlertAction(title: "Camera", style: .default , handler: addPhotoFromCamera))
        alert.addAction(UIAlertAction(title: "Delete Picture", style: .default , handler: deleteGroupPhoto))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
        
        parent.present(alert, animated: true)
    }
    
    //MARK: Actions
    func refreshBtnPressed(_ sender: Any) {
        self.parent.songsTable.isHidden = true
        self.parent.activityIndicator?.startAnimating()
        DispatchQueue.global().async {
            self.parent.songs = Globals.generateSongs(groupId: self.parent.state!.group!.id, numSongs: 10, lastSong: nil, state: self.parent.state!)
            
            if (self.parent.songs.count > 0) {
                self.parent.playSong(player: self.parent.state!.player!, song: self.parent.songs[0])
                self.parent.state!.currentActiveGroup = self.parent.state!.group!.id
                self.parent.playPauseBtn?.setTitle("Pause", for: .normal)
            } else {
                self.parent.updateIsPlaying(update: false)
                self.parent.playPauseBtn?.setTitle("Play", for: .normal)
                self.parent.state!.currentActiveGroup = nil
            }
            Globals.addPlaylistSongs(songs: self.parent.songs, groupId: self.parent.state!.group!.id, userId: self.parent.state!.user.id)
            DispatchQueue.main.async {
                self.parent.songsTable.reloadData()
                self.parent.songsTable.isHidden = false
                self.parent.activityIndicator?.stopAnimating()
            }
        }
    }
    
    func deleteLeaveBtnPressed(alert: UIAlertAction!) {
        parent.updateIsPlaying(update: false)
        parent.state!.userNetworks.removeValue(forKey: parent.state!.group!.id)
        
        if (deleteLeaveBtn.titleLabel?.text == "Leave Network") {
            Globals.deleteGroupUser(userId: parent.state!.user.id, groupId: parent.state!.group!.id)
            Globals.deleteUserFromGroup(userId: parent.state!.user.id, groupId: parent.state!.group!.id)
            parent.state!.group = nil
            parent.performSegue(withIdentifier: "playlistBackSegue", sender: self)
        }
        
        if (deleteLeaveBtn.titleLabel?.text == "Delete Network") {
            Globals.deleteGroup(group: parent.state!.group!)
            parent.state!.group = nil
            parent.performSegue(withIdentifier: "playlistBackSegue", sender: self)
        }
        
    }
    
    func addPhotoFromLibrary(alert: UIAlertAction!) {
        // Get the current authorization state.
        let access = PHPhotoLibrary.authorizationStatus()
        
        switch access {
        case .authorized:
            break
        case .denied:
            return
        case .notDetermined:
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    
                }
                    
                else {
                    return
                }
            })
        case .restricted:
            return
        }
        
        // https://stackoverflow.com/questions/39812390/how-to-load-image-from-camera-or-photo-library-in-swift/39812909
        let photoLibrary = UIImagePickerController()
        let isPhotoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        let isSavedPhotoAlbumAvailable = UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        
        if !isPhotoLibraryAvailable && !isSavedPhotoAlbumAvailable { return }
        let type = kUTTypeImage as String
        
        if isPhotoLibraryAvailable {
            photoLibrary.sourceType = .photoLibrary
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                if availableTypes.contains(type) {
                    photoLibrary.mediaTypes = [type]
                    photoLibrary.allowsEditing = true
                }
            }
            
            photoLibrary.sourceType = .savedPhotosAlbum
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
                if availableTypes.contains(type) {
                    photoLibrary.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        
        photoLibrary.allowsEditing = true
        photoLibrary.delegate = parent
        parent.present(photoLibrary, animated: true, completion: nil)
    }
    
    func addPhotoFromCamera(alert: UIAlertAction!) {
        
        let access = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch access {
        case .authorized:
            break
        case .denied:
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == false
                {
                    return
                }
            });
        case .restricted:
            return
        }
        
        let camera = UIImagePickerController()
        let isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let isRearCameraAvailable = UIImagePickerController.isCameraDeviceAvailable(.rear)
        let isFrontCameraAvailable = UIImagePickerController.isCameraDeviceAvailable(.front)
        let sourceTypeCamera = UIImagePickerControllerSourceType.camera
        let rearCamera = UIImagePickerControllerCameraDevice.rear
        let frontCamera = UIImagePickerControllerCameraDevice.front
        
        if !isCameraAvailable { return }
        let type1 = kUTTypeImage as String
        
        if isCameraAvailable {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if availableTypes.contains(type1) {
                    camera.mediaTypes = [type1]
                    camera.sourceType = sourceTypeCamera
                }
            }
            
            if isRearCameraAvailable {
                camera.cameraDevice = rearCamera
            } else if isFrontCameraAvailable {
                camera.cameraDevice = frontCamera
            }
        } else {
            return
        }
        
        camera.allowsEditing = true
        camera.showsCameraControls = true
        camera.delegate = parent
        parent.present(camera, animated: true, completion: nil)
    }
    
    func deleteGroupPhoto(alert: UIAlertAction!) {
        parent.state!.group?.pic.pointee = UIImage(named: Globals.defaultPic)!
        self.groupPicView?.image = UIImage(named: Globals.defaultPic)
        
        let requestURL = URL(string: "http://autocollabservice.com/deletegrouppic")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "groupId=\(parent.state!.group!.id)"
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 0)
    }
    
    func copyInviteKey(_ sender: Any) {
        UIPasteboard.general.string = parent.state!.group!.inviteKey!
        parent.showAlert(text: "Copied!")
    }
    
    func emptySpaceTapped() {
        if (self.nameTextField.isHidden == false) {
            if (self.nameTextField.text != "") {
                self.nameLabel.text = self.nameTextField.text
                self.nameLabel.isHidden = false
                self.nameTextField.isHidden = true
            }
            self.endEditing(true)
            self.setGroupName(name: self.nameTextField.text!)
            parent.state!.group!.name = self.nameTextField.text!
            if (self.nameTextField.text! == "") {
                parent.groupName.text = Globals.getUsersName(id: parent.state!.group!.admin, state: parent.state!) + "'s Network"
            } else {
                parent.groupName.text = self.nameTextField.text!
            }
        }
    }
    
    // MARK: HELPERS
    
    func beginEdit() {
        if (parent.state!.group!.admin == parent.state!.user.id) {
            self.nameTextField.text = self.nameLabel.text
            self.nameLabel.isHidden = true
            self.nameTextField.isHidden = false
            self.nameTextField.becomeFirstResponder()
        }
    }
    
    func setGroupName(name: String) {
        var setName = ""
        if (name == "") {
            setName = "///NULL///"
        } else {
            setName = name
        }
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/addgroupname")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(parent.state!.group!.id)" + "&name=" + setName
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in}, isAsync: 1)
    }
}
