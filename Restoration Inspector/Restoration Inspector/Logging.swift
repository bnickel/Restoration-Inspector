//
//  Logging.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/9/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import KeyedArchiveInspector

extension String {
    func indented(level:Int) -> String {
        let prefix = String(count: level * 4, repeatedValue: Character(" "))
        return prefix + self.stringByReplacingOccurrencesOfString("\n", withString: "\n" + prefix, options: nil, range: nil)
    }
}

extension KeyedArchiveRecord : Printable {
    
    public var description:String {
        if let data = value as? NSData {
            return "\(key) (\(valueType)) = \(data.length) bytes"
            
        } else {
            return "\(key) (\(valueType)) = \(value)" + (children.count > 0 ? "\n" + "\n".join(children.map({ $0.description })).indented(1) : "")
        }
    }
}

extension BeautifiedKeyedArchiveRecord : Printable {
    
    public var description:String {
        if let data = value as? NSData {
            return "\(key) (\(valueType)) = \(data.length) bytes"
            
        } else {
            return "\(key) (\(valueType)) = \(value)" + (children.count > 0 ? "\n" + "\n".join(children.map({ $0.description })).indented(1) : "")
        }
    }
}

extension KeyedArchive : Printable {
    public var description:String {
        return join("\n", sorted(map(keys) { self[$0]!.beautified.description }))
    }
}

func logApplicationState(path:String) {
    
    var error:NSError?
    
    if let state = ApplicationState(contentsOfFile: path, error: &error) {
        logApplicationState(state)
    } else if let error = error {
        println("Could not read archive: \(error)")
    }
}

func logApplicationState(state:ApplicationState, println:String -> Void = println) {
    
    println("Bundle version: \(state.bundleVersion)")
    println("System version: \(state.systemVersion)")
    println("UI Idiom:       \(state.userInterfaceIdiom)")
    println("")
    
    for identifier in state.restorationIdentifiers {
        
        println("-----------------------")
        println("")
        
        println("Object:            \(identifier)")
        println("Restoration class: " + (state.restorationClassMap[identifier] ?? "nil"))
        println("")
        println("Encoded state:")
        println("")
        
        var error:NSError?
        
        if let archive = state.restoredObject(identifier, error: &error) {
            println(archive.description)
            
            if let views = archive["kViewRestorationDataKey"]?.beautified.children where views.count > 0 {
                
                println("")
                println("Restorable views:")
                println("")
                
                for view in views {
                    
                    println(view.key)
                    
                    if  let data = view.value as? NSData,
                        let archive = KeyedArchive(data: data, error: &error) {
                            
                            println(archive.description.indented(1))
                            
                    } else if let error = error {
                        println("Could not read child archive: \(error)")
                    }
                }
                
            }
            
        } else if let error = error {
            println("Could not read archive: \(error)")
        }
        println("")
    }
}

extension ApplicationState: Printable {
    
    public var description:String {
        var output = ""
        logApplicationState(self, println: { output += "\($0)\n"})
        return output
    }
}