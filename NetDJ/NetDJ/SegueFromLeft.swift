//
//  SegueFromLeft.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/17/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

// COPIED FROM STACK OVERFLOW - https://stackoverflow.com/questions/30763519/ios-segue-left-to-right
class SegueFromLeft: UIStoryboardSegue
{
    override func perform()
    {
        let src = self.source
        let dst = self.destination
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)
        
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(dst.view, aboveSubview: src.view)
        
        UIView.animate(withDuration: 0.2,
                                   delay: 0.0,
                                   options: .curveEaseOut,
                                   animations: {
                                    dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        },
                                   completion: { finished in
                                        src.present(dst, animated: false, completion: nil)
                                    }
        )
    }
}
