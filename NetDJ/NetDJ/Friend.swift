//
//  Friend.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/7/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class Friend {
    
    //MARK: Properties
    
    var name: String
    var picURL: String?
    var fbId: String
    var chosen: Bool
    var pic: UIImage?
    var picHasLoaded = false
    var imageView: UIImageView?
    var nameHasLoaded = false
    var nameLabel: UILabel?
    
    // MARK: Initialization
    
    init?(name: String, picURL: String?, fbId: String, state: State!) {
        
        // Check that name and artist is supplied
        if (name.isEmpty || fbId.isEmpty) {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.picURL = picURL
        self.fbId = fbId
        self.chosen = false
        self.pic = UIImage(named: Globals.defaultPic)
        
        if fbId.contains("NOID") {
            DispatchQueue.global().async { [weak self] in
                let id = String(fbId[fbId.range(of: "NOID")!.upperBound...])
                self?.picURL = Globals.getUserPic(userId: id)
                
                let userName = Globals.getUsersName(id: id, state: state) ?? name
                DispatchQueue.main.async {
                    self?.name = userName
                    self?.nameHasLoaded = true
                    self?.nameLabel?.text = self?.name
                }
                self?.getPic()
            }
            
        } else {
            nameHasLoaded = true
        }
    }
    
    func getPic() {
        DispatchQueue.global().async { [weak self] in
            if let picURL = self?.picURL {
                if let url = URL(string: picURL) {
                    if let data = try? Data(contentsOf: url) {
                        self?.pic = UIImage(data: data, scale: UIScreen.main.scale)!
                        self?.picHasLoaded = true
                        return
                    }
                }
            }
            self?.picHasLoaded = true
        }
    }
    
    func assignPicToView(imageView: UIImageView) {
        self.imageView = imageView
        imageView.image = self.pic
        if (!self.picHasLoaded) {
            DispatchQueue.global().async { [weak self] in
                var picHasLoaded = self?.picHasLoaded
                if picHasLoaded != nil {
                    while(!picHasLoaded!) {
                        picHasLoaded = self?.picHasLoaded
                        if picHasLoaded == nil {
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.1, animations: {
                            imageView.alpha = 0.0
                        }, completion: { (finished) in
                            imageView.image = self?.pic
                            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                                imageView.alpha = 1.0
                            }, completion: { (finished) in
                                return
                            })
                        })
                    }
                }
            }
        }
    }
    
    func assignNameToView(label: UILabel) {
        label.text = name
        if nameHasLoaded {
            label.text = name
        } else {
            nameLabel = label
        }
    }
}

