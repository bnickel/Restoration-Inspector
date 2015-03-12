//
//  Simulators.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/12/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Foundation

func findAllSimulators() -> [iOSSimulator] {
    let simulators = findAll(baseURL: NSURL(string: "Library/Developer/CoreSimulator/Devices/", relativeToURL: NSURL(fileURLWithPath: NSHomeDirectory()))) { iOSSimulator(URL: $0) }
    return sorted(simulators, { $0.name < $1.name || ($0.name == $1.name && $0.runtime < $1.runtime) })

}

private func findAll<T>(#baseURL:NSURL?, transform:NSURL -> T?) -> [T] {
    if  let baseURL = baseURL,
        let URLs = NSFileManager.defaultManager().contentsOfDirectoryAtURL(baseURL, includingPropertiesForKeys: [NSURLNameKey], options: .SkipsSubdirectoryDescendants, error: nil) {
            return URLs.map { $0 as! NSURL } .map(transform).filter { $0 != nil } .map { $0! } // Casting here because `as? [NSURL]` causes Zombie in Swift 1.2.
    } else {
        return []
    }
}

@objc class iOSSimulator {
    
    let URL:NSURL
    let name:String
    let runtime:String
    let savedStates:[NSURL]
    
    init?(URL:NSURL) {
        self.URL = URL
        
        if  let plistURL = NSURL(string: "device.plist", relativeToURL: URL),
            let data = NSData(contentsOfURL: plistURL),
            let properties = NSPropertyListSerialization.propertyListWithData(data, options: 0, format: nil, error: nil) as? [String: AnyObject],
            let name = properties["name"] as? String,
            let runtime = properties["runtime"] as? String {
                
                self.name = name
                
                let prefix = "com.apple.CoreSimulator.SimRuntime.iOS-"
                if runtime.hasPrefix(prefix) {
                    self.runtime = runtime.substringFromIndex(prefix.endIndex).stringByReplacingOccurrencesOfString("-", withString: ".", options: nil, range: nil)
                } else {
                    self.runtime = runtime
                }
                
                let data:[[(String, NSURL)]] = findAll(baseURL: self.URL.URLByAppendingPathComponent("data/Containers/Data/Application/")) { dataURL -> [(String, NSURL)]? in
                    return findAll(baseURL: dataURL.URLByAppendingPathComponent("Library/Saved Application State")) { savedStateURL -> (String, NSURL)? in
                        var key = savedStateURL.lastPathComponent
                        if key != nil && key!.removeSuffix(".savedState") {
                            return (key!, savedStateURL)
                        } else {
                            return nil
                        }
                    }
                }
                
                self.savedStates = data.reduce([(String, NSURL)](), combine: +).sorted({ $0.0 < $1.0 }).map({ $0.1 })
                
        } else {
            self.name = ""
            self.runtime = ""
            self.savedStates = []
        }
        
        if savedStates.count == 0 {
            return nil
        }
    }
}

private extension String {
    
    mutating func removeSuffix(suffix:String) -> Bool {
        if hasSuffix(suffix) {
            removeRange(advance(endIndex, -count(suffix)) ..< endIndex)
            return true
        } else {
            return false
        }
    }
    
    mutating func removePrefix(prefix:String) -> Bool {
        if hasPrefix(prefix) {
            removeRange(startIndex ..< advance(startIndex, count(prefix)))
            return true
        } else {
            return false
        }
    }
}
