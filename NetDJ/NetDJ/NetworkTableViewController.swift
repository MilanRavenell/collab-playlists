//
//  NetworkTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/15/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
//import FacebookCore
//import FacebookLogin
//import FBSDKLoginKit
import AVFoundation
import MediaPlayer
import MessageUI

class NetworkTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate {

    //MARK: - Properties
    @IBOutlet weak var networkTable: UITableView!
    var groups = [Group]()
    var state: State?
    var selectedGroup: Group?
    var userView: UserView!
    var dimView: UIView!
    var dismiss: UITapGestureRecognizer!
    var userShown = false
    @IBOutlet weak var addBtn: UIBarButtonItem!
    //var accessToken = AccessToken.current
    var prevVC: UIViewController?
    var playlistVC: ViewPlaylistViewController?
    var userPlaylistVC: UserPlaylistsTableViewController?
    var viewPlaylistVC: ViewPlaylistViewController?
    var prevController: String?
    var newGroupName: String?
    var requestsToSend: [String]?
    var doFBAlert = false
    var doFirstTimeAlert = false
    var emptyLabel: UILabel!
    var actionToEnable: UIAlertAction!
    var firstTimeAlertNameVC: FirstTimeAlertName!
    var firstTimeAlertPhoneVC: FirstTimeAlertPhone!
    var firstTimeAlertConfirmationVC: FirstTimeAlertConfirmation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        performSegue(withIdentifier: "loginSegue", sender: self)
        
        self.title = "Your Networks"
        
        emptyLabel = UILabel(frame: self.view.frame)
        emptyLabel.text = "You are not a part of any networks"
        emptyLabel.isHidden = true
        self.view.addSubview(emptyLabel)
        
        if (networkTable) != nil {
            networkTable.dataSource = self
            networkTable.delegate = self
            networkTable.rowHeight = 90
            networkTable.frame = self.view.frame
            networkTable.tableFooterView = UIView()
        }
        
        //navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = Globals.getThemeColor1()
        //navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        dimView = UIView(frame: self.view.frame)
        dimView.isHidden = true
        dismiss = UITapGestureRecognizer(target: self, action: #selector(self.triggerDismiss))
        dimView.addGestureRecognizer(dismiss)
        self.view.addSubview(dimView)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didRightSwipe))
        rightSwipeGesture.direction = .right
        self.networkTable.addGestureRecognizer(rightSwipeGesture)
        
        let viewRightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didRightSwipe))
        viewRightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(viewRightSwipeGesture)
        
        let dimLeftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
        dimLeftSwipeGesture.direction = .left
        self.dimView.addGestureRecognizer(dimLeftSwipeGesture)
        
        // Handle Remote Events
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.pauseCommand.addTarget { [unowned self] (event) -> MPRemoteCommandHandlerStatus in
            if self.state!.curActiveId != nil {
                self.playlistVC?.playPauseBtnPressed(self)
            }
            return .success
        }
        
        commandCenter.playCommand.addTarget { [unowned self] (event) -> MPRemoteCommandHandlerStatus in
            if self.state!.curActiveId != nil {
                self.playlistVC?.playPauseBtnPressed(self)
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [unowned self] (event) -> MPRemoteCommandHandlerStatus in
            if self.state!.curActiveId != nil {
                self.playlistVC?.nextBtnPressed(self)
            }
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] (event) -> MPRemoteCommandHandlerStatus in
            if self.state!.curActiveId != nil {
                self.playlistVC?.playPauseBtnPressed(self)
            }
            return .success
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reloadNetworkTable()
        self.state?.archiveGroups()
        self.state?.user.songsHasLoaded = false
        
        if doFBAlert {
            // User is logged in, use 'accessToken' here.
            let alert = UIAlertController(title: "You are not logged into a Facebook Account", message: "We recommend that you log into your Facebook account to make it easier to add your friends", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: facebookLogin))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
            doFBAlert = false
        }
        
        if let userPlaylistVC = userPlaylistVC {
            let playlists = userPlaylistVC.playlists
            let starting = userPlaylistVC.startingPlaylists
            DispatchQueue.global().async { [weak self] in
                if let state = self?.state {
                    Globals.updatePlaylist(group: state.group, playlists: playlists, startingPlaylists: starting, state: state)
                }
            }
            
            self.userPlaylistVC = nil
            state?.userPlaylistVC = nil
        }
        
        if let viewPlaylistVC = viewPlaylistVC {
            if let srcGroup = viewPlaylistVC.state?.group {
                if srcGroup.id == self.state!.curActiveId {
                    self.state!.currentActiveGroup = srcGroup.copy() as? Group
                }
                srcGroup.unload()
                self.state?.userNetworks[srcGroup.id] = srcGroup
            }
            self.state = viewPlaylistVC.state
            self.state?.group = nil
            self.state?.user.songsHasLoaded = false
            
            if let delete = viewPlaylistVC.groupToDelete {
                self.state!.userNetworks[delete] = nil
            }
            
            
            self.groups = Array(self.state!.userNetworks.values)
            reloadNetworkTable()
            
            self.viewPlaylistVC = nil
        }
        
        if self.state != nil {
            if doFirstTimeAlert {
                presentFirstTimeAlert()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkTableViewCell", for: indexPath) as? NetworkTableViewCell else {
            fatalError("It messed up")
        }
        cell.backgroundColor = UIColor.clear
        
        if indexPath.row < self.groups.count {
            let group = self.groups[indexPath.row]
            
            // Configure the cell...
            cell.name.text = group.name
            cell.admin.text = "Now Playing: "
            if group.songs != nil && group.songs!.count > 0 {
                cell.admin.text = cell.admin.text! + group.songs![0].name
            }
            
            cell.name.font = cell.name.font.withSize(20)
            cell.admin.font = cell.admin.font.withSize(13)
            cell.admin.textColor = UIColor(displayP3Red: 100, green: 100, blue: 100, alpha: 1)
            
            let networkPicView = UIImageView(frame: CGRect(x: 10, y: 10, width: 80, height: cell.frame.height - 20))
            cell.addSubview(networkPicView)
            group.assignPicToView(imageView: networkPicView)
            
            networkPicView.contentMode = .scaleAspectFill
            
            let path = UIBezierPath(roundedRect: networkPicView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            networkPicView.layer.mask = mask
            
            if group.id == self.state?.currentActiveGroup?.id {
                cell.name.textColor = Globals.getThemeColor1()
                cell.admin.textColor = Globals.getThemeColor1()
            } else {
                cell.name.textColor = UIColor.black
                cell.admin.textColor = UIColor.black
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (groups.count > indexPath.row) {
            state!.group = groups[indexPath.row]
        }
        
        
        //parsing the response
        self.performSegue(withIdentifier: "viewPlaylistSegue", sender: self)
        self.networkTable.deselectRow(at: indexPath, animated: false)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.editedImage.rawValue] as! UIImage
        
        self.state!.user.pic = image
        self.userView.userPicView?.image = image
        
        picker.dismiss(animated: true, completion: nil)
        
        let url = URL(string: "http://autocollabservice.com/addimage");
        let request = NSMutableURLRequest(url: url!);
        request.httpMethod = "POST"
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = image.jpegData(compressionQuality: 1)
        if (imageData == nil) {
            print("UIImageJPEGRepresentation return nil")
            return
        }
        
        let body = NSMutableData()
        body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format:"Content-Disposition: form-data; name=\"file\"; filename=\"userPic" + self.state!.user.id + ".jpg\"\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format: "Content-Type: application/octet-stream\r\n\r\n").data(using: String.Encoding.utf8.rawValue)!)
        body.append(imageData!)
        body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
        
        request.httpBody = body as Data
        
        Globals.sendRequest(request: request, postParameters: nil, method: "POST", completion: {_ in}, isAsync: 1)
        
        // Add photo url to group in database
        addPhotoToUser(userId: self.state!.user.id, url: "http://autocollabservice.com/images/userPic" + self.state!.user.id + ".jpg")
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    }
    
    @objc func triggerDismiss() {
        presentUserView(present: false)
        userView.saveName()
    }
    
    @objc  func didRightSwipe() {
        presentUserView(present: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        userView.saveName()
        return true
    }
    
    //MARK: - Actions
    
    @IBAction func addGroupPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "findFriendsSegue", sender: self)
    }
    
    
    @IBAction func userBtnPressed(_ sender: Any) {
        presentUserView(present: !self.userShown)
    }
    
    @IBAction func unwindToNetworkTable(sender: UIStoryboardSegue) {
        self.state!.isAtHomeScreen = true
        if let sourceViewController = sender.source as? FriendSearchViewController {
            if let segue = sender as? UIStoryboardSegueWithCompletion {
                segue.completion = { [unowned self] in
                    self.prevController = "FriendSearchWithNewGroup"
                    self.newGroupName = sourceViewController.groupName
                    self.requestsToSend = sourceViewController.spotifyIds
                    self.state!.group = nil
                    self.performSegue(withIdentifier: "viewPlaylistSegue", sender: self)
                }
            }
        }
        
        if let sourceViewController = sender.source as? ViewPlaylistViewController {
            self.state!.viewPlaylistVC = nil
            
            if let srcGroup = sourceViewController.state?.group {
                if srcGroup.id == self.state!.curActiveId {
                    self.state!.currentActiveGroup = srcGroup.copy() as? Group
                }
                srcGroup.unload()
                self.state?.userNetworks[srcGroup.id] = srcGroup
            }
            self.state = sourceViewController.state
            self.state?.group = nil
            self.state?.user.songsHasLoaded = false
            
            if let delete = sourceViewController.groupToDelete {
                self.state!.userNetworks[delete] = nil
            }
            
            
            self.groups = Array(self.state!.userNetworks.values)
            reloadNetworkTable()
        }
        
        if let _ = sender.source as? ViewController {
            self.groups = Array(self.state!.userNetworks.values)
            reloadNetworkTable()
            
            userView = UserView(frame: CGRect(x: 0 - 2 * self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height), parent: self)
            self.view.addSubview(userView)
            
            let userLeftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
            userLeftSwipeGesture.direction = .left
            self.userView.addGestureRecognizer(userLeftSwipeGesture)
            
            let path = UIBezierPath(roundedRect: userView.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 50, height: 50))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            userView.layer.mask = mask
            
            if Globals.useFB {
                let userDefaults = UserDefaults.standard
                if userDefaults.object(forKey: "DidRequestFacebookLogin") == nil {
                    if (/*AccessToken.current == nil*/true) {
                        self.doFBAlert = true
                        
                        let requestedFbData = NSKeyedArchiver.archivedData(withRootObject: true)
                        userDefaults.set(requestedFbData, forKey: "DidRequestFacebookLogin")
                        userDefaults.synchronize()
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        self.state?.isAtHomeScreen = false
        
        
        if (segue.identifier == "viewPlaylistSegue") {
            let destinationVC = segue.destination as! ViewPlaylistViewController
            destinationVC.state = state
            destinationVC.prevController = self.prevController
            destinationVC.newGroupName = self.newGroupName
            destinationVC.requestsToSend = self.requestsToSend
            destinationVC.networkTableView = self
            self.prevController = nil
            self.playlistVC = destinationVC
            self.groups = [Group]()
            self.viewPlaylistVC = destinationVC
            
            if self.state!.group?.id == self.state!.curActiveId {
                self.state!.group?.songs = self.state!.currentActiveGroup?.songs
                self.state!.group?.totalSongs = self.state!.currentActiveGroup?.totalSongs ?? [Song]()
                self.state!.group?.network = self.state!.currentActiveGroup?.network ?? [[Int]]()
                self.state!.group?.totalSongsFinishedLoading = true
                DispatchQueue.global().async { [unowned self] in
                    Globals.getUserSongs(user: self.state!.user, groupId: self.state!.group?.id ?? -2, state: self.state!)
                    Globals.getUserSelectedPlaylists(user: self.state!.user, groupId: self.state!.group?.id ?? -2, state: self.state!)
                    self.state!.group?.getUsers()
                }
                self.state!.group?.hasLoaded = true
                self.state!.group?.queueLoaded = true
                self.state!.currentActiveGroup = nil
            }
            
            for id in state!.userNetworks.keys {
                if id != state!.group?.id {
                    state!.userNetworks[id]?.resetSongs()
                }
            }
        }
        
        if (segue.identifier == "findFriendsSegue") {
            let destinationVC = segue.destination as! FriendSearchViewController
            destinationVC.state = state
            destinationVC.prevController = "NetworkTable"
            destinationVC.networkTableView = self
        }
        if (segue.identifier == "defaultSongsSegue") {
            let destinationVC = segue.destination as! SongsViewController
            destinationVC.prevController = "User"
            self.state?.group = Group(name: nil, admin: self.state!.user.id, id: -1, picURL: nil, inviteKey: nil, state: self.state!)
            self.state?.group?.totalSongsFinishedLoading = true
            destinationVC.state = state
        }
        if (segue.identifier == "defaultPlaylistsSegue") {
            let destinationVC = segue.destination as! UserPlaylistsTableViewController
            destinationVC.prevController = "User"
            self.state?.group = Group(name: nil, admin: self.state!.user.id, id: -1, picURL: nil, inviteKey: nil, state: self.state!)
            self.state?.group?.totalSongsFinishedLoading = true
            destinationVC.state = state
            self.userPlaylistVC = destinationVC
        }
        if (segue.identifier == "viewGroupRequestsSegue") {
            let destinationVC = segue.destination as! GroupRequestViewController
            destinationVC.state = state
            destinationVC.networkTableVC = self
        }
    }
    
    // MARK: - Helpers
    func facebookLogin(alert: UIAlertAction!) {
        Globals.logIntoFacebook(viewController: self, userId: self.state!.user.id)
    }
    
    func presentUserView(present: Bool) {
        if (present) {
            self.dimView.isHidden = false
            UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            })
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [unowned self] in
                self.userView?.frame = CGRect(x: 0, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { [unowned self] (_) in
                self.userShown = true
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                self.dimView.backgroundColor = UIColor.clear
            })
            self.dimView.isHidden = true
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [unowned self] in
                self.userView?.frame = CGRect(x: 0 - 2 * self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { [unowned self] (_) in
                self.userShown = false
            })
        }
    }
    
    func facebookBtnLogin(alert: UIAlertAction!) {
        if (/*AccessToken.current == nil*/true) {
            Globals.logIntoFacebook(viewController: self, userId: self.state!.user.id)
        } else {
            //LoginManager().logOut()
            self.userView.facebookBtn.setTitle("Connect Facebook Account", for: .normal)
        }
    }
    
    func addPhotoToUser(userId: String, url: String) {
        let requestURL = URL(string: "http://autocollabservice.com/adduserpic")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "url=" + url + "&userId=" + userId
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in }, isAsync: 1)
    }
    
    func reloadNetworkTable() {
        if self.state != nil {
            self.groups = Array(self.state!.userNetworks.values)
        }
        
        if self.groups.count == 0 {
            self.networkTable.isHidden = true
            self.emptyLabel.isHidden = false
            self.emptyLabel.textColor = UIColor.gray
            self.emptyLabel.textAlignment = .center
            
        } else {
            self.networkTable.isHidden = false
            self.emptyLabel.isHidden = true
            self.networkTable.reloadData()
        }
    }
    
    
    
    func presentFirstTimeAlert() {
        firstTimeAlertNameVC = FirstTimeAlertName(frame: CGRect(x: 0, y: self.view.frame.height, width: 300, height: 200), parent: self)
        firstTimeAlertNameVC.center.x = self.view.center.x
        self.view.addSubview(firstTimeAlertNameVC)
        
        firstTimeAlertPhoneVC = FirstTimeAlertPhone(frame: CGRect(x: 0, y: self.view.frame.height, width: 300, height: 250), parent: self, isUpdate: false)
        firstTimeAlertPhoneVC.center.x = self.view.center.x
        self.view.addSubview(firstTimeAlertPhoneVC)
        
        firstTimeAlertConfirmationVC = FirstTimeAlertConfirmation(frame: CGRect(x: 0, y: self.view.frame.height, width: 300, height: 250), parent: self)
        firstTimeAlertConfirmationVC.center.x = self.view.center.x
        self.view.addSubview(firstTimeAlertConfirmationVC)
        
        self.dimView.isHidden = false
        self.dimView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let centerY = self?.view.center.y {
                self?.firstTimeAlertNameVC.center.y = centerY - 100
                self?.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            }
        }) { (_) in
        }
    }
    
    func presentUpdatePhoneNumberAlert() {
        firstTimeAlertPhoneVC = FirstTimeAlertPhone(frame: CGRect(x: 0, y: self.view.frame.height, width: 300, height: 250), parent: self, isUpdate: true)
        firstTimeAlertPhoneVC.center.x = self.view.center.x
        self.view.addSubview(firstTimeAlertPhoneVC)
        
        firstTimeAlertConfirmationVC = FirstTimeAlertConfirmation(frame: CGRect(x: 0, y: self.view.frame.height, width: 300, height: 250), parent: self)
        firstTimeAlertConfirmationVC.center.x = self.view.center.x
        self.view.addSubview(firstTimeAlertConfirmationVC)
        
        self.dimView.isHidden = false
        self.dimView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let centerY = self?.view.center.y {
                self?.firstTimeAlertPhoneVC.center.y = centerY - 100
                self?.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            }
        }) { (_) in
        }
    }
    
    func firstTimeAlertNameSubmit() {
        self.state?.user.name = firstTimeAlertNameVC.displayName.text
        Globals.setDisplayName(id: state!.user.id, name: firstTimeAlertNameVC.displayName.text!)
        self.userView.name.text = firstTimeAlertNameVC.displayName.text
        
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let height = self?.view.frame.height {
                self?.firstTimeAlertNameVC.center.y = height + 400
            }
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                if let centerY = self?.view.center.y {
                    self?.firstTimeAlertPhoneVC.center.y = centerY - 100
                }
            }) { (_) in
            }
        }
    }
    
    func firstTimeAlertPhoneSubmit() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let height = self?.view.frame.height {
                self?.firstTimeAlertPhoneVC.center.y = height + 400
            }
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                if let centerY = self?.view.center.y {
                    self?.firstTimeAlertConfirmationVC.center.y = centerY - 100
                     self?.firstTimeAlertConfirmationVC.confirmationCodeTextField.becomeFirstResponder()
                }
            }) { (_) in
            }
        }
    }
    
    func firstTimeAlertConfirmationSubmit() {
        Globals.addPhoneNumber(id: state!.user.id, number: firstTimeAlertPhoneVC.phoneNumber.text!)
        self.dimView.isUserInteractionEnabled = true
        self.dimView.isHidden = true
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let height = self?.view.frame.height {
                self?.firstTimeAlertConfirmationVC.center.y = height + 400
                self?.dimView.backgroundColor = UIColor.clear
            }
        }) { (_) in
        }
    }
    
    func firstTimeAlertPhoneBack() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let height = self?.view.frame.height {
                self?.firstTimeAlertPhoneVC.center.y = height + 400
            }
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                if let centerY = self?.view.center.y {
                    self?.firstTimeAlertNameVC.center.y = centerY - 100
                }
            }) { (_) in
            }
        }
    }
    
    func firstTimeAlertPhoneCancel() {
        self.dimView.isUserInteractionEnabled = true
        self.dimView.isHidden = true
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let height = self?.view.frame.height {
                self?.firstTimeAlertPhoneVC.center.y = height + 400
            }
        })
    }
    
    func firstTimeAlertConfirmationBack() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            if let height = self?.view.frame.height {
                self?.firstTimeAlertConfirmationVC.center.y = height + 400
            }
        }) { (_) in
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                if let centerY = self?.view.center.y {
                    self?.firstTimeAlertPhoneVC.center.y = centerY - 100
                }
            }) { (_) in
            }
        }
    }
}
