//
//  Kmeans.swift
//  CollabPlaylists
//
//  Created by Milan Ravenell on 7/23/18.
//  Copyright © 2018 Ravenell, Milan. All rights reserved.
//

import Foundation

class Kmeans {
    
    var k: Int!
    var centroids = [[Float]]()
    var labels: [Int]?
    
    init?(k: Int) {
        self.k = k
    }
    
    func fit(data: [[Float]]) {
        
        let N = data.count
        let M = data.first!.count
        labels = [Int](repeating: -1, count: N)
        
        if (N <= 0) {
            return
        }
        
        // Set up
        var randIndices = [Int]()
        while (randIndices.count < k) {
            let rand = Int(arc4random_uniform(UInt32(N)))
            if (!randIndices.contains(rand)) {
                randIndices.append(rand)
            }
        }
        
        for indx in randIndices {
            centroids.append(data[indx])
        }
        
        // Run algorithm
        var hasChanged = true
        var n = 0
        while (hasChanged && n < 500) {
            hasChanged = false
            n += 1
            
            // Assign new labels
            for i in 0 ..< N {
                let newLabel = getClosestCentroid(vec: data[i])
                if (newLabel != labels?[i]) {
                    hasChanged = true
                    labels?[i] = newLabel
                }
            }
            
            // Calculate new centroids
            centroids = [[Float]](repeating: [Float](repeating: 0, count: M) , count: k)
            var counts = [Float](repeating: 0, count: k)
            for i in 0 ..< N {
                for j in 0 ..< M {
                    centroids[labels![i]][j] += data[i][j]
                }
                counts[labels![i]] += 1.0
            }
            for i in 0 ..< k {
                for j in 0 ..< M {
                    if (counts[i] != 0) {
                        centroids[i][j] /= counts[i]
                    }
                }
            }
        }
    }
    
    func distance(vec1: [Float], vec2: [Float]) -> Float {
        let M = vec1.count
        var total = Float(0)
        for i in 0 ..< M {
            total += pow(vec1[i] - vec2[i], 2)
        }
        total = Float(sqrt(Double(total)))
        return total
    }
    
    func getClosestCentroid(vec: [Float]) -> Int {
        var label = 0
        var minDist = distance(vec1: vec, vec2: centroids[0])
        
        for i in 1 ..< k {
            let dist = distance(vec1: vec, vec2: centroids[i])
            
            if (dist < minDist) {
                label = i
                minDist = dist
            }
        }
        
        return label
    }
}
