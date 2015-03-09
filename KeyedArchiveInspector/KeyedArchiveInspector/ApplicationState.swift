//
//  ApplicationState.swift
//  KeyedArchiveInspector
//
//  Created by Brian Nickel on 2/20/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Foundation

public class ApplicationState {
    
    private let rootArchive:KeyedArchive!
    
    private init(rootArchive:KeyedArchive) {
        self.rootArchive = rootArchive
    }
    
    private init?() {
        rootArchive = nil
        
        return nil
    }
    
    public convenience init?(data:NSData, error:NSErrorPointer) {
        
        if let rootArchive = KeyedArchive(data: data, error: error) {
            self.init(rootArchive: rootArchive)
        } else {
            self.init()
        }
    }
    
    public convenience init?(contentsOfURL URL:NSURL, error:NSErrorPointer) {
        
        if let rootArchive = KeyedArchive(contentsOfURL: URL, error: error) {
            self.init(rootArchive: rootArchive)
        } else {
            self.init()
        }
    }
    
    public convenience init?(contentsOfFile file:String, error:NSErrorPointer) {
        
        if let rootArchive = KeyedArchive(contentsOfFile: file, error: error) {
            self.init(rootArchive: rootArchive)
        } else {
            self.init()
        }
    }
    
    public var bundleVersion:String! {
        return rootArchive["UIApplicationStateRestorationBundleVersion"]?.value as? String
    }
    
    public var systemVersion:String! {
        return rootArchive["UIApplicationStateRestorationSystemVersion"]?.value as? String
    }
    
    public var userInterfaceIdiom:Int! {
        return rootArchive["UIApplicationStateRestorationUserInterfaceIdiom"]?.value as? Int
    }
    
    public var restorationIdentifiers:[String] {
        if let identifiers = rootArchive["kRootRestorationIdentifiersKey"]?.beautified.children {
            return identifiers.map({ $0.value as! String })
        } else {
            return []
        }
    }
    
    public var restorationClassMap:[String:String] {
        
        if let children = rootArchive["kViewControllerRestorationClassMapKey"]?.beautified.children {
            var classMap:[String:String] = [:]
            for child in children {
                classMap[child.key] = child.value.description
            }
            return classMap
        } else {
            return [:]
        }
    }
    
    public func restoredObject(key:String, error:NSErrorPointer) -> KeyedArchive? {
        if let data = rootArchive[key]?.beautified.value as? NSData {
            return KeyedArchive(data: data, error: error)
        } else {
            if error != nil {
                error.memory = NSError(domain: KeyedArchiveInspectorErrorDomain, code: KeyedArchiveErrorInvalidArchive, userInfo: nil)
            }
            return nil
        }
    }
}
