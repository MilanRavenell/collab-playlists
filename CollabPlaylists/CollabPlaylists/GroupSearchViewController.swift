//
//  GroupSearchViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 6/5/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class GroupSearchViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var inviteKeyTextField: UITextField!
    var state: State?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func joinGroup(_ sender: Any) {
        
        let success = getGroupByInviteKey(inviteKey: inviteKeyTextField.text!)
        if (success == 1) {
            RequestWrapper.addGroupUser(groupId: self.state!.group!.id, userId: self.state!.userId)
            state!.group?.users?.append(self.state!.userId)
            
            // Add songs to the user
            RequestWrapper.addUserSongs(songs: self.state!.topSongs, userId: self.state!.userId, groupId: self.state!.group!.id, isTop: 1)
            
            performSegue(withIdentifier: "joinGroupSegue", sender: self)
        }
    }
    
    // MARK: Helpers
    
    func getGroupByInviteKey(inviteKey: String) -> Int{
        
        var success: Int?
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getgroups")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "method=invite&inviteKey=" + inviteKey
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
            do {
                //converting resonse to NSDictionary
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String: AnyObject]]
                
                //parsing the json
                if let result = myJSON {
                    if result.count == 0 {
                        success = 0
                    } else {
                        let group = result.first!
                        let name = group["name"] as? String
                        let admin = group["admin"] as! String
                        let id = group["id"] as! Int
                        let activated = group["activated"] as! Bool
                        let inviteKey = group["invite_key"] as! String
                        self.state!.group = Group(name: name, admin: admin, id: id, activated: activated, users:[], inviteKey: inviteKey)
                        success = 1
                    }
                }
            } catch {
                NSLog("\(error)")
            }
            semaphore.signal()
        }
        //executing the task
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        self.state!.group?.users = RequestWrapper.getGroupUsers(id: self.state!.group!.id)
        return success!
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "groupSearchBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! EventTableViewController
            destinationVC.state = state
        }
        if (segue.identifier == "joinGroupSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! GroupViewController
            destinationVC.state = state
        }
    }

}
