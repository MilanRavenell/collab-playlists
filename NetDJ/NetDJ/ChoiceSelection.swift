//
//  ChoiceSelection.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 10/7/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class ChoiceSelection: UIView {

    var choices: [(String, String, (() -> Void)?)]!
    var height: CGFloat!
    var targetY: CGFloat!
    var view: UIView!
    var dimView: UIView!
    var buttonViewHeight:CGFloat = 50
    
    init (titleView: UIView, choices: [(String, String, (() -> Void)?)], view: UIView) {
        height = (buttonViewHeight * CGFloat(choices.count)) + titleView.frame.height + 10
        targetY = view.frame.height - height
        self.view = view
        
        super.init(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height))
        
        self.choices = choices
        
        backgroundColor = Globals.getThemeColor2()
        
        dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        let dismiss = UITapGestureRecognizer(target: self, action: #selector(self.triggerDismiss))
        dimView.alpha = 0
        dimView.addGestureRecognizer(dismiss)
        
        view.addSubview(dimView)
        view.addSubview(self)
        
        titleView.backgroundColor = Globals.getThemeColor1()
        self.addSubview(titleView)
        
        var path = UIBezierPath(roundedRect: titleView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        titleView.layer.mask = mask
        
        path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
        mask.path = path.cgPath
        self.layer.mask = mask
        
        for i in 0 ..< choices.count {
            
            let choiceView = UIView(frame: CGRect(x: 0, y: titleView.frame.height +
                (buttonViewHeight * CGFloat(i)), width: view.frame.width, height: buttonViewHeight))
            
            let icon = UIImageView(frame: CGRect(x: 20, y: 10, width: 30, height: choiceView.frame.height - 20))
            icon.image = UIImage(named: choices[i].1)
            
            if let image = icon.image {
                let maskImage = image.cgImage!
                
                let width = image.size.width
                let height = image.size.height
                let bounds = CGRect(x: 0, y: 0, width: width, height: height)
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
                let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
                
                context.clip(to: bounds, mask: maskImage)
                context.setFillColor(Globals.getThemeColor1().cgColor)
                context.fill(bounds)
                
                if let cgImage = context.makeImage() {
                    icon.image = UIImage(cgImage: cgImage)
                }
            }
            
            choiceView.addSubview(icon)
            
            let button = UIButton(frame: CGRect(x: 70, y: 0, width: choiceView.frame.width, height: choiceView.frame.height))
            button.setTitle(choices[i].0, for: .normal)
            button.setTitleColor(Globals.getThemeColor1(), for: .normal)
            button.addTarget(self, action: #selector(btnClicked), for: .touchUpInside)
            button.contentHorizontalAlignment = .left
            button.tag = i
            
            choiceView.addSubview(button)
            self.addSubview(choiceView)
        }
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func btnClicked(_ button: UIButton!) {
        if let handler = choices[button.tag].2 {
            handler()
        }
        present(show: false)
    }
    
    func present(show: Bool) {
        if (show) {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                if let cs = self {
                    self?.frame = CGRect(x: 0, y: cs.targetY, width: cs.view.frame.width, height: cs.height)
                    self?.dimView.alpha = 1
                }
            }) { (finished) in
            }
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                if let cs = self {
                    self?.frame = CGRect(x: 0, y: cs.view.frame.height, width: cs.view.frame.width, height: cs.height)
                    self?.dimView.alpha = 0
                }
            }) { (finished) in
            }
        }
    }
    
    func triggerDismiss() {
        present(show: false)
    }
}
