//
//  HITS.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/23/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import Foundation

class HITS {
    static func authorityUpdate(hub: [String: Int], songDict: [String: [Song]]) -> [String: Int]{
        var newAuthority = [String: Int]()
        for (user, songs) in songDict {
            for song in songs {
                newAuthority[song.id] = newAuthority[song.id, default: 0] + hub[user]!
            }
        }
        return newAuthority
    }
    
    static func hubUpdate(authority: [String: Int], songDict: [String: [Song]]) -> [String: Int] {
        var newHub = [String: Int]()
        for (user, songs) in songDict {
            for song in songs {
                newHub[user] = newHub[user, default: 0] + authority[song.id]!
            }
        }
        return newHub
    }
    
    static func HITS(songDict: [String: [Song]], t: Int) -> ([String: Int]){
        var hub = [String: Int]()
        var authority = [String: Int]()
        
        for (user, songs) in songDict {
            for song in songs {
                authority[song.id] = 1
            }
            hub[user] = 1
        }
        
        for _ in 0 ..< t {
            authority = authorityUpdate(hub: hub, songDict: songDict)
            hub = hubUpdate(authority: authority, songDict: songDict)
        }
        
        return authority
    }
    
    static func getTopAuth(auth: [String: Int], n: Int) -> [String] {
        var unordered = [(String, Int)]()
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
    
    static func decreaseSongLikelihood(graph: [[Float]], song: Int) -> [[Float]]{
        var newGraph = graph
        for i in 0 ..< graph.count {
            newGraph[i][song] -= 3.0
            if (newGraph[i][song] < 0.1) {
                newGraph[i][song] = 0.1
            }
        }
        return newGraph
    }
    
    static func generateGraph(songIdsTotal: [String], songDict: [String: [Song]], clusters: [[String]], topAuth: [String]) -> [[Float]] {
        let M = songIdsTotal.count
        var graph = [[Float]](repeating: [Float](repeating: 0, count: M), count: M)
        
        for (user, songs) in songDict {
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
    
    static func getRandSong(songs: [String], dist: [Float]) -> String {
        let summ = dist.reduce(0, +)
        var distNorm = dist
        if (summ > 0) {
            
            // Normalize
            for i in  0 ..< songs.count {
                distNorm[i] /= summ
            }
            
            let rand = Float(Float(arc4random()) / Float(UINT32_MAX))
            var total = Float(0)
            
            for i in 0 ..< songs.count {
                total += distNorm[i]
                if (rand <= total) {
                    return songs[i]
                }
            }
            return songs.last!
        }
        return "None"
    }
    
    static func getNextSongs(network: [[Float]], start: String, songs: [String], n: Int) -> ([String], [[Float]]){
        var nodesFound = [String]()
        var curNode = start
        var newNetwork = network
        var num = n
        
        if (songs.count - 1 < n) {
            num = songs.count - 1
        }
        
        while (nodesFound.count < num) {
            curNode = getRandSong(songs: songs, dist: network[songs.index(of: curNode)!])
            if (!songs.contains(curNode)) {
                nodesFound.append(curNode)
                newNetwork = decreaseSongLikelihood(graph: newNetwork, song: songs.index(of: curNode)!)
            }
        }
        return (nodesFound, newNetwork)
    }
}
