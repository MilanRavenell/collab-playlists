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
    @IBOutlet weak var joinBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Globals.getThemeColor2()

        self.title = "Submit Invite Key"
        self.inviteKeyTextField.placeholder = "Submit invite key"
        navigationController?.navigationBar.barTintColor = Globals.getThemeColor1()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        self.joinBtn.setTitleColor(Globals.getThemeColor1(), for: .normal)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        rightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(rightSwipeGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func joinGroup(_ sender: Any) {
        //let success = getGroupByInviteKey(inviteKey: inviteKeyTextField.text!)
//        if (success == 1) {
//            
//        }
    }
    
    // MARK: Helpers
    
    
    
    func didSwipeRight() {
        performSegue(withIdentifier: "groupSearchBackSegue", sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "groupSearchBackSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! NetworkTableViewController
            destinationVC.state = state
            destinationVC.userShown = true
        }
        if (segue.identifier == "joinGroupSegue") {
            let navVC = segue.destination as! UINavigationController
            let destinationVC = navVC.viewControllers.first as! ViewPlaylistViewController
            destinationVC.state = state
        }
    }

}
