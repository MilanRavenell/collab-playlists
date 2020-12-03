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

class ViewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SPTAppRemotePlayerStateDelegate {
    
    //MARK: - Properties
    var songs = [Song]()
    var nowPlayingLabel: UILabel!
    var upNextLabel: UILabel!
    @IBOutlet weak var networkBtn: UIBarButtonItem!
    var upNextBtn: UIButton!
    var playPauseBtn: UIButton?
    var nextBtn: UIButton!
    var randomBtn: UIButton!
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
    var otherUser: String?
    var totalSongsFinishedLoading = false
    weak var networkTableView: NetworkTableViewController?
    var newGroupName: String?
    var userPlaylistVC: UserPlaylistsTableViewController?
    var groupToDelete: Int?
    var groupToCreate: Int?
    var totalSongsVC: TotalSongsViewController?
    var curPlaylingId: String?
    var didTimeOut = false
    var timeOutLabel: UILabel!
    var nowPlayingView: NowPlaying!
    var selectedIndex: Int!
    var curTrackPosition = 0
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    @IBOutlet weak var songsTable: UITableView!
    var state: State?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.state!.group?.name

        // Do any additional setup after loading the view.
        // Do any additional setup after loading the view.
        if songsTable != nil {
            songsTable.dataSource = self
            songsTable.delegate = self
            songsTable.isHidden = true
            songsTable.allowsSelectionDuringEditing = true
        }
        
        self.view.backgroundColor = Globals.getThemeColor2()
        
        activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator?.center = self.view.center
        activityIndicator?.startAnimating()
        self.view.addSubview(activityIndicator!)
        
        if (MPNowPlayingInfoCenter.default().nowPlayingInfo != nil) {
            songInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!
        }
        
        // Handle Audio Interruptions
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: audioSession)
        
        // Add group name sub view
        groupNameView = UIView(frame: CGRect(x: 0, y: 65, width: self.view.frame.width, height: 50))
        groupNameView.backgroundColor = UIColor.white
        self.view.addSubview(groupNameView)
        
        nowPlayingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: groupNameView.frame.width, height: groupNameView.frame.height))
        nowPlayingLabel.textAlignment = .center
        nowPlayingLabel.isUserInteractionEnabled = true
        nowPlayingLabel.text = "Now Playing"
        groupNameView.addSubview(nowPlayingLabel)
        
        upNextLabel = UILabel(frame: CGRect(x: 0, y: 0, width: groupNameView.frame.width, height: groupNameView.frame.height))
        upNextLabel.textAlignment = .center
        upNextLabel.isUserInteractionEnabled = true
        upNextLabel.text = "Up Next"
        upNextLabel.alpha = 0
        groupNameView.addSubview(upNextLabel)
        
        randomBtn = UIButton(type: .system)
        randomBtn.frame = CGRect(x: 6 * view.frame.width/7 - 10, y: 0, width: view.frame.width/7, height: nowPlayingLabel.frame.height)
        randomBtn.addTarget(self, action: #selector(randomBtnPressed), for: .touchUpInside)
        randomBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        randomBtn.setTitle("Random", for: .normal)
        randomBtn?.isEnabled = false
        randomBtn?.alpha = 0
        groupNameView.addSubview(randomBtn)
        
        // Adjust table
        self.songsTable.backgroundColor = Globals.getThemeColor2()
        self.songsTable.frame = CGRect(x: 0, y: 115, width: self.view.frame.width, height: self.view.frame.height - 115 - 90)
        self.songsTable.isEditing = true
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songsTable.addGestureRecognizer(rightSwipeGesture)
        
        let backgroundRightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        backgroundRightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(backgroundRightSwipeGesture)
        
        nowPlayingView = NowPlaying(frame: CGRect(x: 0, y: songsTable.frame.minY, width: view.frame.width, height: songsTable.frame.maxY - songsTable.frame.minY), parent: self)
        self.view.addSubview(nowPlayingView)
        
        // Add buttons subview
        buttonsView = UIView(frame: CGRect(x: 0, y: songsTable.frame.maxY, width: self.view.frame.width, height: 90))
        buttonsView.backgroundColor = UIColor.white
        self.view.addSubview(buttonsView)
        
        curPosition = UILabel(frame: CGRect(x: 0, y: 2, width: 70, height: 20))
        curPosition.text = "--:--"
        curPosition.textAlignment = .center
        curPosition.font = curPosition.font.withSize(15)
        slider = UISlider(frame: CGRect(x: 70, y: 2, width: buttonsView.frame.width - 140, height: 20))
        slider!.tintColor = Globals.getThemeColor1()
        slider!.addTarget(self, action: #selector(sliderValueChanged(sender:event:)), for: .valueChanged)
        songLength = UILabel(frame: CGRect(x: buttonsView.frame.width-70, y: 2, width: 70, height: 20))
        songLength.text = "--:--"
        songLength.textAlignment = .center
        songLength.font = songLength.font.withSize(15)
        buttonsView.addSubview(curPosition)
        buttonsView.addSubview(slider!)
        buttonsView.addSubview(songLength)
        
        upNextBtn = UIButton(type: .system)
        upNextBtn.frame = CGRect(x: 0, y: slider!.frame.maxY, width: buttonsView.frame.width/3, height: buttonsView.frame.height - slider!.frame.maxY)
        upNextBtn.addTarget(self, action: #selector(upNextBtnPressed), for: .touchUpInside)

        if let image = UIImage(named: "hamburger.png") {
            upNextBtn.setImage(image, for: .normal)
            upNextBtn.tintColor = Globals.getThemeColor1()
        }

        buttonsView.addSubview(upNextBtn)
        
        playPauseBtn = UIButton(type: .system)
        playPauseBtn?.frame = CGRect(x: buttonsView.frame.width/3, y: slider!.frame.maxY, width: buttonsView.frame.width/3, height: buttonsView.frame.height - slider!.frame.maxY)
        playPauseBtn?.addTarget(self, action: #selector(playPauseBtnPressed), for: .touchUpInside)
        playPauseBtn?.tintColor = Globals.getThemeColor1()
        playPauseBtn?.setTitleColor(Globals.getThemeColor1(), for: .normal)
        if let playerState = self.state!.playerState, playerState.isPaused && self.state?.group?.id == self.state!.curActiveId {
            if let image = UIImage(named: "pause.png") {
                playPauseBtn?.setImage(image, for: .normal)
            }
        } else {
            if let image = UIImage(named: "play.png") {
                playPauseBtn?.setImage(image, for: .normal)
            }
        }
        playPauseBtn?.isEnabled = false
        playPauseBtn?.alpha = 0.5
        buttonsView.addSubview(playPauseBtn!)
        
        nextBtn = UIButton(type: .system)
        nextBtn.frame = CGRect(x: 2 * buttonsView.frame.width/3, y: slider!.frame.maxY, width: buttonsView.frame.width/3, height: buttonsView.frame.height - slider!.frame.maxY)
        nextBtn.addTarget(self, action: #selector(nextBtnPressed), for: .touchUpInside)
        nextBtn?.tintColor = Globals.getThemeColor1()
        nextBtn?.isEnabled = false
        nextBtn?.alpha = 0.5
        
        if let image = UIImage(named: "next.png") {
            nextBtn?.setImage(image, for: .normal)
        }
        
        buttonsView.addSubview(nextBtn)
        
        dimView = UIView(frame: self.view.frame)
        dimView.isHidden = true
        dismiss = UITapGestureRecognizer(target: self, action: #selector(self.triggerDismiss))
        dimView.addGestureRecognizer(dismiss)
        self.view.addSubview(dimView)
        
        timeOutLabel = UILabel(frame: view.frame)
        timeOutLabel.textColor = UIColor.gray
        timeOutLabel.textAlignment = .center
        self.view.addSubview(timeOutLabel)
        
        networkView = NetworkView(frame: CGRect(x: self.view.frame.width, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height), parent: self)
        self.view.addSubview(networkView)
        
        if networkShown {
            dimView.isHidden = false
            dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            networkView.frame = CGRect(x: self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
        }
        
        if (self.otherUser != nil) {
            load()
        } else if (self.state!.group == nil || !self.state!.group!.hasLoaded) {
            if let queueLoaded = self.state!.group?.queueLoaded, queueLoaded {
                self.songs = self.state!.group?.songs ?? [Song]()
                self.reloadSongsTable()
                self.songsTable.isHidden = false
                self.activityIndicator?.stopAnimating()
            }
            load()
        } else if (self.state!.group!.isGenerating) {
            
        }
        else {
            self.songs = self.state!.group?.songs ?? [Song]()
            self.reloadSongsTable()
            self.songsTable.isHidden = false
            self.activityIndicator?.stopAnimating()
        }
        
        if (otherUser == nil) {
            self.state!.viewPlaylistVC = self
            self.state!.appRemote?.playerAPI?.delegate = self
            
            nextBtn?.isEnabled = true
            nextBtn?.alpha = 1
            playPauseBtn?.isEnabled = true
            playPauseBtn?.alpha = 1
            randomBtn?.isEnabled = true
            randomBtn?.alpha = 0
            
            if let playerState = self.state!.playerState, self.state!.group?.id == self.state!.curActiveId {
                let track = playerState.track
                slider?.maximumValue = Float(track.duration)
                songLength.text = intervalToString(time: TimeInterval(track.duration))
                curPosition.text = intervalToString(time: TimeInterval(playerState.playbackPosition))
            }
            
            let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didLeftSwipe))
            leftSwipeGesture.direction = .left
            self.songsTable.addGestureRecognizer(leftSwipeGesture)
            
            let backgroundLeftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didLeftSwipe))
            backgroundLeftSwipeGesture.direction = .left
            self.view.addGestureRecognizer(backgroundLeftSwipeGesture)
            
            let networkRightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
            networkRightSwipeGesture.direction = .right
            self.networkView.addGestureRecognizer(networkRightSwipeGesture)
            
            let dimRightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(triggerDismiss))
            dimRightSwipeGesture.direction = .right
            self.dimView.addGestureRecognizer(dimRightSwipeGesture)
            
        } else {
            networkBtn.isEnabled = false
            songsTable.allowsSelection = false
            curPosition.isHidden = true
            slider?.isHidden = true
            songLength?.isHidden = true
            if (self.otherUser != nil) {
                let otherUserName = Globals.getUsersName(id: self.otherUser!, state: self.state!) ?? "Network Error"
                self.title = otherUserName + "'s Queue"
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if otherUser == nil {
            self.songs = self.state!.group?.songs ?? [Song]()
            reloadSongsTable()
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
        
        if let totalSongsVC = self.totalSongsVC {
            totalSongsVC.searchController?.isActive = false
            self.totalSongsVC = nil
        }
        
        self.state!.groupUsersVC = nil
        
        if let id = self.state?.group?.id {
            DispatchQueue.global().async { [weak self] in
                if let state = self?.state {
                    if let group = Globals.getGroupsById(ids: [id], state: state).first {
                        DispatchQueue.main.async {
                            self?.networkView.nameLabel.text = group.name
                            self?.state!.group?.name = group.name
                            self?.state!.group?.picURL = group.picURL
                            self?.state!.group?.getPic()
                            if let imageView = self?.networkView.groupPicView {
                                self?.state!.group?.assignPicToView(imageView: imageView)
                            }
                        }
                    }
                }
            }
        }
        
        self.state?.totalSongsVC = nil
        self.state?.songsVC = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "PlaylistSongTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PlaylistSongTableViewCell else{
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
        // Fetches the appropriate song
        let song = self.songs[indexPath.row]
        song.assignPicToView(imageView: cell.albumCover)

        cell.name.text = song.name
        cell.artist.text = song.artist
        cell.artist.font = cell.artist.font.withSize(15)
        
        cell.name.frame = CGRect(x: cell.name.frame.minX, y: cell.name.frame.minY, width: cell.frame.width -  cell.name.frame.minX - 10, height: cell.name.frame.height)
        cell.artist.frame = CGRect(x: cell.artist.frame.minX, y: cell.artist.frame.minY, width: cell.frame.width -  cell.artist.frame.minX - 10, height: cell.artist.frame.height)
        
        if (indexPath.section == 0 && indexPath.row == 0 && self.state!.group?.id == self.state!.curActiveId) {
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
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedSong = self.songs[indexPath.row]
        selectedIndex = indexPath.row
        
        selectedSong.loadPic()
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 80, height: 80))
        selectedSong.assignPicToView(imageView: imageView)
        let name = UILabel(frame: CGRect(x: 100, y: 25, width: view.frame.width - 100, height: 50))
        name.textColor = UIColor.white
        name.text = selectedSong.name
        name.font = name.font.withSize(25)
        let artist = UILabel(frame: CGRect(x: 100, y: 53, width: view.frame.width - 100, height: 50))
        artist.textColor = UIColor.white
        artist.text = selectedSong.artist
        artist.font = artist.font.withSize(15)
        titleView.addSubview(imageView)
        titleView.addSubview(name)
        titleView.addSubview(artist)
        
        let choiceSelection = ChoiceSelection(titleView: titleView, choices: [("Play Now", "play_small.png", selectFromTable), ("Delete", "icons8-waste-32.png", deleteFromTable), ("Cancel", "icons8-delete-40.png", nil)], view: view)
        choiceSelection.present(show: true)
    }
    
    func selectFromTable() {
        self.songs.removeFirst(selectedIndex)
        self.updatePlayPauseBtn(isPlaying: true)
        self.state?.curActiveId = self.state!.group?.id ?? self.state?.curActiveId
        self.state!.currentActiveGroup = nil
        
        if let appRemote = self.state!.appRemote, let playerAPI = appRemote.playerAPI {
            playSong(playerAPI: playerAPI, song: self.songs[0])
        }
        
        DispatchQueue.global().async { [unowned self] in
            self.state!.group?.songs = self.songs
            if let group = self.state!.group {
                Globals.generateSongs(group: group, numSongs: self.selectedIndex, lastSong: self.songs.last, state: self.state!, viewPlaylistVC: nil)
                self.songs = group.songs ?? [Song]()
            }
            DispatchQueue.main.async { [unowned self] in
                if self.songs.count > 0 {
                    self.songsTable.beginUpdates()
                    var deletePaths = [IndexPath]()
                    var insertPaths = [IndexPath]()
                    for i in 0..<self.selectedIndex {
                        deletePaths.append(IndexPath(row: i, section: 0))
                        insertPaths.append(IndexPath(row: self.songs.count - i - 1, section: 0))
                    }
                    self.songsTable.deleteRows(at: deletePaths, with: .fade)
                    self.songsTable.insertRows(at: insertPaths, with: .fade)
                    self.songsTable.endUpdates()
                    
                    let cell = self.songsTable.cellForRow(at: IndexPath(row: 0, section: 0)) as? PlaylistSongTableViewCell
                    cell?.name.textColor = Globals.getThemeColor1()
                    cell?.artist.textColor = Globals.getThemeColor1()
                } else {
                    self.reloadSongsTable()
                }
                
            }
            if let id = self.state!.group?.id {
                Globals.addPlaylistSongs(songs: self.songs, groupId: id, userId: self.state!.user.id)
            }
        }
    }
    
    func deleteFromTable() {
        
        if selectedIndex == 0 && self.state!.group?.id == self.state!.curActiveId {
            Globals.showAlert(text: "Can't delete currently playing song", view: self.view)
            return
        }
        
        self.songs.remove(at: selectedIndex)
        self.songsTable.beginUpdates()
        songsTable.deleteRows(at: [IndexPath(row: selectedIndex, section: 0)], with: .fade)
        self.songsTable.endUpdates()
        self.state!.group?.songs = self.songs
        if self.songs.count < 10 {
            updateSongsAfterDeletion()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if (destinationIndexPath.row == 0 && destinationIndexPath.section == 0 && self.state!.group?.id == self.state!.curActiveId) {
            reloadSongsTable()
            Globals.showAlert(text: "Can't move currently playing song", view: self.view)
            return
        }
        if (sourceIndexPath.row == 0 && sourceIndexPath.section == 0 && self.state!.group?.id == self.state!.curActiveId) {
            reloadSongsTable()
            Globals.showAlert(text: "Can't move currently playing song", view: self.view)
            return
        }
        let movedSong = self.songs[sourceIndexPath.row]
        self.songs.remove(at: sourceIndexPath.row)
        self.songs.insert(movedSong, at: destinationIndexPath.row)
        self.state!.group?.songs = self.songs
        if let id = self.state!.group?.id {
            Globals.addPlaylistSongs(songs: self.songs, groupId: id, userId: self.state!.user.id)
        }
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func updateSongsAfterDeletion() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: { [unowned self] in
            if let group = self.state!.group {
                Globals.generateSongs(group: group, numSongs: 1, lastSong: self.songs.last, state: self.state!, viewPlaylistVC: self)
                self.songs = group.songs ?? [Song]()
            }
            DispatchQueue.main.async {
                self.reloadSongsTable()
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        networkView.saveName()
        return true
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerController.InfoKey.editedImage.rawValue] as! UIImage
        
        self.state!.group?.pic = image
        self.networkView.groupPicView?.image = image
        self.state!.archiveGroups()
        
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
        
        if let id = self.state!.group?.id {
            let body = NSMutableData()
            body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
            body.append(NSString(format:"Content-Disposition: form-data; name=\"file\"; filename=\"groupPic\(id).jpg\"\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
            body.append(NSString(format: "Content-Type: application/octet-stream\r\n\r\n").data(using: String.Encoding.utf8.rawValue)!)
            body.append(imageData!)
            body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
            
            request.httpBody = body as Data
            
            Globals.sendRequest(request: request, postParameters: nil, method: "POST", completion: {_ in}, isAsync: 1)
            
            // Add photo url to group in database
            addPhotoToGroup(groupId: id, url: "http://autocollabservice.com/images/groupPic\(id).jpg")
        }
        
        
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.state!.group?.songs = self.songs
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "searchSegue") {
            let destinationVC = segue.destination as! SongSearchViewController
            destinationVC.prevController = "ViewPlaylist"
            destinationVC.state = state
        }
        
        if (segue.identifier == "viewUsersSegue" || segue.identifier == "viewUsersAnimatedSegue") {
            let destinationVC = segue.destination as! GroupUserTableViewController
            destinationVC.state = state
        }
        
        if (segue.identifier == "myPlaylistsSegue") {
            let destinationVC = segue.destination as! UserPlaylistsTableViewController
            destinationVC.prevController = "ViewPlaylist"
            destinationVC.state = state
            self.userPlaylistVC = destinationVC
        }
        
        if (segue.identifier == "totalSongsSegue") {
            let destinationVC = segue.destination as! TotalSongsViewController
            destinationVC.viewPlaylistView = self
            destinationVC.state = state
        }
    }
    
    //MARK: - Actions
    @objc func playPauseBtnPressed(_ sender: Any) {
        if let playerState = self.state!.playerState, (self.state!.group == nil || self.state!.group?.id == self.state!.curActiveId) {
            // player is paused if we are currently playing silent track
            if (playerState.track.uri != Globals.silentTrack) {
                print(playerState.track.uri)
                updateIsPlaying(update: false)
                self.songInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            } else {
                updateIsPlaying(update: true)
                self.songInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            }
        } else {
            if (self.songs.count > 0) {
                self.state?.curActiveId = self.state!.group?.id ?? self.state?.curActiveId
                self.state!.currentActiveGroup = nil
                
                if let appRemote = self.state!.appRemote, let playerAPI = appRemote.playerAPI {
                    playSong(playerAPI: playerAPI, song: self.songs[0])
                }
            
                self.reloadSongsTable()
            }
        }
    }
    
    @objc func nextBtnPressed(_ sender: Any) {
        var group: Group!
        
        if let _ = sender as? UIButton {
            group = self.state!.group
            self.state?.curActiveId = self.state!.group?.id ?? self.state?.curActiveId
            self.state!.currentActiveGroup = nil
        } else {
            if (self.state!.group?.id == self.state!.curActiveId) {
                group = self.state!.group
            } else {
                group = self.state!.currentActiveGroup
            }
        }
        
        var curSongs = group.songs ?? [Song]()
        
        if (curSongs.count > 0) {
            curSongs.removeFirst()
            
            if let first = curSongs.first {
                if let appRemote = self.state!.appRemote, let playerAPI = appRemote.playerAPI {
                    playSong(playerAPI: playerAPI, song: first)
                }
                
            }
            
            group.songs = curSongs
            
            DispatchQueue.main.async {
                self.networkTableView?.reloadNetworkTable()
            }
            
            DispatchQueue.global().async { [unowned self] in
                var doInsert = false
                if (curSongs.count < 10) {
                    Globals.generateSongs(group: group, numSongs: 1, lastSong: curSongs.last, state: self.state!, viewPlaylistVC: nil)
                    doInsert = true
                }
                    
                Globals.addPlaylistSongs(songs: group.songs!, groupId: group.id, userId: self.state!.user.id)
                
                curSongs = group.songs!
                    
                if self.state!.curActiveId == self.state!.group?.id {
                    DispatchQueue.main.async {
                        self.songs = curSongs
                        if curSongs.count > 0 {
                            self.songsTable.beginUpdates()
                            self.songsTable.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                            if doInsert {
                                self.songsTable.insertRows(at: [IndexPath(row: self.songs.count - 1, section: 0)], with: .automatic)
                            }
                            self.songsTable.endUpdates()
                            
                            let cell = self.songsTable.cellForRow(at: IndexPath(row: 0, section: 0)) as? PlaylistSongTableViewCell
                            cell?.name.textColor = Globals.getThemeColor1()
                            cell?.artist.textColor = Globals.getThemeColor1()
                        } else {
                            self.reloadSongsTable()
                        }
                        
                        
                    }
                }
                DispatchQueue.main.async {
                    self.state!.userNetworks[group.id]?.songs = curSongs
                    self.networkTableView?.reloadNetworkTable()
                }
            }
        }
    }
    
    
    @objc func randomBtnPressed(sender: UIButton!) {
        let initialCount = self.songs.count
        randomBtn.isEnabled = false
        DispatchQueue.global().async { [unowned self] in
            var n = 10
            if self.state?.group?.id == self.state?.curActiveId {
                if let songs = self.state!.group?.songs, songs.count > 0 {
                    self.state!.group?.songs = [songs[0]]
                    n -= 1
                }
            } else {
                self.state!.group?.songs = []
            }
            
            Globals.generateSongs(group: self.state!.group, numSongs: n, lastSong: self.state!.group?.songs?.first, state: self.state!, viewPlaylistVC: nil)
            self.songs = self.state!.group?.songs ?? [Song]()
            if let id = self.state!.group?.id {
                Globals.addPlaylistSongs(songs: self.songs, groupId: id, userId: self.state!.user.id)
            }
            
            
            DispatchQueue.main.async {
                if (self.songs.count > 0) {
                    self.songsTable.beginUpdates()
                    var deletePaths = [IndexPath]()
                    var insertPaths = [IndexPath]()
                    for i in (10 - n)..<initialCount {
                        deletePaths.append(IndexPath(row: i, section: 0))
                    }
                    for i in (10 - n)..<self.songs.count {
                        insertPaths.append(IndexPath(row: i, section: 0))
                    }
                    self.songsTable.deleteRows(at: deletePaths, with: .fade)
                    self.songsTable.insertRows(at: insertPaths, with: .fade)
                    self.songsTable.endUpdates()
                } else {
                    self.updateIsPlaying(update: false)
                    self.state!.currentActiveGroup = nil
                }
                self.randomBtn.isEnabled = true
            }
        }
    }
    
    @objc func upNextBtnPressed(sender: UIButton!) {
        if (nowPlayingView.active) {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                self?.nowPlayingView.alpha = 0
                self?.randomBtn.alpha = 1
            }) { (_) in
            }
            nowPlayingView.active = false
            nowPlayingLabel.text = "Up Next"
            if let image = UIImage(named: "disc.png") {
                upNextBtn.setImage(image, for: .normal)
                upNextBtn.tintColor = Globals.getThemeColor1()
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                self?.nowPlayingView.alpha = 1
                self?.randomBtn.alpha = 0
            }) { (_) in
            }
            nowPlayingView.active = true
            nowPlayingLabel.text = "Now Playing"
            if let image = UIImage(named: "hamburger.png") {
                upNextBtn.setImage(image, for: .normal)
                upNextBtn.tintColor = Globals.getThemeColor1()
            }
        }
    }
    
    @IBAction func backBtnPressed(_ sender: Any) {
        if (self.otherUser != nil) {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.performSegue(withIdentifier: "unwindToNetworkTableFromPlaylist", sender: self)
        }
    }
    
    @IBAction func viewNetworkBtnPressed(_ sender: Any) {
        presentNetworkView(present: !self.networkShown)
    }
    
    @objc func triggerDismiss() {
        presentNetworkView(present: false)
        networkView.saveName()
    }
    
    @objc func didLeftSwipe() {
        presentNetworkView(present: true)
    }
    
    @objc func didSwipeRight() {
        backBtnPressed(self)
    }
    
    @objc func sliderValueChanged(sender: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            if (touchEvent.phase == .ended) {
                if (self.state!.playerState == nil) {
                    if let appRemote = self.state!.appRemote, let playerAPI = appRemote.playerAPI {
                        playSong(playerAPI: playerAPI, song: self.songs[0])
                    }
                }
                self.state!.appRemote?.playerAPI?.seek(toPosition: Int(sender.value), callback: nil)
            }
        }
        curPosition.text = intervalToString(time: Double(sender.value))
        self.songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(sender.value)
    }
    
    // MARK: - SPTAppRemotePlayerAPIDelegate
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        let curPlayerState = self.state!.playerState
        
        if (curPlayerState == nil || playerState.isPaused != curPlayerState!.isPaused) {
            if (playerState.isPaused) {
                self.deactivateAudioSession()
            } else {
                self.activateAudioSession()
            }
        }
        
        if (curPlayerState == nil || playerState.track.uri != curPlayerState!.track.uri) {
            songInfo[MPMediaItemPropertyPlaybackDuration] = playerState.track.duration
            MPNowPlayingInfoCenter.default().nowPlayingInfo = songInfo
            
            if (self.state!.group?.id == self.state!.curActiveId) {
                self.songLength.text = intervalToString(time: TimeInterval(playerState.track.duration))
                self.curPosition.text = "0:00"
                self.slider!.maximumValue = Float(playerState.track.duration)
            }
        }
        
        self.slider?.setValue(Float(playerState.playbackPosition), animated: true)
        self.curPosition.text = intervalToString(time: TimeInterval(playerState.playbackPosition))
        
        self.state!.playerState = playerState
    }
    
    // Handle Audio Interruption
    @objc func handleInterruption(notification: NSNotification) {
        print("handleInterruption")
        guard let value = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue,
            let interruptionType =  AVAudioSession.InterruptionType(rawValue: value)
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
    
    func load() {
        if let otherUser = self.otherUser {
            DispatchQueue.global().async { [weak self] in
                if let state = self?.state {
                    if let id = state.group?.id {
                        self?.songs = Globals.getPlaylistSongs(userId: otherUser, groupId: id, state: state)
                    }
                }
                
                DispatchQueue.main.async {
                    self?.reloadSongsTable()
                    self?.songsTable.isHidden = false
                    self?.activityIndicator?.stopAnimating()
                }
                self?.enableActions()
            }
        } else if (self.prevController == "FriendSearchWithNewGroup") {
            createNetwork()
        } else if let isJoining = self.state!.group?.isJoining, !isJoining {
            networkSetup()
        }
    }
    
    func enableActions() {
        DispatchQueue.main.async {
            self.reloadSongsTable()
            self.activityIndicator?.stopAnimating()
            
            self.networkView.searchBtn.isEnabled = true
            self.networkView.searchBtn.alpha = 1
            self.networkView.totalSongsBtn.isEnabled = true
            self.networkView.totalSongsBtn.alpha = 1
            self.networkView.viewUsersBtn.isEnabled = true
            self.networkView.viewUsersBtn.alpha = 1
            self.networkView.inviteBtn.isEnabled = true
            self.networkView.inviteBtn.alpha = 1
            self.networkView.deleteLeaveBtn.isEnabled = true
            self.networkView.deleteLeaveBtn.alpha = 1
        }
    }
    
    func networkSetup() {
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                if let id = state.group?.id {
                    
                    DispatchQueue.main.async {
                        if let users = state.group?.users, users.count > 1 {
                            self?.networkView.deleteLeaveBtn.setTitle("Leave Network", for: .normal)
                        } else {
                            self?.networkView.deleteLeaveBtn.setTitle("Delete Network", for: .normal)
                        }
                    }
                    
                    var didTimeOut = self?.didTimeOut ?? true
                    if let queueLoaded = state.group?.queueLoaded, !queueLoaded {
                        var tries = 0
                        
                        while (self?.songs == nil || self?.songs.count == 0) && tries < 10 && !didTimeOut {
                            didTimeOut = self?.didTimeOut ?? true
                            self?.songs =  Globals.getPlaylistSongs(userId: state.user.id, groupId: id, state: state)
                            
                            tries += 1
                        }                        
                    }
                    
                    if didTimeOut {
                        DispatchQueue.main.async {
                            self?.activityIndicator?.stopAnimating()
                            self?.songsTable.isHidden = true
                            self?.timeOutLabel.text = "Couldn't retrieve songs"
                            self?.didTimeOut = false
                        }
                    } else {
                        state.group?.songs = self?.songs
                        // Do in its own thread
                        Globals.updateNetwork(group: state.group, state: state)
                        state.group?.getUsers()
                        
                        Globals.getUserSongs(user: state.user, groupId: id, state: state)
                        Globals.getUserSelectedPlaylists(user: state.user, groupId: id, state: state)
                        
                        if let playlists = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.playlistsFilePath) as? [Playlist] {
                            for playlist in playlists {
                                playlist.state = state
                                if let selectedPlaylists = state.user.selectedPlaylists[id], selectedPlaylists.contains(playlist.id) {
                                    state.user.songs[id]?.append(contentsOf: playlist.getSongs()  )
                                }
                            }
                        }
                        
                        state.user.songsHasLoaded = true
                        
                        if let songsVC = state.songsVC {
                            songsVC.mySongsDidFinishLoading()
                        }
                        
                        state.group?.hasLoaded = true
                        
                        self?.enableActions()
                    }
                }
            }
        }
    }
    
    func getTotalUserSongs(groupId: Int) {
        Globals.getUserSongs(user: state!.user, groupId: groupId, state: state!)
        Globals.getUserSelectedPlaylists(user: state!.user, groupId: groupId, state: state!)
    }
    
    func createNetwork() {
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                DispatchQueue.main.async {
                    // Update Group Name
                    self?.nowPlayingLabel.text = self?.newGroupName
                    self?.networkView?.groupPicView?.image = UIImage(named: Globals.defaultPic)
                }
                
                let (groupId, inviteKey) = Globals.createGroup(userId: state.user.id)
                if groupId == -2 {
                    if let view = self?.networkTableView?.view {
                        Globals.showAlert(text: "Failed to create group", view: view)
                    }
                    
                    self?.navigationController?.popViewController(animated: true)
                    return
                }
                Globals.addGroupUsers(groupId: groupId, userIds: [state.user.id])
                let group = Group(name: self?.newGroupName, admin: state.user.id, id: groupId, picURL: nil, inviteKey: inviteKey, state: state)
                state.userNetworks[groupId] = group
                
                group?.isJoining = true
                Globals.setGroupName(name: self?.newGroupName, groupId: groupId)
                group?.getUsers()
                
                state.curCreatingGroup = group?.copy() as? Group
                
                DispatchQueue.main.async {
                    // Set netwrok view values
                    self?.networkView.nameTextField.isHidden = true
                    self?.networkView.nameLabel.text = self?.newGroupName
                    self?.networkView.deleteLeaveBtn.setTitle("Delete Network", for: .normal)
                }
                
                Globals.createGroupRequests(userIds: self?.requestsToSend, groupId: groupId, inviter: state.user.id)
                
                Globals.addUserDefaults(user: state.user, group: state.curCreatingGroup!, state: state)
                
                state.curCreatingGroup!.songs = [Song]()
                
                while (state.curCreatingGroup != nil && !state.curCreatingGroup!.totalSongsFinishedLoading) {
                }
                
                Globals.generateSongs(group: state.curCreatingGroup!, numSongs: 10, lastSong: nil, state: state, viewPlaylistVC: nil)
                Globals.addPlaylistSongs(songs: state.curCreatingGroup!.songs!, groupId: state.curCreatingGroup!.id!, userId: state.user.id)
                
                if state.group?.id == state.curCreatingGroup?.id || (!state.isAtHomeScreen && state.group == nil){
                    self?.songs = state.curCreatingGroup!.songs!
                    self?.state!.group = state.curCreatingGroup
                }
                
                if state.isAtHomeScreen {
                    group?.hasLoaded = false
                } else {
                    group?.hasLoaded = true
                }
                
                self?.enableActions()
                group?.isJoining = false
                state.viewPlaylistVC?.networkSetup()
                state.archiveGroups()
            }
        }
    }
    
    func finishedGenerating() {
        self.songs = self.state!.group?.songs ?? [Song]()

        DispatchQueue.main.async {
            self.reloadSongsTable()
            self.activityIndicator?.stopAnimating()
        }
    }
    
    func playSong(playerAPI: SPTAppRemotePlayerAPI, song: Song) {
        if let id = song.id {
            playerAPI.play("spotify:track:" + id) { [weak self] (_, error) in
                if (error == nil) {
                    print("playing!")
                    if self?.state!.group?.id == self?.state?.curActiveId {
                        self?.updatePlayPauseBtn(isPlaying: true)
                    }
                } else {
                     print("song play error: " + song.name)
                }
            }
        }
        
        nowPlayingView.setNowPlaying(song: song)
        
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
        self.state!.group?.pushToPlayedSongs(song: song)
        self.curPlaylingId = song.id
    }
    
    func updateIsPlaying(update: Bool) {
        if let playerAPI = self.state?.appRemote?.playerAPI, let curPlayingId = self.curPlaylingId {
            if (update) {
                playerAPI.play("spotify:track:" + curPlayingId, asRadio: false, callback: { [weak self] (_, error) in
                    if (error == nil), let curTrackPosition = self?.curTrackPosition {
                        playerAPI.seek(toPosition: curTrackPosition) { (_, _) in
                            self?.updatePlayPauseBtn(isPlaying: true)
                        }
                    } else {
                        print("updateIsPlaying error")
                    }
                })
            } else {
                playerAPI.getPlayerState({ [weak self] (result, error) in
                    if let playerState = result as? SPTAppRemotePlayerState {
                        // Get current position
                        self?.curTrackPosition = playerState.playbackPosition
                    } else {
                        print("updateIsPlaying: couldn't get playback position")
                    }
                    
                    // Play the silent track in spotify, we have to do this so the spotify app remains awake in the background
                    playerAPI.play(Globals.silentTrack, asRadio: false, callback: { [weak self] (_, error) in
                        if (error == nil) {
                            self?.updatePlayPauseBtn(isPlaying: false)
                        } else {
                            print("updateIsPlaying error")
                        }
                    })
                })
            }
        }
    }
    
    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: Deactivate audio session
    
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func presentNetworkView(present: Bool) {
        if (present) {
            self.dimView.isHidden = false
            UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            })
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [unowned self] in
                self.networkView?.frame = CGRect(x: self.view.frame.width/3, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { [unowned self] (finished) in
                self.songsTable.isScrollEnabled = false
                self.randomBtn.isEnabled = false
                self.playPauseBtn?.isEnabled = false
                self.nextBtn.isEnabled = false
                self.networkShown = true
                self.reloadSongsTable()
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: { [unowned self] in
                self.dimView.backgroundColor = UIColor.clear
            })
            self.dimView.isHidden = true
            
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [unowned self] in
                self.networkView?.frame = CGRect(x: self.view.frame.width, y: 0, width: 2 * self.view.frame.width/3, height: self.view.frame.height)
            }, completion: { [unowned self] (finished) in
                self.songsTable.isScrollEnabled = true
                self.randomBtn.isEnabled = true
                self.playPauseBtn?.isEnabled = true
                self.nextBtn.isEnabled = true
                self.networkShown = false
                self.reloadSongsTable()
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
    
    func updatePlayPauseBtn(isPlaying: Bool) {
        if (isPlaying) {
            if let image = UIImage(named: "pause.png") {
                playPauseBtn?.setImage(image, for: .normal)
            }
        } else {
            if let image = UIImage(named: "play.png") {
                playPauseBtn?.setImage(image, for: .normal)
            }
        }
    }
    
    func reloadSongsTable() {
        songsTable.reloadData()
        activityIndicator?.stopAnimating()
        if songs.count == 0 {
            songsTable.isHidden = true
            timeOutLabel.text = "There are no songs in this Network"
            timeOutLabel.isHidden = false
        } else {
            songsTable.isHidden = false
            timeOutLabel.isHidden = true
            nowPlayingView.setNowPlaying(song: songs.first)
        }
    }
}
