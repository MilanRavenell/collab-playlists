//
//  FirstTimeAlertConfirmation.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 2/9/19.
//  Copyright © 2019 Ravenell, Milan. All rights reserved.
//

import UIKit
import MessageUI

class FirstTimeAlertConfirmation: UIView {
    
    var confirmationCodeTextField: UITextField!
    var submit: UIButton!
    var back: UIButton!
    var parent: NetworkTableViewController!
    var confirmationCode: String!
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
        
        confirmationCode = Globals.randomString(length: 6)
        
        let confirmationLabel = UILabel(frame: CGRect(x: 0, y: 25, width: 4 *  frame.width/5, height: 70))
        confirmationLabel.center.x = main.frame.midX - 10
        confirmationLabel.textColor = UIColor.gray
        confirmationLabel.textAlignment = .center
        confirmationLabel.lineBreakMode = .byWordWrapping
        confirmationLabel.numberOfLines = 3
        confirmationLabel.text = "We just sent you a text, enter in the confirmation code"
        
        confirmationCodeTextField = UITextField(frame: CGRect(x: 0, y: confirmationLabel.frame.maxY + Globals.smallOffset, width: 4 * frame.width/5, height: 30))
        confirmationCodeTextField.center.x = main.frame.midX - 10
        confirmationCodeTextField.backgroundColor = UIColor.white
        confirmationCodeTextField.placeholder = "Confirmation Code"
        confirmationCodeTextField.borderStyle = .roundedRect
        confirmationCodeTextField.addTarget(self, action: #selector(self.textChanged(_:)), for: .editingChanged)
        
        back = UIButton(frame: CGRect(x: 0, y: confirmationCodeTextField.frame.maxY + Globals.bigOffset, width: frame.width/2, height: 30))
        back.setTitleColor(Globals.getThemeColor1(), for: .normal)
        back.setTitle("Back", for: .normal)
        back.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        
        submit = UIButton(frame: CGRect(x: frame.width/2 - 20, y: confirmationCodeTextField.frame.maxY + Globals.bigOffset, width: frame.width/2, height: 30))
        submit.setTitleColor(Globals.getThemeColor1(), for: .normal)
        submit.setTitle("Submit", for: .normal)
        submit.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
        submit.isEnabled = false
        submit.alpha = 0.5
        
        main.addSubview(confirmationLabel)
        main.addSubview(confirmationCodeTextField)
        main.addSubview(back)
        main.addSubview(submit)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textConfirmationCode(phoneNumber: String) {
        print("No text service yet")
    }
    
    func submitPressed(sender: UIButton!) {
        confirmationCodeTextField.resignFirstResponder()
        parent.firstTimeAlertConfirmationSubmit()
    }
    
    func backPressed(sender: UIButton!) {
        parent.firstTimeAlertConfirmationBack()
    }
    
    func textChanged(_ sender: UITextField) {
        if sender.text!.count > 0 {
            submit.isEnabled  = true
            submit.alpha = 1
        } else {
            submit.isEnabled  = false
            submit.alpha = 0.5
        }
    }
}
