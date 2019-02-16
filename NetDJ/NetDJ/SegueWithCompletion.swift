//
//  SegueWithCompletion.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 8/1/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class UIStoryboardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?
    
    override func perform() {
        super.perform()
        if let completion = completion {
            completion()
        }
    }
}
