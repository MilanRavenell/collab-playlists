//
//  ViewPlaylistViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 4/10/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SPTAudioStreamingDelegate {
    
    //MARK: Properties
    var songs = [Song]()
    var groupName: UILabel!
    @IBOutlet weak var networkBtn: UIButton!
    var playPauseBtn: UIButton?
    var nextBtn: UIButton!
    var reorderBtn: UIButton!
    var refreshBtn: UIButton!
    var curPosition: UILabel!
    var songLength: UILabel!
    var slider: UISlider?
    var prevController: String?
    var requestsToSend: [String]?
    var activityIndicator: UIActivityIndicatorView?
    let audioSession = AVAudioSession.sharedInstance()
    var dismiss: UITapGestureRecognizer!
    var networkView: NetworkView!
    var groupNameView: UIView!
    var buttonsView: UIView!
    var dimView: UIView!
    var alertView: UIView!
    var alertLabel: UILabel!
    var networkShown = false
    var songInfo = [String: Any]()
    var otherUser: String? = nil
    var totalSongsFinishedLoading = false
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    @IBOutlet weak var songsTable: UITableView!
    var state: State?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (self.state!.player == nil) {
            self.state!.player = SPTAudioStreamingController.sharedInstance()
            try! self.state!.player!.start(withClientId: SPTAuth.defaultInstance()!.clientID)
            self.state!.player!.login(withAccessToken: self.state!.getAccessToken())
        }
        self.state!.player!.playbackDelegate = self
        self.state!.player!.delegate = self

        // Do any additional setup after loading the view.
        // Do any additional setup after loading the view.
        if ((songsTable) != nil) {
            songsTable.dataSource = self
            songsTable.delegate = self
            songsTable.isHidden = true
        }
        
        self.view.backgroundColor = Globals.getThemeColor2()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator?.center = self.view.center
        activityIndicator?.startAnimating()
        self.view.addSubview(activityIndicator!)
        
        // Handle Remote Events
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playPauseBtnPressed(self)
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playPauseBtnPressed(self)
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.nextBtnPressed(self)
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.playPauseBtnPressed(self)
            return .success
        }
        
        if (MPNowPlayingInfoCenter.default().nowPlayingInfo != nil) {
            songInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!
        }
        
        // Handle Audio Interruptions
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: NSNotification.Name.AVAudioSessionInterruption, object: audioSession)
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        // Add group name sub view
        groupNameView = UIView(frame: CGRect(x: 0, y: 65, width: self.view.frame.width, height: 50))
        groupNameView.backgroundColor = UIColor.white
        self.view.addSubview(groupNameView)
        
        groupName = UILabel(frame: CGRect(x: 0, y: 0, width: groupNameView.frame.width, height: groupNameView.frame.height))
        groupName.textAlignment = .center
        groupNameView.addSubview(groupName)
        
        if (self.state?.group?.songs != nil) {
            self.songsTable.reloadData()
            self.songsTable.isHidden = false
            self.activityIndicator?.stopAnimating()
            self.songs = self.state!.group!.songs!
        }
        
        if (self.state!.group != nil) {
            if (self.state!.group!.name == nil || self.state!.group!.name == "") {
                self.groupName.text = Globals.getUsersName(id: self.state!.group!.admin, state: self.state!)  + "'s Network"
            } else {
                self.groupName.text = self.state!.group!.name
            }
        }
        
        if (self.prevController == "FriendSearch") {
            Globals.createGroupRequests(userIds: self.requestsToSend!, groupId: self.state!.group!.id)
        }
        
        // Adjust table
        self.songsTable.backgroundColor = Globals.getThemeColor2()
        self.songsTable.frame = CGRect(x: 0, y: 115, width: self.view.frame.width, height: self.view.frame.height - 115 - 90)
        
        // Add buttons subview
        buttonsView = UIView(frame: CGRect(x: 0, y: songsTable.frame.maxY, width: self.view.frame.width, height: 90))
        buttonsView.backgroundColor = UIColor.white
        self.view.addSubview(buttonsView)
        
        if (otherUser == nil) {
            curPosition = UILabel(frame: CGRect(x: 0, y: 2, width: 70, height: 20))
            curPosition.text = "--:--"
            curPosition.textAlignment = .center
            curPosition.font = curPosition.font.withSize(15)
            slider = UISlider(frame: CGRect(x: 70, y: 2, width:buttonsView.frame.width - 140, height: 20))
            slider!.tintColor = Globals.getThemeColor1()
            slider!.addTarget(self, action: #selector(sliderValueChanged(sender:event:)), for: .valueChanged)
            songLength = UILabel(frame: CGRect(x: buttonsView.frame.width-70, y: 2, width: 70, height: 20))
            songLength.text = "--:--"
            songLength.textAlignment = .center
            songLength.font = songLength.font.withSize(15)
            buttonsView.addSubview(curPosition)
            buttonsView.addSubview(slider!)
            buttonsView.addSubview(songLength)
            
            if (self.state!.metadata != nil && self.state!.group?.id == self.state!.currentActiveGroup) {
                slider!.maximumValue = Float(self.state!.metadata!.currentTrack!.duration)
                songLength.text = intervalToString(time: self.state!.metadata!.currentTrack!.duration)
            }
            
            if (self.state!.player?.playbackState != nil && self.state!.group?.id == self.state!.currentActiveGroup) {
                curPosition.text = intervalToString(time: self.state!.player!.playbackState.position)
            }
            
            reorderBtn = UIButton(type: .system)
            reorderBtn.frame = CGRect(x: 0, y: slider!.frame.maxY, width: buttonsView.frame.width/3, height: buttonsView.frame.height - slider!.frame.maxY)
            reorderBtn.addTarget(self, action: #selector(reorderBtnPressed), for: .touchUpInside)
            reorderBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
            reorderBtn.setTitle("Reorder", for: .normal)
            buttonsView.addSubview(reorderBtn)
            
            playPauseBtn = UIButton(type: .system)
            playPauseBtn?.frame = CGRect(x: buttonsView.frame.width/3, y: slider!.frame.maxY, width: buttonsView.frame.width/3, height: buttonsView.frame.height - slider!.frame.maxY)
            playPauseBtn?.addTarget(self, action: #selector(playPauseBtnPressed), for: .touchUpInside)
            playPauseBtn?.setTitleColor(Globals.getThemeColor1(), for: .normal)
            if (self.state!.player!.playbackState != nil && self.state!.player!.playbackState.isPlaying && self.state?.group?.id == self.state!.currentActiveGroup) {
                playPauseBtn?.setTitle("Pause", for: .normal)
            }
            else {
                playPauseBtn?.setTitle("Play", for: .normal)
            }
            buttonsView.addSubview(playPauseBtn!)
            
            nextBtn = UIButton(type: .system)
            nextBtn.frame = CGRect(x: 2 * buttonsView.frame.width/3, y: slider!.frame.maxY, width: buttonsView.frame.width/3, height: buttonsView.frame.height - slider!.frame.maxY)
            nextBtn.addTarget(self, action: #selector(nextBtnPressed), for: .touchUpInside)
            nextBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
            nextBtn.setTitle("Next", for: .normal)
            buttonsView.addSubview(nextBtn)
            
            dimView = UIView(frame: self.view.frame)
            dimView.isHidden = true
            dismiss = UITapGestureRecognizer(target: self, action: #selector(self.triggerDismiss))
            dimView.addGestureRecognizer(dismiss)
            self.view.addSubview(dimView)
            
            networkView = NetworkView(frame: CGRect(x: self.view.frame.width, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height), parent: self)
            networkView.backgroundColor = Globals.getThemeColor2()
            self.view.addSubview(networkView)
            if (networkShown) {
                dimView.isHidden = false
                dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                networkView.frame = CGRect(x: self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }
            
            alertView = UIView(frame: CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 50))
            alertView.backgroundColor = Globals.getThemeColor1()
            self.view.addSubview(alertView)
            alertLabel = UILabel(frame: CGRect(x: 0, y: 0, width: alertView.frame.width, height: alertView.frame.height))
            alertLabel.textAlignment = .center
            alertLabel.textColor = UIColor.white
            alertLabel.text = "hi"
            alertView.addSubview(alertLabel)
            
            let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didLeftSwipe))
            leftSwipeGesture.direction = .left
            self.songsTable.addGestureRecognizer(leftSwipeGesture)
            
            let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
            rightSwipeGesture.direction = .right
            self.songsTable.addGestureRecognizer(rightSwipeGesture)
            
            let networkRightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
            networkRightSwipeGesture.direction = .right
            self.networkView.addGestureRecognizer(networkRightSwipeGesture)
            
            let dimRightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
            dimRightSwipeGesture.direction = .right
            self.dimView.addGestureRecognizer(dimRightSwipeGesture)
        } else {
            networkBtn.isHidden = true
            songsTable.allowsSelection = false
            if (self.otherUser != nil) {
                self.groupName.text = self.groupName.text! + " (" + Globals.getUsersName(id: self.otherUser!, state: self.state!) + ")"
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (self.otherUser != nil) {
            load(userId: self.otherUser!)
        } else {
            if (self.state?.group?.songs == nil) {
                load(userId: self.state!.user.id)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Table Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PlaylistSongTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PlaylistSongTableViewCell else{
            fatalError("It messed up")
        }
        
        let albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
        cell.addSubview(albumCover)
        
        cell.backgroundColor = UIColor.clear
        
        // Fetches the appropriate song
        let song = self.songs[indexPath.row]
        
        albumCover.image = song.image
        
        if (!song.imageHasLoaded){
            DispatchQueue.global().async {
                if (song.imageURL != nil) {
                    let url = URL(string: song.imageURL!)
                    if let data = try? Data(contentsOf: url!) {
                        DispatchQueue.main.async {
                            UIView.animate(withDuration: 2.0, animations: {
                                albumCover.alpha = 0.0
                            }, completion: { (finished) in
                                albumCover.image = UIImage(data: data)!
                                UIView.animate(withDuration: 2.0, delay: 0.3, options: .curveLinear, animations: {
                                    albumCover.alpha = 1.0
                                }, completion: { (finished) in
                                    return
                                })
                            })
                        }
                    }
                }
            }
        }

        cell.name.text = song.name
        cell.artist.text = song.artist
        cell.artist.font = cell.artist.font.withSize(15)
        
        cell.name.frame = CGRect(x: cell.name.frame.minX, y: cell.name.frame.minY, width: cell.frame.width -  cell.name.frame.minX - 10, height: cell.name.frame.height)
        cell.artist.frame = CGRect(x: cell.artist.frame.minX, y: cell.artist.frame.minY, width: cell.frame.width -  cell.artist.frame.minX - 10, height: cell.artist.frame.height)
        
        if (indexPath.section == 0 && indexPath.row == 0 && self.state!.group?.id == self.state!.currentActiveGroup) {
            cell.name.textColor = Globals.getThemeColor1()
            cell.artist.textColor = Globals.getThemeColor1()
        } else {
            cell.name.textColor = UIColor.black
            cell.artist.textColor = UIColor.black
        }
        
        // Configure the cell...
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.songs.removeFirst(indexPath.row)
        playPauseBtn?.setTitle("Pause", for: .normal)
        self.state!.currentActiveGroup = self.state!.group!.id
        playSong(player: self.state!.player!, song: self.songs[0])
        
        let newSongs = Globals.generateSongs(groupId: self.state!.group!.id, numSongs: indexPath.row, lastSong: self.songs.last?.id, state: self.state!)
        self.songs.append(contentsOf: newSongs)
        
        Globals.addPlaylistSongs(songs: self.songs, groupId: self.state!.group!.id, userId: self.state!.user.id)
        self.songsTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if (destinationIndexPath.row == 0 && destinationIndexPath.section == 0 && self.state!.group!.id == self.state!.currentActiveGroup) {
            songsTable.reloadData()
            return
        }
        let movedSong = self.songs[sourceIndexPath.row]
        self.songs.remove(at: sourceIndexPath.row)
        self.songs.insert(movedSong, at: destinationIndexPath.row)
        
        self.state!.group?.songs = self.songs
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if (textField.text != "") {
            self.networkView.nameLabel.text = textField.text
            self.networkView.nameLabel.isHidden = false
            textField.isHidden = true
        }
        self.networkView.setGroupName(name: textField.text!)
        self.state!.group!.name = textField.text!
        if (textField.text! == "") {
            self.groupName.text = Globals.getUsersName(id: self.state!.group!.admin, state: self.state!)  + "'s Network"
        } else {
            self.groupName.text = textField.text!
        }
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        
        self.state!.group!.pic.pointee = image
        self.networkView.groupPicView?.image = image
        
        picker.dismiss(animated: true, completion: nil)
        
        let url = URL(string: "http://autocollabservice.com/addgroupimage");
        let request = NSMutableURLRequest(url: url!);
        request.httpMethod = "POST"
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = UIImageJPEGRepresentation(image, 1)
        if (imageData == nil) {
            print("UIImageJPEGRepresentation return nil")
            return
        }
        
        let body = NSMutableData()
        body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format:"Content-Disposition: form-data; name=\"file\"; filename=\"groupPic\(self.state!.group!.id).jpg\"\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format: "Content-Type: application/octet-stream\r\n\r\n").data(using: String.Encoding.utf8.rawValue)!)
        body.append(imageData!)
        body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
        
        request.httpBody = body as Data
        
        Globals.sendRequest(request: request, postParameters: nil, method: "POST", completion: {_ in}, isAsync: 1)
        
        // Add photo url to group in database
        addPhotoToGroup(groupId: self.state!.group!.id, url: "http://autocollabservice.com/images/groupPic\(self.state!.group!.id).jpg")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.state!.group?.songs = self.songs
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "playlistBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            if (self.state!.group != nil) {
                self.state!.userNetworks[self.state!.group!.id] = self.state!.group!
            }
            state?.group = nil
            destinationVC.state = state
        }
        
        if (segue.identifier == "mySongsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongsViewController
            destinationVC.prevController = "ViewPlaylist"
            destinationVC.state = state
        }
        
        if (segue.identifier == "viewUsersSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupUserTableViewController
            destinationVC.state = state
        }
        
        if (segue.identifier == "myPlaylistsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! UserPlaylistsTableViewController
            destinationVC.prevController = "ViewPlaylist"
            destinationVC.state = state
        }
        
        if (segue.identifier == "totalSongsSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! TotalSongsViewController
            destinationVC.viewPlaylistView = self
            destinationVC.state = state
        }
    }
    
    //MARK: - Actions
    func playPauseBtnPressed(_ sender: Any) {
        if (self.state!.player!.playbackState != nil && self.state!.group?.id == self.state!.currentActiveGroup) {
            if (self.state!.player!.playbackState.isPlaying) {
                updateIsPlaying(update: false)
                playPauseBtn?.setTitle("Play", for: .normal)
                self.songInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            }
            else {
                updateIsPlaying(update: true)
                playPauseBtn?.setTitle("Pause", for: .normal)
                self.songInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            }
        } else {
            if (self.songs.count > 0) {
                self.state!.currentActiveGroup = self.state!.group!.id
                playSong(player: self.state!.player!, song: self.songs[0])
                playPauseBtn?.setTitle("Pause", for: .normal)
                self.songsTable.reloadData()
            }
            
        }
    }
    
    func nextBtnPressed(_ sender: Any) {
        if (self.songs.count > 0) {
            self.songs.removeFirst()
            self.state!.currentActiveGroup = self.state!.group!.id
            playSong(player: self.state!.player!, song: self.songs[0])
            if (self.songs.count < 10) {
                let newSong = Globals.generateSongs(groupId: self.state!.group!.id, numSongs: 1, lastSong: self.songs.last?.id, state: self.state!)[0]
                self.songs.append(newSong)
            }
            Globals.addPlaylistSongs(songs: self.songs, groupId: self.state!.group!.id, userId: self.state!.user.id)
            playPauseBtn?.setTitle("Pause", for: .normal)
            self.songsTable.reloadData()
        }
    }
    
    
    func reorderBtnPressed(sender: UIButton!) {
        if self.songsTable.isEditing {
            self.songsTable.setEditing(false, animated: true)
            self.reorderBtn.setTitle("Reorder", for: .normal)
        } else {
            self.songsTable.setEditing(true, animated: true)
            self.reorderBtn.setTitle("Finish", for: .normal)
        }
    }
    
    @IBAction func backBtnPressed(_ sender: Any) {
        if (self.otherUser != nil) {
            self.performSegue(withIdentifier: "viewUsersSegue", sender: self)
        } else {
            self.performSegue(withIdentifier: "playlistBackSegue", sender: self)
        }
    }
    
    @IBAction func viewNetworkBtnPressed(_ sender: Any) {
        presentNetworkView(present: !self.networkShown)
    }
    
    func triggerDismiss() {
        presentNetworkView(present: false)
        
        if (self.networkView.nameTextField.isHidden == false) {
            if (self.networkView.nameTextField.text != "") {
                self.networkView.nameLabel.text = self.networkView.nameTextField.text
                self.networkView.nameLabel.isHidden = false
                self.networkView.nameTextField.isHidden = true
            }
            self.view.endEditing(true)
            self.networkView.setGroupName(name: self.networkView.nameTextField.text!)
            self.state!.group!.name = self.networkView.nameTextField.text!
            if (self.networkView.nameTextField.text! == "") {
                self.groupName.text = Globals.getUsersName(id: self.state!.group!.admin, state: self.state!) + "'s Network"
            } else {
                self.groupName.text = self.networkView.nameTextField.text!
            }
        }
        
    }
    
    func didLeftSwipe() {
        presentNetworkView(present: true)
    }
    
    func didSwipeRight() {
        backBtnPressed(sender: self)
    }
    
    func sliderValueChanged(sender: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            if (touchEvent.phase == .ended) {
                if (self.state!.player!.playbackState == nil ) {
                    playSong(player: self.state!.player!, song: self.songs[0])
                    
                }
                self.state!.player!.seek(to: Double(sender.value), callback: { (error) in
                    if (error == nil) {
                        print("changed!")
                    }
                })
            }
        }
        curPosition.text = intervalToString(time: Double(sender.value))
        self.songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(sender.value)
    }
    
    func showAlert(text: String) {
        self.alertLabel.text = text
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.alertView.frame = CGRect(x: 0, y: self.view.frame.height - 50, width: self.view.frame.width, height: 50)
        }) { (finished) in
            UIView.animate(withDuration: 0.2, delay: 0.7, options: .curveEaseOut, animations: {
                self.alertView.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 50)
            }) { (finished) in
                return
            }
        }
    }
    
    // MARK: - SPTAudioStreamingPlaybackDelegate Methods
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if (isPlaying) {
            self.activateAudioSession()
        } else {
            self.deactivateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        self.songs.removeFirst()
        playSong(player: audioStreaming, song: self.songs[0])
        if (self.songs.count < 10) {
            let newSong = Globals.generateSongs(groupId: self.state!.currentActiveGroup!, numSongs: 1, lastSong: songs.last?.id, state: self.state!)[0]
            songs.append(newSong)
        }
        Globals.addPlaylistSongs(songs: songs, groupId: self.state!.currentActiveGroup!, userId: self.state!.user.id)

        self.state!.userNetworks[self.state!.currentActiveGroup!]?.songs = songs
        
        self.songsTable.reloadData()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        self.state!.metadata = metadata
        songInfo[MPMediaItemPropertyPlaybackDuration] = metadata.currentTrack!.duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
        if (self.state!.group?.id == self.state!.currentActiveGroup) {
            self.songLength.text = intervalToString(time: metadata.currentTrack!.duration)
            self.curPosition.text = "0:00"
            self.slider!.maximumValue = Float(metadata.currentTrack!.duration)
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        if (self.slider != nil && !self.slider!.isTouchInside && self.state!.group?.id == self.state!.currentActiveGroup) {
            self.slider!.setValue(Float(position), animated: true)
            self.curPosition.text = intervalToString(time: position)
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }
    
    // Handle Audio Interruption
    func handleInterruption(notification: NSNotification) {
        print("handleInterruption")
        guard let value = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue,
            let interruptionType =  AVAudioSessionInterruptionType(rawValue: value)
            else {
                print("notification.userInfo?[AVAudioSessionInterruptionTypeKey]", notification.userInfo?[AVAudioSessionInterruptionTypeKey])
                return }
        switch interruptionType {
        case .began:
            playPauseBtnPressed(self)
        default:
            playPauseBtnPressed(self)
        }
    }
 
    // MARK: - Helpers
    
    func load(userId: String) {
        if (self.prevController == "FriendSearchWithNewGroup") {
            let (groupId, inviteKey) = Globals.createGroup(userId: self.state!.user.id)
            Globals.addGroupUsers(groupId: groupId, userIds: [self.state!.user.id])
            let group = Group(name: nil, admin: self.state!.user.id, id: groupId, picURL: nil, users: [self.state!.user.id], inviteKey: inviteKey)
            self.state!.group = group
            self.state!.userNetworks[groupId] = group!
            
            // Set netwrok view values
            if (self.state?.group?.name == nil || self.state?.group?.name == "") {
                self.networkView.nameLabel.isHidden = true
            } else {
                self.networkView.nameTextField.isHidden = true
                self.networkView.nameLabel.text = self.state?.group?.name
            }
            
            if (self.state?.group?.admin == self.state?.user.id) {
                self.networkView.deleteLeaveBtn.setTitle("Delete Network", for: .normal)
            } else  {
                self.networkView.deleteLeaveBtn.setTitle("Leave Network", for: .normal)
            }
            
            Globals.createGroupRequests(userIds: self.requestsToSend!, groupId: groupId)
            
            Globals.addUserDefaults(user: self.state!.user.id, group: self.state!.group!, state: self.state!)
            
            var generatedSongs = [Song]()
            var i = 0
            
            while (generatedSongs.count == 0 && i < 5) {
                generatedSongs = Globals.generateSongs(groupId: self.state!.group!.id, numSongs: 10, lastSong: nil, state: self.state!)
                i += 1
            }
            
            Globals.addPlaylistSongs(songs: generatedSongs, groupId: self.state!.group!.id, userId: self.state!.user.id)
           self.songs = generatedSongs
            
            // Update Group Name
            if (self.state!.group!.name == nil || self.state!.group!.name == "") {
                self.groupName.text = Globals.getUsersName(id: self.state!.group!.admin, state: self.state!)  + "'s Network"
            } else {
                self.groupName.text = self.state!.group!.name
            }
        }
        else {
            self.songs = getPlaylistSongs(userId: userId)
        }
        
        self.state!.user.songs[self.state!.group!.id] = Globals.getUserSongs(userId: self.state!.user.id, groupId: self.state!.group!.id, state: self.state!)
        self.state!.user.playlists[self.state!.group!.id] = Globals.getUserPlaylists(userId: self.state!.user.id, groupId: self.state!.group!.id, state: self.state!)
        
        self.songsTable.reloadData()
        self.songsTable.isHidden = false
        print("done")
        self.activityIndicator?.stopAnimating()
        self.getTotalSongsAsync()
    }
    
    func playSong(player: SPTAudioStreamingController, song: Song) {
        player.playSpotifyURI("spotify:track:\(song.id)", startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error == nil) {
                print("playing!")
            }
        })
        
        songInfo = [
            MPMediaItemPropertyTitle:  song.name ,
            MPMediaItemPropertyArtist: song.artist ,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
            ] as [String : Any]
        
        // If song plays before image loads
        if (song.image != nil){
            songInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork.init(boundsSize: song.image.size, requestHandler: { (size) -> UIImage in
                return song.image
            })
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
    }
    
    func updateIsPlaying(update: Bool) {
        self.state!.player?.setIsPlaying(update, callback: { (error) in
            if (error != nil) {
                print("error")
            }
        })
    }
    
    func getPlaylistSongs(userId: String) -> [Song] {
        NSLog("PlaylistSong")
        var playlistSongsUnordered = [(Song, Int)]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getplaylistsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "groupId=\(self.state!.group!.id)&userId=" + userId
        
        var responseDict: [String: AnyObject]?
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            responseDict = response as? [String: AnyObject]
        }, isAsync: 0)
        
        if (responseDict == nil) {
            return []
        }
        
        let songs = responseDict!["songs"] as! [[AnyObject]]
        
        for song in songs {
            let name = song[1] as! String
            let artist = song[2] as! String
            let id = song[3] as! String
            let order = song[4] as! Int
            let albumCover = song[5] as? String
            let song = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: self.state!)
            song?.imageURL = albumCover
            playlistSongsUnordered.append((song!, order))
        }
                
        let playlistSongsOrdered = playlistSongsUnordered.sorted(by: { $0.1 < $1.1 })
        
        var playlistSongs = [Song]()
        
        for (song, _) in playlistSongsOrdered {
            playlistSongs.append(song)
        }
        
        return playlistSongs
    }
    
    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: Deactivate audio session
    
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func presentNetworkView(present: Bool) {
        if (present) {
            self.dimView.isHidden = false
            UIView.animate(withDuration: 0.15, animations: {
                self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            })
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                self.networkView?.frame = CGRect(x: self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { (finished) in
                self.songsTable.isScrollEnabled = false
                self.reorderBtn.isEnabled = false
                self.playPauseBtn?.isEnabled = false
                self.nextBtn.isEnabled = false
                self.networkShown = true
                self.songsTable.reloadData()
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: {
                self.dimView.backgroundColor = UIColor.clear
            })
            self.dimView.isHidden = true
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                self.networkView?.frame = CGRect(x: self.view.frame.width, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { (finished) in
                self.songsTable.isScrollEnabled = true
                self.reorderBtn.isEnabled = true
                self.playPauseBtn?.isEnabled = true
                self.nextBtn.isEnabled = true
                self.networkShown = false
                self.songsTable.reloadData()
            })
        }
    }
    
    func addPhotoToGroup(groupId: Int, url: String) {
        let requestURL = URL(string: "http://autocollabservice.com/addgrouppic")
        let request = NSMutableURLRequest(url: requestURL!)
        let postParameters = "&url=" + url + "&groupId=\(groupId)"
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: {_ in }, isAsync: 0)
    }
    
    func intervalToString(time: TimeInterval) -> String {
        var str = ""
        let hour = floor(time/360)
        let minute = floor((time - hour * 360)/60)
        let second = floor(time - (hour * 360) - (minute * 60))
        
        if (hour > 1) {
            str += String(Int(hour))
            str += ":"
        }
        str += String(Int(minute))
        str += ":"
        str += String(format: "%02d", Int(second))
        
        return str
    }
    
    func getTotalSongsAsync() {
        var totalSongs = [Song]()
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/gettotalsongs")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        
        let postParameters = "groupId=\(self.state!.group!.id)"
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            let responseDict = response as? [String: [[AnyObject]]]
            
            let responseSongs = responseDict?["songs"]
            if (responseSongs != nil) {
                for song in responseSongs! {
                    let name = song[1] as! String
                    let artist = song[2] as! String
                    let id = song[0] as! String
                    let albumCover = song[5] as? String
                    let newSong = Song(name: name, artist: artist, id: id, imageURL: albumCover, state: self.state!)
                    print("appended")
                    totalSongs.append(newSong!)
                }
            }
            
            self.state!.group?.totalSongs = totalSongs
            self.state!.group?.totalSongsFinishedLoading = true
            print("doneeeeeeee")
        }, isAsync: 1)
    }
}
