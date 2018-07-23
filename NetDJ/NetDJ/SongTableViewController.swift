//
//  SongTableViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class SongTableViewController: UITableViewController {
    
    //MARK: Properties
    var songs = [Song]()
    var state: State?
    var prevController: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Songs"
        self.tableView.reloadData()
        self.tableView.backgroundColor = Globals.getThemeColor2()
        
        if (self.state!.user.songs[self.state!.group!.id]!.count == 0) {
            self.tableView.isHidden = true
            self.tableView.backgroundView = UIView(frame: self.view.frame)
            self.tableView.backgroundView?.backgroundColor = Globals.getThemeColor2()
            let emptyLabel = UILabel(frame: self.view.frame)
            emptyLabel.text = "Add some songs!"
            emptyLabel.textColor = UIColor.gray
            self.tableView.backgroundView?.addSubview(emptyLabel)
        }
        
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return self.state!.user.songs[self.state!.group!.id]!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        if (song.albumCover != nil) {
            let url = URL(string: song.albumCover!)
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    albumCover.image = UIImage(data: data!)
                }
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
        delete_Button.addTarget(self, action: #selector(SongTableViewController.deleteBtnPressed), for: .touchUpInside)
        delete_Button.tag = indexPath.row
        cell.addSubview(delete_Button)
        
        return cell
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
        self.tableView.reloadData()
        
        Globals.deleteUserSong(id: song.id, userId: self.state!.user.id, groupId: self.state!.group!.id)
        Globals.updateNetworkAsync(groupId: self.state!.group!.id, add_delete: 1, user: self.state!.user.id, songs: [song])
    }
}
