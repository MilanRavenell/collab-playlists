//
//  UserPlaylistsTableViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/9/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class UserPlaylistsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    var state: State?
    var playlists = [Playlist]()
    var startingPlaylists = [String]()
    var selectedPlaylists = [Playlist]()
    var prevController: String?
    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView?
    var emptyLabel: UILabel?
    var retryBtn: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Your Playlists"
        
        self.state!.userPlaylistVC = self
        
        self.tableView.reloadData()
        self.tableView.tableFooterView = UIView()
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator?.center = self.view.center
        self.view.addSubview(activityIndicator!)
        
        emptyLabel = UILabel(frame: self.view.frame)
        emptyLabel?.text = "You have no Spotify playlists"
        emptyLabel?.textColor = UIColor.gray
        emptyLabel?.textAlignment = .center
        emptyLabel?.isHidden = true
        self.view.addSubview(emptyLabel!)
        
        retryBtn = UIButton(frame: CGRect(x: view.frame.minX, y: view.frame.minY+25, width: view.frame.width, height: view.frame.height))
        retryBtn?.setTitle("Retry", for: .normal)
        retryBtn?.setTitleColor(Globals.getThemeColor1(), for: .normal)
        retryBtn?.addTarget(self, action: #selector(retry), for: .touchUpInside)
        retryBtn?.isHidden = true
        self.view.addSubview(retryBtn!)
        
        activityIndicator?.startAnimating()
        
        if let id = self.state!.group?.id, self.state!.user.selectedPlaylists[id] != nil {
            configurePlaylists()
        }
        
        
        if (self.state?.group == nil) {
            performSegue(withIdentifier: "userPlaylistBackToTableSegue", sender: self)
        }
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.tableView.addGestureRecognizer(rightSwipeGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
     
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if let id = self?.state?.group?.id {
                if self?.state!.user.selectedPlaylists[id] == nil {
                    self?.tableView.isHidden = true
                    self?.emptyLabel?.isHidden = false
                    self?.emptyLabel?.text = "Error retrieving playlists"
                    self?.activityIndicator?.stopAnimating()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return playlists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserPlaylistsTableViewCell", for: indexPath) as? UserPlaylistsTableViewCell else {
            fatalError("It messed up")
        }
        
        cell.backgroundColor = UIColor.clear
        
        let playlist = playlists[indexPath.row]
        
        // Configure the cell...
        cell.nameLabel.text = playlist.name
        if (playlist.selected) {
            cell.nameLabel.textColor = Globals.getThemeColor1()
        } else {
            cell.nameLabel.textColor = UIColor.black
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let playlist = playlists[indexPath.row]
        if let id = self.state!.group?.id {
            if playlist.selected {
                playlist.selected = false
                if let indx = self.state!.user.selectedPlaylists[id]?.index(of: playlist.id) {
                    self.state!.user.selectedPlaylists[id]?.remove(at: indx)
                }
            } else {
                playlist.selected = true
                self.state!.user.selectedPlaylists[id]?.append(playlist.id)
            }
        }
        self.tableView.reloadData()
    }
    
    func didSwipeRight() {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func backBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindToSongViewFromUserPlaylistSegue", sender: self)
//        if self.prevController == "User" {
//            performSegue(withIdentifier: "uniwindToNetworkFromUserPlaylistSegue", sender: self)
//        } else {
//            performSegue(withIdentifier: "unwindToViewPlayslitSegue", sender: self)
//        }
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        if let id = state!.group?.id {
            state!.user.selectedPlaylists[id] = startingPlaylists
            navigationController?.popViewController(animated: true)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let destinationVC = segue.destination as? ViewPlaylistViewController {
            destinationVC.state = self.state
        }
        if let destinationVC = segue.destination as? NetworkTableViewController {
            destinationVC.state = self.state
        }
    }
    
    // MARK: Helpers
    func configurePlaylists() {
        playlists = []
        if let savedPlaylists = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.playlistsFilePath) as? [Playlist] {
            if let id = self.state!.group?.id {
                if self.state!.user.selectedPlaylists[id] != ["ERROR"] {
                    if savedPlaylists.count == 0 {
                        DispatchQueue.main.async { [weak self] in
                            self?.playlists = [Playlist]()
                            self?.tableView.reloadData()
                            self?.emptyLabel?.text = "You have no Spotify playlists"
                            self?.emptyLabel?.isHidden = false
                            self?.activityIndicator?.stopAnimating()
                        }
                    } else {
                        for playlist in savedPlaylists {
                            playlist.state = self.state!
                            if (self.state!.user.selectedPlaylists[id]!.contains(playlist.id)) {
                                playlist.selected = true
                                startingPlaylists.append(playlist.id)
                            } else {
                                playlist.selected = false
                            }
                            playlists.append(playlist)
                        }
                        DispatchQueue.main.async { [weak self] in
                            self?.tableView.reloadData()
                            self?.activityIndicator?.stopAnimating()
                            self?.emptyLabel?.isHidden = true
                            self?.retryBtn?.isHidden = true
                        }
                    }
                    return
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.playlists = [Playlist]()
            self?.tableView.reloadData()
            self?.emptyLabel?.text = "Could not get your playlists"
            self?.emptyLabel?.isHidden = false
            self?.activityIndicator?.stopAnimating()
            self?.retryBtn?.isHidden = false
        }
    }
    
    func retry() {
        retryBtn?.isHidden = true
        emptyLabel?.isHidden = true
        activityIndicator?.startAnimating()
        
        DispatchQueue.global().async { [weak self] in
            if let state = self?.state {
                let savedPlaylists = NSKeyedUnarchiver.unarchiveObject(withFile: Globals.playlistsFilePath) as? [Playlist]
                if savedPlaylists == nil {
                    state.user.getPlaylists(state: state)
                }
                if let id = state.group?.id {
                    if state.user.selectedPlaylists[id] == ["ERROR"] {
                        Globals.getUserSelectedPlaylists(user: state.user, groupId: id, state: state)
                    }
                }
                self?.configurePlaylists()
            }
        }
    }
    
    func selectedPlaylistsDidLoad() {
        self.configurePlaylists()
    }
}
