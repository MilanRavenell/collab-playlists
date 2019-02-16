//
//  NowPlaying.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 9/20/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import UIKit

class NowPlaying: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var parent: ViewPlaylistViewController!
    var imageView: UIImageView!
    var name: UILabel!
    var artist: UILabel!
    var active = true
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    init (frame : CGRect, parent: ViewPlaylistViewController) {
        super.init(frame: frame)
        self.parent = parent
        
        self.backgroundColor = Globals.getThemeColor2()
        
        imageView = UIImageView(frame: CGRect(x: 20, y: 20, width: self.frame.width - 40, height: self.frame.height - 150))
        imageView.image = UIImage(named: Globals.defaultPic)
        self.addSubview(imageView)
        
        name = UILabel(frame: CGRect(x: 0, y: imageView.frame.maxY + Globals.medOffset, width: self.frame.width, height: 30))
        name.textAlignment = .center
        name.font =  name.font.withSize(25)
        self.addSubview(name)
        
        artist = UILabel(frame: CGRect(x: 0, y: name.frame.maxY + Globals.smallOffset, width: self.frame.width, height: 30))
        artist.textAlignment = .center
        self.addSubview(artist)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setNowPlaying(song: Song?) {
        if let song = song {
            song.assignPicToView(imageView: imageView)
            name.text = song.name
            artist.text = song.artist
        } else {
            imageView.image = UIImage(named: Globals.defaultPic)
            name.text = "..."
            artist.text = "..."
        }
    }
}
