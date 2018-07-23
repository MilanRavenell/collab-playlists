//
//  SongsViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/16/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SongsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: Properties
    @IBOutlet weak var songsTable: UITableView!
    var songs = [Song]()
    var state: State?
    var prevController: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Globals.getThemeColor2()
        self.title = "Your Songs"
        self.songsTable.backgroundColor = Globals.getThemeColor2()
        self.songsTable.frame = self.view.frame
        self.songsTable.rowHeight = 90
        songsTable.dataSource = self
        self.songsTable.delegate = self
        
        if (self.state!.user.songs[self.state!.group!.id]!.count == 0) {
            self.songsTable.isHidden = true
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "Add some songs!"
            emptyLabel.textColor = UIColor.gray
            emptyLabel.textAlignment = .center
            self.view.addSubview(emptyLabel)
        }
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.songsTable.addGestureRecognizer(rightSwipeGesture)
        self.view.addGestureRecognizer(rightSwipeGesture)
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
        
        return self.state!.user.songs[self.state!.group!.id]!.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SongTableViewCell else{
            fatalError("It messed up")
        }
        NSLog("Begin")
        
        let albumCover = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: cell.frame.height))
        cell.addSubview(albumCover)
        
        cell.backgroundColor = UIColor.clear
        
        // Fetches the appropriate song
        let song = self.state!.user.songs[self.state!.group!.id]![indexPath.row]
        
        if (song.imageURL != nil) {
            let url = URL(string: song.imageURL!)
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    albumCover.image = UIImage(data: data!)
                }
            }
        }
        
        if (song.image != nil) {
            albumCover.image = song.image
        } else {
            if (song.imageURL != nil) {
                let url = URL(string: song.imageURL!)
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    DispatchQueue.main.async {
                        song.image = UIImage(data: data!)!
                        albumCover.image = song.image
                        self.state?.user.songs[self.state!.group!.id]![indexPath.row].image = song.image
                    }
                }
            } else {
                albumCover.image = UIImage(named: Globals.defaultPic)
            }
        }
        
        cell.songName.text = song.name
        cell.songArtist.text = song.artist
        cell.songArtist.font = cell.songArtist.font.withSize(15)
        
        // Add delete Button
        let delete_Button = UIButton(type: .system)
        delete_Button.setTitle("Delete", for: .normal)
        delete_Button.setTitleColor(UIColor.red, for: .normal)
        delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: 90)
        delete_Button.addTarget(self, action: #selector(SongsViewController.deleteBtnPressed), for: .touchUpInside)
        delete_Button.tag = indexPath.row
        cell.addSubview(delete_Button)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    func didSwipeRight() {
        backBtnPressed(self)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "addSongSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! SongSearchViewController
            destinationVC.prevController = prevController
            destinationVC.state = state
        }
        
        if (segue.identifier == "songTableBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.state = state
            destinationVC.networkShown = true
        }
        
        if (segue.identifier == "songTableBackToTableSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            self.state!.group = nil
            destinationVC.state = state
            destinationVC.userShown = true
        }
    }
    
    // MARK: Actions
    @IBAction func backBtnPressed(_ sender: Any) {
        if (prevController == "ViewPlaylist") {
            performSegue(withIdentifier: "songTableBackSegue", sender: self)
        }
        if (prevController == "User") {
            performSegue(withIdentifier: "songTableBackToTableSegue", sender: self)
        }
    }
    
    func deleteBtnPressed(sender: UIButton!) {
        let song = self.state!.user.songs[self.state!.group!.id]![sender.tag]
        self.state!.user.songs[self.state!.group!.id]!.remove(at: sender.tag)
        self.songsTable.reloadData()
        
        Globals.deleteUserSongs(songs: [song], userId: self.state!.user.id, groupId: self.state!.group!.id)
        Globals.updateNetworkAsync(groupId: self.state!.group!.id, add_delete: 1, user: self.state!.user.id, songs: [song])
        
        if (self.state!.user.songs[self.state!.group!.id]!.count == 0) {
            self.songsTable.isHidden = true
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "Add some songs!"
            emptyLabel.textColor = UIColor.gray
            emptyLabel.textAlignment = .center
            self.view.addSubview(emptyLabel)
        }
    }
}
