//
//  HITS.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/23/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import Foundation

class HITS {
    static func authorityUpdate(hub: [String: Float], songDict: [String: [Song]]) -> [String: Float]{
        var newAuthority = [String: Float]()
        for (user, songs) in songDict {
            for song in songs {
                newAuthority[song.id] = newAuthority[song.id, default: 0] + hub[user]!
            }
        }
        return newAuthority
    }
    
    static func hubUpdate(authority: [String: Float], songDict: [String: [Song]]) -> [String: Float] {
        var newHub = [String: Float]()
        for (user, songs) in songDict {
            for song in songs {
                newHub[user] = newHub[user, default: 0] + authority[song.id]!
            }
        }
        return newHub
    }
    
    static func HITS(songDict: [String: [Song]], t: Int) -> ([String: Float]){
        var hub = [String: Float]()
        var authority = [String: Float]()
        
        for (user, songs) in songDict {
            for song in songs {
                authority[song.id] = 0.001
            }
            hub[user] = 0.001
        }
        
        for _ in 0 ..< t {
            authority = authorityUpdate(hub: hub, songDict: songDict)
            hub = hubUpdate(authority: authority, songDict: songDict)
        }
        
        return authority
    }
    
    static func getTopAuth(auth: [String: Float], n: Int) -> [String] {
        var unordered = [(String, Float)]()
        for (song, score) in auth {
            unordered.append((song, score))
        }
        var ordered = unordered.sorted(by: { $0.1 > $1.1 })
        var top = [String]()
        
        var num = n
        if (ordered.count < n) {
            num = ordered.count
        }
        
        for i in 0 ..< num {
            top.append(ordered[i].0)
        }
        
        return top
    }
    
    static func decreaseSongLikelihood(graph: [[Int]], song: Int) -> [[Int]] {
        var newGraph = graph
        for i in 0 ..< graph.count {
            newGraph[i][song] -= 400
            if (newGraph[i][song] < 10) {
                newGraph[i][song] = 10
            }
        }
        return newGraph
    }
    
    static func generateGraph(songIdsTotal: [String], songDict: [String: [Song]], clusters: [[String]], topAuth: [String]) -> [[Float]] {
        let M = songIdsTotal.count
        var graph = [[Float]](repeating: [Float](repeating: 0, count: M), count: M)
        
        for (_, songs) in songDict {
            for i in 0 ..< songs.count {
                for j in i ..< songs.count {
                    let song1 = songIdsTotal.index(of: songs[i].id)
                    let song2 = songIdsTotal.index(of: songs[j].id)
                    graph[song1!][song2!] += 0.25
                    graph[song2!][song1!] += 0.25
                }
            }
        }
        
        for c in clusters {
            for i in 0 ..< c.count {
                for j in i ..< c.count {
                    let song1 = songIdsTotal.index(of: c[i])
                    let song2 = songIdsTotal.index(of: c[j])
                    graph[song1!][song2!] += 2.0
                    graph[song2!][song1!] += 2.0
                }
            }
        }
        
        for song in topAuth {
            let indx = songIdsTotal.index(of: song)
            for i in 0 ..< M {
                graph[i][indx!] += 5.0
            }
        }
        
        for s in 0 ..< M {
            graph[s][s] = 0
        }
        
        return graph
    }
    
    static func getRandSong(songs: [Song], dist: [Int]) -> Song {
        let summ = Float(dist.reduce(0, +))
        var distNorm = [Float]()
        if (summ > 0) {
            // Normalize
            for i in  0 ..< songs.count {
                distNorm.append(Float(dist[i])/summ)
            }
            
            let rand = Float(Float(arc4random()) / Float(UINT32_MAX))
            var total = Float(0)
            
            for i in 0 ..< songs.count {
                total += distNorm[i]
                if (rand <= total) {
                    return songs[i].copy() as! Song
                }
            }
            return songs.last!.copy() as! Song
        }
        return songs.first!.copy() as! Song
    }
    
    static func getNextSongs(network: [[Int]], start: Song, songs: [Song], n: Int) -> [Song] {
        var nodesFound = [Song]()
        var curNode = start
        var newNetwork = network
        var num = n
        
        if (songs.count - 1 < n) {
            num = songs.count - 1
        }
        
        while (nodesFound.count < num) {
            curNode = getRandSong(songs: songs, dist: network[getSongIndex(song: curNode, songs: songs)!])
            curNode.loadPic()
            
            if (!isContained(song: curNode, songs: nodesFound)) {
                nodesFound.append(curNode)
                newNetwork = decreaseSongLikelihood(graph: newNetwork, song: getSongIndex(song: curNode, songs: songs)!)
            }
        }
        
        return nodesFound
    }
    
    static func getSongIndex(song: Song, songs: [Song]) -> Int? {
        let indx = songs.index(where: { (item) -> Bool in
            item.id == song.id
        })
        return indx
    }
    
    static func isContained(song: Song, songs: [Song]) -> Bool {
        return songs.contains { (item) -> Bool in
            item.id == song.id
        }
    }
}
