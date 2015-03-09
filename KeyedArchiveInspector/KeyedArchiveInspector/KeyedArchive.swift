//
//  KeyedArchive.swift
//  KeyedArchiveInspector
//
//  Created by Brian Nickel on 2/20/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Foundation

private let simpleObjectMap = ["NSMutableData": "NS.data", "NSMutableString": "NS.string", "NSMutableArray": "NS.objects", "_UIObjectIdentifierPathProxy": "kObjectIdentifierPathProxyIdentifierPathKey"]

public class BeautifiedKeyedArchiveRecord {
    public let key:String
    public let value:NSObject
    public let valueType:String
    public let children:[BeautifiedKeyedArchiveRecord]
    
    init(key:String, value:NSObject, valueType:String, children:[BeautifiedKeyedArchiveRecord]) {
        self.key = key
        self.value = value
        self.valueType = valueType
        self.children = children
    }
    
    func withKey(key:String) -> BeautifiedKeyedArchiveRecord {
        return BeautifiedKeyedArchiveRecord(key: key, value: value, valueType: valueType, children: children)
    }
    
    func withValueType(valueType:String) -> BeautifiedKeyedArchiveRecord {
        return BeautifiedKeyedArchiveRecord(key: key, value: value, valueType: valueType, children: children)
    }
    
    private(set) public lazy var keyedChildren:[String: BeautifiedKeyedArchiveRecord] = {
        var keyedChildren:[String: BeautifiedKeyedArchiveRecord] = [:]
        for child in self.children {
            keyedChildren[child.key] = child
        }
        return keyedChildren
    }()
}

public class KeyedArchiveRecord {
    public let key:String
    public let value:NSObject
    public let valueType:String
    public let children:[KeyedArchiveRecord]
    
    init(key:String, value:NSObject, valueType:String, children:[KeyedArchiveRecord]) {
        self.key = key
        self.value = value
        self.valueType = valueType
        self.children = children
    }
    
    func withKey(key:String) -> KeyedArchiveRecord {
        return KeyedArchiveRecord(key: key, value: value, valueType: valueType, children: children)
    }
    
    func withValueType(valueType:String) -> KeyedArchiveRecord {
        return KeyedArchiveRecord(key: key, value: value, valueType: valueType, children: children)
    }
    
    private(set) public lazy var keyedChildren:[String: KeyedArchiveRecord] = {
        var keyedChildren:[String: KeyedArchiveRecord] = [:]
        for child in self.children {
            keyedChildren[child.key] = child
        }
        return keyedChildren
    }()
    
    private(set) public lazy var beautified:BeautifiedKeyedArchiveRecord = {
        
        if  let childKey = simpleObjectMap[self.valueType],
            let value = self.keyedChildren[childKey] {
                return value.beautified.withValueType(self.valueType).withKey(self.key)
        }
        
        if self.valueType == "NSDictionary" || self.valueType == "NSMutableDictionary" {
            
            if let keys = self.keyedChildren["NS.keys"]?.children.map({ $0.value.description }),
                let values = self.keyedChildren["NS.objects"]?.children where values.count == keys.count {
                    var children:[BeautifiedKeyedArchiveRecord] = []
                    for (key, value) in zip(keys, values) {
                        children.append(value.beautified.withKey(key))
                    }
                    
                    return BeautifiedKeyedArchiveRecord(key: self.key, value: "\(children.count) values", valueType: self.valueType, children: children)
            }
        }
        
        return BeautifiedKeyedArchiveRecord(key: self.key, value: self.value, valueType: self.valueType, children: self.children.map { $0.beautified })
        
    }()
    
}

public let KeyedArchiveInspectorErrorDomain = "com.stackexchange.KeyedArchiveInspector"
public let KeyedArchiveErrorInvalidArchive = 1

public class KeyedArchive {
    
    private let rawTop:[String: NSObject]
    private let rawObjects:[NSObject]
    
    public let keys:Set<String>
    
    private var objects:[Int: KeyedArchiveRecord] = [:]
    private var top:[String: KeyedArchiveRecord] = [:]
    
    private init(rawTop:[String: NSObject], rawObjects:[NSObject]) {
        self.rawTop = rawTop
        self.rawObjects = rawObjects
        self.keys = Set(rawTop.keys)
    }
    
    private convenience init?(propertyList:[String: NSObject], error:NSErrorPointer) {
        
        if  let rawTop = propertyList["$top"] as? [String: NSObject],
            let rawObjects = propertyList["$objects"] as? [NSObject] {
                self.init(rawTop: rawTop, rawObjects: rawObjects)
        } else {
            
            if error != nil {
                error.memory = NSError(domain: KeyedArchiveInspectorErrorDomain, code: KeyedArchiveErrorInvalidArchive, userInfo: [:])
            }
            
            self.init(rawTop: [:], rawObjects: [])
            return nil
        }
    }
    
    public convenience init?(data:NSData, error:NSErrorPointer) {
        
        if let propertyList = NSPropertyListSerialization.propertyListWithData(data, options: 0, format: nil, error: error) as? [String: NSObject] {
            self.init(propertyList:propertyList, error: error)
        } else {
            self.init(rawTop: [:], rawObjects: [])
            return nil
        }
    }
    
    public convenience init?(contentsOfURL URL:NSURL, error:NSErrorPointer) {
        
        if let data = NSData(contentsOfURL: URL, options: nil, error: error) {
            self.init(data: data, error: error)
        } else {
            self.init(rawTop: [:], rawObjects: [])
            return nil
        }
    }
    
    public convenience init?(contentsOfFile file:String, error:NSErrorPointer) {
        
        if let data = NSData(contentsOfFile: file, options: nil, error: error) {
            self.init(data: data, error: error)
        } else {
            self.init(rawTop: [:], rawObjects: [])
            return nil
        }
    }
    
    private let UIDRegex = NSRegularExpression(pattern: "^<CFKeyedArchiverUID[^>]*>\\{value = (\\d+)\\}$", options: nil, error: nil)!
    
    private func readObject(dictionary:[String: NSObject], classname:String) -> KeyedArchiveRecord {
        
        
        var children:[KeyedArchiveRecord] = []
        for (key, value) in dictionary {
            if !key.hasPrefix("$") {
                children.append(read(value).withKey(key))
            }
        }
        return KeyedArchiveRecord(key: "", value: "\(children.count) values" as NSString, valueType: classname, children: children)
    }
    
    private func readArray(array:[NSObject]) -> KeyedArchiveRecord {
        var children:[KeyedArchiveRecord] = []
        for (index, value) in enumerate(array) {
            children.append(read(value).withKey("\(index)"))
        }
        return KeyedArchiveRecord(key: "", value: "\(children.count) values" as NSString, valueType: "NSArray", children: children)
    }
    
    private func read(rawObject:NSObject) -> KeyedArchiveRecord {
        if let number = rawObject as? NSNumber {
            return KeyedArchiveRecord(key: "", value: number, valueType: "NSNumber", children: [])
        } else if let string = rawObject as? NSString {
            if string == "$null" {
                return KeyedArchiveRecord(key: "?", value: "null", valueType: "", children: [])
            } else {
                return KeyedArchiveRecord(key: "", value: string, valueType: "NSString", children: [])
            }
        } else if let array = rawObject as? [NSObject] {
            return readArray(array)
        } else if
            let dictionary = rawObject as? [String: NSObject],
            let classname = dictionary["$classname"] as? NSString {
                return KeyedArchiveRecord(key: "", value: classname, valueType: "Class", children: [])
        } else if
            let dictionary = rawObject as? [String: NSObject],
            let classReference = dictionary["$class"] {
                return readObject(dictionary, classname: read(classReference).value.description)
        } else if
            let match = UIDRegex.firstMatchInString(rawObject.description, options: nil, range: NSMakeRange(0, rawObject.description.utf16Count)),
            let number = (rawObject.description as NSString).substringWithRange(match.rangeAtIndex(1)).toInt() {
                return object(number)
        }
        
        return KeyedArchiveRecord(key: "", value: rawObject, valueType: NSStringFromClass(rawObject.dynamicType), children: [])
    }
    
    private func object(index:Int) -> KeyedArchiveRecord {
        
        if let object = objects[index] {
            return object
        } else if rawObjects.startIndex <= index && index < rawObjects.endIndex {
            let object = read(rawObjects[index])
            objects[index] = object
            return object
        } else {
            return KeyedArchiveRecord(key: "", value: "**INVALID OBJECT REFERENCE**", valueType: "", children: [])
        }
    }
    
    public subscript(key:String) -> KeyedArchiveRecord? {
        
        if let object = top[key] {
            return object
        } else if let rawObject = rawTop[key] {
            let object = read(rawObject).withKey(key)
            top[key] = object
            return object
        } else {
            return nil
        }
    }
}
