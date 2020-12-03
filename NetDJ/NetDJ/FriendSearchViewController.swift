//
//  FriendSearchViewController.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/4/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit
//import FacebookCore
//import FacebookLogin
//import FBSDKLoginKit
import Contacts

class FriendSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var searchTable: UITableView!
    @IBOutlet weak var selectedTable: UITableView!
    
    var state: State?
    var searchController: UISearchController?
    var totalFriends = [Friend]()
    var friends = [Friend]()
    var selectedFriends = [Friend]()
    var prevController: String?
    var currentMembers = [String]()
    var spotifyIds = [String]()
    var labelView: UIView!
    var networkTableView: NetworkTableViewController?
    var groupName: String?
    var actionToEnable: UIAlertAction!
    var selectedHeaderLabel: UILabel!
    var contactsAccess = false
    var keyboardHeight: CGFloat = 0
    var keyboardActive = false
    var selectedActive = false
    var dimView: UIView!
    var selectedFriendsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if prevController == "NetworkTable" {
            self.title = "New Network"
            self.navigationController?.navigationItem.rightBarButtonItem?.title = "Create"
        }
        else {
            self.title = "Add Members"
            self.navigationController?.navigationItem.rightBarButtonItem?.title = "Add"
        }
        
        // Do any additional setup after loading the view.
        searchTable.dataSource = self
        searchTable.delegate = self
        searchTable.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        searchTable.rowHeight = 60
        searchTable.tableFooterView = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tableTapped))
        self.searchTable.backgroundView = UIView()
        self.searchTable.backgroundView?.addGestureRecognizer(gesture)
        searchTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: searchTable.frame.width, height: 50))
        
        let searchHeaderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: searchTable.tableHeaderView!.frame.width, height: searchTable.tableHeaderView!.frame.height))
        if /*AccessToken.current == nil*/true {
            searchHeaderLabel.text = "Search through your contacts or by Spotify Id"
        } else {
            searchHeaderLabel.text = "Search for friends by Facebook Name or Spotify Id"
        }
        
        searchHeaderLabel.textAlignment = .center
        searchHeaderLabel.textColor = UIColor.gray
        searchTable.tableHeaderView?.addSubview(searchHeaderLabel)
        
        labelView = UIView(frame: CGRect(x: 0, y: self.view.frame.height-250, width: self.view.frame.width, height: 50))
        labelView.backgroundColor = Globals.getThemeColor1()
        
        let path = UIBezierPath(roundedRect: labelView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        labelView.layer.mask = mask
        
        let labelGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectedLabelViewTapped))
        self.labelView.addGestureRecognizer(labelGesture)
        self.view.addSubview(labelView)
        
        selectedFriendsLabel = UILabel(frame: CGRect(x: 10, y: 0, width: labelView.frame.width, height: labelView.frame.height))
        selectedFriendsLabel.text = "0 Selected"
        selectedFriendsLabel.textColor = UIColor.white
        
        labelView.addSubview(selectedFriendsLabel)
        
        searchTable.reloadData()
        selectedTable.reloadData()
        
        selectedTable.dataSource = self
        selectedTable.delegate = self
        selectedTable.frame = CGRect(x: 0, y: labelView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - labelView.frame.maxY)
        selectedTable.rowHeight = 60
        selectedTable.tableFooterView = UIView()
        selectedTable.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: selectedTable.frame.width, height: 50))
        
        selectedHeaderLabel = UILabel(frame: CGRect(x: 0, y: 0, width: selectedTable.tableHeaderView!.frame.width, height: selectedTable.tableHeaderView!.frame.height))
        selectedHeaderLabel.text = "0 Selected"
        selectedHeaderLabel.textAlignment = .center
        selectedHeaderLabel.textColor = UIColor.gray
        selectedTable.tableHeaderView?.addSubview(selectedHeaderLabel)

        searchController = UISearchController(searchResultsController: nil)
        
        if Globals.useFB{
            getFriends()
        }
        
        
        if (self.prevController == "GroupUserTable") {
            if let users = self.state!.group?.users {
                currentMembers = Globals.getFbIds(users: users.map { $0.id })
            }
        }
        
        if #available(iOS 10.0, *) {
            searchController?.hidesNavigationBarDuringPresentation = false
            searchController?.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            searchController?.searchResultsUpdater = self
            searchController?.delegate = self
            searchController?.searchBar.delegate = self
            searchController?.searchBar.sizeToFit()
            self.searchTable.tableHeaderView = searchController?.searchBar
        } else {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController?.searchResultsUpdater = self
            searchController?.delegate = self
            searchController?.searchBar.delegate = self
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.searchBar.placeholder = "Search"
            searchController?.hidesNavigationBarDuringPresentation = true
            searchController?.searchBar.tintColor = UIColor.white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
        definesPresentationContext = true
        
        dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        dimView.alpha = 0
        dimView.isUserInteractionEnabled = false
        
        self.view.addSubview(dimView)
        
        self.view.bringSubviewToFront(selectedTable)
        self.view.bringSubviewToFront(labelView)
        
        searchContacts(query: "")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async { [weak self] in
            self?.searchController?.searchBar.becomeFirstResponder()
        }
        
        checkContactAccess()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc func keyboardWillAppear(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight = keyboardFrame.cgRectValue.height
        }
        keyboardActive = true
        animateSelectedUser(show: false)
    }
    
    @objc func keyboardWillDisappear(_ notification: Notification) {
        keyboardActive = false
        if !selectedActive {
            animateSelectedUser(show: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func networkNamePrompt() {
        if (self.prevController == "NetworkTable") {
            let alert = UIAlertController(title: "Give a name to your Network", message: "", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "Network Name"
                textField.addTarget(self, action: #selector(self.textChanged(_:)), for: .editingChanged)
            }
            
            let save = UIAlertAction(title: "Submit", style: .default, handler: { [weak alert, weak self] (_) in
                let textField = alert?.textFields![0]
                self?.groupName = textField?.text
                self?.title = textField?.text
            })
            
            alert.addAction(save)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            }))
            
            self.actionToEnable = save
            save.isEnabled = false
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func checkContactAccess() {
        let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        // Find out what access level we have currently
        switch status {
        case .authorized:
            contactsAccess = true
            networkNamePrompt()
        case .denied:
            contactsAccess = false
            networkNamePrompt()
        case .notDetermined:
            CNContactStore().requestAccess(for: CNEntityType.contacts, completionHandler: { [weak self] (access, accessError) -> Void in
                if access {
                    self?.contactsAccess = true
                }
                else {
                    self?.contactsAccess = false
                }
                DispatchQueue.main.async {
                    self?.networkNamePrompt()
                }
            })
        default:
            contactsAccess = false
            networkNamePrompt()
        }
    }
    
    @objc func textChanged(_ sender: UITextField) {
        self.actionToEnable?.isEnabled  = (sender.text!.count > 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.searchTable) {
            return self.friends.count
        }
        return self.selectedFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView == self.searchTable) {
            let cellIdentifier = "FriendSearchTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? FriendSearchTableViewCell else{
                fatalError("It messed up")
            }
            
            cell.backgroundColor = UIColor.clear
            
            // Fetches the appropriate song
            let friend = self.friends[indexPath.row]
            if !friend.fbId.contains("NOID") {
                friend.getPic()
            }
            
            let profPicView = UIImageView(frame: CGRect(x: 10, y: 10, width: 50, height: cell.frame.height - 20))
            Globals.roundAllCorners(imageView: profPicView)
            print("search: \(cell.frame.height)")
            cell.addSubview(profPicView)
            
            friend.assignPicToView(imageView: profPicView)
            friend.assignNameToView(label: cell.nameLabel)
            
            if (self.currentMembers.contains(friend.fbId)) {
                cell.nameLabel.textColor = Globals.getThemeColor1()
            } else {
                cell.nameLabel.textColor = UIColor.black
            }
            
            
            return cell
        } else {
            let cellIdentifier = "SelectedFriendsTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SelectedFriendsTableViewCell else{
                fatalError("It messed up")
            }
            
            cell.backgroundColor = UIColor.clear
            
            // Fetches the appropriate song
            let friend = self.selectedFriends[indexPath.row]
            if !friend.fbId.contains("NOID") {
                friend.getPic()
            }
            
            let profPicView = UIImageView(frame: CGRect(x: 10, y: 10, width: 50, height: cell.frame.height - 20))
            Globals.roundAllCorners(imageView: profPicView)
            print("selected: \(cell.frame.height)")
            
            cell.addSubview(profPicView)
            friend.assignPicToView(imageView: profPicView)
            friend.assignNameToView(label: cell.nameLabel)
            
            let delete_Button = UIButton(type: .system)
            delete_Button.setTitle("Delete", for: .normal)
            delete_Button.setTitleColor(UIColor.red, for: .normal)
            delete_Button.frame = CGRect(x: self.view.frame.size.width-100, y: 0, width: 100, height: cell.frame.height)
            delete_Button.addTarget(self, action: #selector(deleteBtnPressed), for: .touchUpInside)
            delete_Button.tag = indexPath.row
            cell.addSubview(delete_Button)

            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (tableView == self.searchTable) {
            // Fetches the appropriate song
            let friend = self.friends[indexPath.row]
            
            var selectedIds = [String]()
            for selectedFriend in selectedFriends {
                selectedIds.append(selectedFriend.fbId)
            }
            
            if (selectedIds.contains(friend.fbId)) {
                var indx = self.currentMembers.index(where: { (item) -> Bool in
                    item == friend.fbId
                })
                if (indx != nil) {
                    self.currentMembers.remove(at: indx!)
                }
                
                indx = self.selectedFriends.index(where: { (item) -> Bool in
                    item.fbId == friend.fbId
                })
                if (indx != nil) {
                    self.selectedFriends.remove(at: indx!)
                }
            } else if self.currentMembers.contains(friend.fbId) {
                Globals.showAlert(text: "Already in the group", view: self.view)
                return
            } else {
                self.selectedFriends.append(friend)
                self.friends[indexPath.row].chosen = true
                self.currentMembers.append(friend.fbId)
            }
        }
        selectedHeaderLabel.text = String(self.selectedFriends.count) + " Selected"
        selectedFriendsLabel.text = String(self.selectedFriends.count) + " Selected"
        
        self.selectedTable.reloadData()
        self.searchTable.reloadData()
    }
    
    @objc func tableTapped() {
        self.searchController?.searchBar.resignFirstResponder()
        self.searchController?.isActive = false
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(getResults), object: nil)
        self.perform(#selector(getResults), with: nil, afterDelay: 0.5)
    }
    
    @objc func getResults() {
        if let query = searchController?.searchBar.text {
            self.friends = filterFriends(query: query)
            self.searchTable.reloadData()
            searchSpotifyId()
            if contactsAccess {
                searchContacts(query: query)
            }
        }
        
    }
    
    func searchSpotifyId() {
        
        if searchController!.searchBar.text!.contains(self.state!.user.id) { return }
        
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusersbyquery")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "query=" + searchController!.searchBar.text!
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { [weak self] (response) in
            let responseDict = response as? [AnyObject]
            
            if (responseDict == nil) {
                print("No Users")
                return
            }
            
            for user in responseDict! {
                if let user = user as? [AnyObject] {
                    let name = user[5] as? String ?? ""
                    let picURL = user[4] as? String ?? ""
                    let userId = user[0] as? String ?? ""
                    if let state = self?.state, userId != state.user.id {
                        let friend = Friend(name: name, picURL: picURL, fbId: "NOID" + userId, state: state)
                        self?.friends.append(friend!)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.searchTable.reloadData()
            }
        }, isAsync: 1)
    }
    
    func searchContacts(query: String) {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey, CNContactPhoneNumbersKey]
        let contactsStore = CNContactStore()
        var phoneNumbers = [String]()
        
        do {
            try contactsStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])) { (contact, cursor) in
                let name = contact.givenName + " " + contact.familyName
                if name.lowercased().contains(query.lowercased()) || query == "" {
                    for phoneNumber in contact.phoneNumbers {
                        var numberString = phoneNumber.value.stringValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
                        if numberString.count > 10 {
                            let _ = numberString.removeFirst()
                        }
                        print(numberString)
                        if !phoneNumbers.contains(numberString) {
                            phoneNumbers.append(numberString)
                        }
                    }
                }
            }
        }
        catch {
            print("Unable to fetch contacts.")
        }
        
        getUsersByPhoneNumber(numbers: phoneNumbers)
    }
    
    //MARK: - Actions
    @IBAction func saveBtnPressed(_ sender: Any) {
        self.spotifyIds = getSpotifyIdsFromFB(friends: self.selectedFriends)
        if (prevController == "NetworkTable") {
            performSegue(withIdentifier: "unwindToNetworkTableSegue", sender: self)
        } else {
            performSegue(withIdentifier: "unwindToGroupUserSegue", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "saveFriendsToPlaylistSegue") {
            let destinationVC = segue.destination as! ViewPlaylistViewController
            destinationVC.state = state
            if (self.prevController == "NetworkTable") {
                destinationVC.prevController = "FriendSearchWithNewGroup"
                destinationVC.networkTableView = self.networkTableView
                destinationVC.newGroupName = self.groupName
                destinationVC.requestsToSend = self.spotifyIds
            }
        }
    }
    
    // MARK: Helpers
    
    func getFriends() {
        if /*AccessToken.current == nil*/true {
            return
        }
        
//        var responseFriends = [Friend]()
//        
//        let params = ["fields": "id, first_name, last_name, profile_pic"]
//        
//        let connection = GraphRequestConnection()
//        let graphrequest = CNSaveRequest(graphPath: "/" + AccessToken.current!.userId! +  "/friends", parameters: params, accessToken: AccessToken.current, httpMethod: .GET, apiVersion: .defaultVersion)
//        
//        connection.add(graphrequest) { [weak self] httpResponse, result in
//            switch result {
//            case .success(let response):
//                let data = response.dictionaryValue!["data"] as? [[String: AnyObject]]
//                if (data != nil) {
//                    for friend in data! {
//                        let first = friend["first_name"] as! String
//                        let last = friend["last_name"] as! String
//                        let fbId = friend["id"] as! String
//                        // Figure out how the picture is formatted
//                        let picURL = friend["profile_picture"] as! String
//                        responseFriends.append(Friend(name: first + last, picURL: picURL, fbId: fbId, state: self?.state)!)
//                    }
//                }
//                self?.totalFriends = responseFriends
//            case .failed(let error):
//                print("Graph Request Failed: \(error)")
//            }
//        }
//        connection.start()
    }
    
    func filterFriends(query: String) -> [Friend] {
        let friends = self.totalFriends.filter({( friend : Friend) -> Bool in
            return friend.name.lowercased().contains(query.lowercased())
        })
        return friends
    }
    
    @objc func deleteBtnPressed(sender: UIButton!) {
        let friend = self.selectedFriends[sender.tag]
        self.selectedFriends.remove(at: sender.tag)
        self.selectedHeaderLabel.text = String(self.selectedFriends.count) + " Selected"
        selectedFriendsLabel.text = String(self.selectedFriends.count) + " Selected"
        
        let indx = self.currentMembers.index(where: { (item) -> Bool in
            item == friend.fbId
        })
        if (indx != nil) {
            self.currentMembers.remove(at: indx!)
        }
        self.selectedTable.reloadData()
        self.searchTable.reloadData()
    }
    
    func getSpotifyIdsFromFB(friends: [Friend]) -> [String] {
        
        var fbIds = ""
        var ids = [String]()
        
        for friend in friends {
            if (friend.fbId.contains("NOID")) {
                ids.append(String(friend.fbId[friend.fbId.range(of: "NOID")!.upperBound...]))
            }
            fbIds += friend.fbId
            fbIds += "///"
        }
        if (friends.count > 0) {
            fbIds.removeLast(3)
        }
        
        let requestURL = URL(string: "http://autocollabservice.com/getspotifyidsfromfb")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "fbIds=" + fbIds
        
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            let responseIds = response as? [String]
            if (responseIds != nil) {
                ids.append(contentsOf: responseIds!)
            }
        },isAsync: 0)
        
        return ids
    }
    
    // stage 0: top of screen
    // stage 1: top of keyboard
    // stage 2: bottom of screen
    func animateSelectedUser(show: Bool) {
        if show {
            selectedActive = true
            searchTable.allowsSelection = false
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                if let vc = self {
                    vc.labelView.frame = CGRect(x: 0, y: 130, width: vc.view.frame.width, height: 50)
                    vc.selectedTable.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                    vc.dimView.alpha = 1
                }
            }, completion: { (finished) in
                return
            })
        } else {
            searchTable.allowsSelection = true
            selectedActive = false
            if keyboardActive {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                    if let vc = self {
                        vc.labelView.frame = CGRect(x: 0, y: vc.view.frame.height - vc.keyboardHeight - 50, width: vc.view.frame.width, height: 50)
                        vc.selectedTable.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                        vc.dimView.alpha = 0
                    }
                    }, completion: { (finished) in
                        return
                })
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: { [weak self] in
                    if let vc = self {
                        vc.labelView.frame = CGRect(x: 0, y: vc.view.frame.height-50, width: vc.view.frame.width, height: 50)
                        vc.selectedTable.frame = CGRect(x: 0, y: vc.labelView.frame.maxY, width: vc.view.frame.width, height: vc.view.frame.height - vc.labelView.frame.maxY)
                        vc.dimView.alpha = 0
                    }
                    }, completion: { (finished) in
                        return
                })
            }
        }
    }
    
    func getUsersByPhoneNumber(numbers: [String]) {
        //created NSURL
        let requestURL = URL(string: "http://autocollabservice.com/getusersbyphonenumber")
        
        //creating NSMutableURLRequest
        let request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        let postParameters = "phoneNumbers=" + numbers.joined(separator: "///")
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { [weak self] (response) in
            let responseDict = response as? [AnyObject]
            
            if (responseDict == nil) {
                print("No Users")
                return
            }
            
            for user in responseDict! {
                if let user = user as? [AnyObject] {
                    let name = user[5] as? String ?? ""
                    let picURL = user[4] as? String ?? ""
                    let userId = user[0] as? String ?? ""
                    if let state = self?.state, userId != state.user.id {
                        let friend = Friend(name: name, picURL: picURL, fbId: "NOID" + userId, state: state)
                        self?.friends.append(friend!)
                    }
                }
            }
            
            if let friends = self?.friends {
                self?.friends = friends.sorted { $0.name < $1.name }
            }
            
            DispatchQueue.main.async {
                self?.searchTable.reloadData()
            }
        }, isAsync: 1)
    }
    
    func getUserBySpotifyId(id: String) {
        
        var name: String?
        var picURL: String?
        
        //created NSURL
        var requestURL = URL(string: "http://autocollabservice.com/getdisplayname")
        
        //creating NSMutableURLRequest
        var request = NSMutableURLRequest(url: requestURL!)
        
        //creating the post parameter by concatenating the keys and values from text field
        var postParameters = "spotifyIds=" + id
        
        Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { (response) in
            name = response as? String
            
            if let name = name {
                requestURL = URL(string: "http://autocollabservice.com/getuserpic")
                
                //creating NSMutableURLRequest
                request = NSMutableURLRequest(url: requestURL!)
                
                //creating the post parameter by concatenating the keys and values from text field
                postParameters = "spotifyId=" + id
                
                Globals.sendRequest(request: request, postParameters: postParameters, method: "POST", completion: { [weak self] (response) in
                    picURL = response as? String ?? Globals.defaultPic
                    if let state = self?.state {
                        let friend = Friend(name: name, picURL: picURL, fbId: "NOID" + id,  state: state)
                        self?.friends.append(friend!)
                        DispatchQueue.main.async {
                            self?.searchTable.reloadData()
                        }
                    }
                }, isAsync: 1)
            }
        }, isAsync: 1)
    }
    
    @objc func selectedLabelViewTapped() {
        if selectedActive {
            animateSelectedUser(show: false)
        } else {
            animateSelectedUser(show: true)
        }
    }
}
