//
//  SongLoadQueue.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/26/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import Foundation

class SongLoadQueue {
    
    //MARK: Properties
    var queues = [[Song?]]()
    var lengths = [Int]()
    var lock = 0
    
    
    // MARK: Initialization
    
    init?(n: Int) {
        // Initialize stored properties
        self.queues = [[Song?]](repeating: [Song?](), count: n)
        self.lengths = [Int](repeating: 0, count: n)
    }
    
    func push(song: Song) {
        while (lock == 1) {
        }
        self.lock = 1
        let queue = getShortestId()
        let wait = (lengths[queue] != 0)
        if (wait) {
            self.queues[queue].insert(song, at: 1)
        } else {
            self.queues[queue].insert(song, at: 0)
        }
        
        song.ticket = (queue, wait)
        self.lengths[queue] += 1
        self.lock = 0
    }
    
    func pop(queue: Int) {
        while (lock == 1) {
        }
        self.lock = 1
        if (self.queues[queue].count > 0) {
            let _ = self.queues[queue].removeFirst()
            self.lengths[queue] -= 1
        }
        
        if (self.queues[queue].count > 0) {
            if let nextSong = self.queues[queue][0] {
                nextSong.loadPic()
            } else {
                pop(queue: queue)
            }
        }
        self.lock = 0
    }
    
    func getShortestId() -> Int {
        let value = self.lengths.min()
        return self.lengths.index(of: value!)!
    }
}
