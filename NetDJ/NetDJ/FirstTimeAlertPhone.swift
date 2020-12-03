//
//  FirstTimeAlert.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 9/6/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class FirstTimeAlertPhone: UIView {
    
    var phoneNumber: UITextField!
    var submit: UIButton!
    var back: UIButton!
    var parent: NetworkTableViewController!
    var isUpdate: Bool!
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    init (frame : CGRect, parent: NetworkTableViewController, isUpdate: Bool) {
        super.init(frame: frame)
        
        self.parent = parent
        self.isUpdate = isUpdate
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
        
        let phoneLabel = UILabel(frame: CGRect(x: 0, y: 25, width: 4 *  frame.width/5, height: 70))
        phoneLabel.center.x = main.frame.midX - 10
        phoneLabel.textColor = UIColor.gray
        phoneLabel.textAlignment = .center
        phoneLabel.lineBreakMode = .byWordWrapping
        phoneLabel.numberOfLines = 3
        phoneLabel.text = "Add your phone number so your friends can find you through their contacts"
        
        phoneNumber = UITextField(frame: CGRect(x: 0, y: phoneLabel.frame.maxY + Globals.smallOffset, width: 4 * frame.width/5, height: 30))
        phoneNumber.center.x = main.frame.midX - 10
        phoneNumber.backgroundColor = UIColor.white
        phoneNumber.placeholder = "Phone Number (digits only)"
        phoneNumber.borderStyle = .roundedRect
        phoneNumber.addTarget(self, action: #selector(self.textChanged(_:)), for: .editingChanged)
        
        back = UIButton(frame: CGRect(x: 0, y: phoneNumber.frame.maxY + Globals.bigOffset, width: frame.width/2, height: 30))
        back.setTitleColor(Globals.getThemeColor1(), for: .normal)
        if isUpdate {
            back.setTitle("Cancel", for: .normal)
        } else {
            back.setTitle("Back", for: .normal)
        }
        back.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        
        submit = UIButton(frame: CGRect(x: frame.width/2 - 20, y: phoneNumber.frame.maxY + Globals.bigOffset, width: frame.width/2, height: 30))
        submit.setTitleColor(Globals.getThemeColor1(), for: .normal)
        submit.setTitle("Submit", for: .normal)
        submit.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
        submit.isEnabled = false
        submit.alpha = 0.5
        
        main.addSubview(phoneLabel)
        main.addSubview(phoneNumber)
        main.addSubview(back)
        main.addSubview(submit)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func submitPressed(sender: UIButton!) {
        if let number = phoneNumber.text {
            parent.firstTimeAlertConfirmationVC.textConfirmationCode(phoneNumber: number)
        }
        parent.firstTimeAlertPhoneSubmit()
    }
    
    @objc func backPressed(sender: UIButton!) {
        if isUpdate {
            phoneNumber.resignFirstResponder()
            parent.firstTimeAlertPhoneCancel()
        } else {
            parent.firstTimeAlertPhoneBack()
        }
        
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
