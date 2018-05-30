//
//  CreateEventViewController.swift
//  CollabPlaylists
//
//  Created by Ravenell, Milan on 3/24/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class CreateEventViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var eventName: UITextField!
    var userId : String?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            return
        }
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/createevent")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //setting the method to post
        request.httpMethod = "POST"
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "name=" + eventName.text! + "&eventId=" + self.userId!
        
        //adding the parameters to request body
        request.httpBody = postParameters.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){
            data, response, error in
            
            if error != nil{
                print("error is \(String(describing: error))")
                return;
            }
            
        }
        //executing the task
        task.resume()
        
    }
}
