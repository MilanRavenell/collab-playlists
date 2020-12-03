//
//  FirstTimeAlert.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 9/6/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class FirstTimeAlertName: UIView {

    var displayName: UITextField!
    var submit: UIButton!
    var parent: NetworkTableViewController!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    init (frame : CGRect, parent: NetworkTableViewController) {
        super.init(frame: frame)
        
        self.parent = parent
        
        self.backgroundColor = Globals.getThemeColor1()
        
        var path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
        var mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        
        let main = UIView(frame: CGRect(x: 2, y: 2, width: frame.width - 4, height: frame.height - 4))
        main.backgroundColor = UIColor.white
        self.addSubview(main)
        
        path = UIBezierPath(roundedRect: main.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 10, height: 10))
        mask = CAShapeLayer()
        mask.path = path.cgPath
        main.layer.mask = mask
        
        let nameLabel = UILabel(frame: CGRect(x: 25, y: 25, width: 4 *  frame.width/5, height: 30))
        nameLabel.center.x = main.frame.midX - 10
        nameLabel.textColor = UIColor.gray
        nameLabel.textAlignment = .center
        nameLabel.text = "Choose your Nickname"
        
            
        displayName = UITextField(frame: CGRect(x: 0, y: nameLabel.frame.maxY + Globals.smallOffset, width: 4 *  frame.width/5, height: 30))
        
        displayName.center.x = main.frame.midX - 10
        displayName.backgroundColor = UIColor.white
        displayName.borderStyle = .roundedRect
        displayName.placeholder = "Nickname"
        displayName.addTarget(self, action: #selector(self.textChanged(_:)), for: .editingChanged)
        displayName.becomeFirstResponder()
        
        submit = UIButton(frame: CGRect(x: 0, y: displayName.frame.maxY + Globals.bigOffset, width: frame.width, height: 30))
        submit.center.x = main.frame.midX - 10
        submit.setTitleColor(Globals.getThemeColor1(), for: .normal)
        submit.setTitle("Next", for: .normal)
        submit.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
        submit.isEnabled = false
        submit.alpha = 0.5
        
        main.addSubview(nameLabel)
        main.addSubview(displayName)
        main.addSubview(submit)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func submitPressed(sender: UIButton!) {
        self.parent.firstTimeAlertNameSubmit()
    }
    
    @objc func textChanged(_ sender: UITextField) {
        if sender.text!.count > 0 {
            submit.isEnabled  = true
            submit.alpha = 1
        } else {
            submit.isEnabled  = false
            submit.alpha = 0.5
        }
    }
}
