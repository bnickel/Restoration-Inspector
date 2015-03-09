// Playground - noun: a place where people can play

import Cocoa

//var handle = dlopen("/Users/bnickel/Library/Developer/Xcode/DerivedData/Restoration_Inspector-aencbpqlomcurvgjhpyokqbzbklv/Build/Products/Debug/KeyedArchiveInspector.framework/Versions/A/KeyedArchiveInspector", 2)

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

let state = ApplicationState(contentsOfFile: "/Users/bnickel/Documents/Shared Playground Data/data.data", error: nil)!

println("Bundle version: \(state.bundleVersion)")
println("System version: \(state.systemVersion)")
println("UI Idiom:       \(state.userInterfaceIdiom)")
println()

for identifier in state.restorationIdentifiers {
    
    println("-----------------------")
    println()

    println("Object:            \(identifier)")
    println("Restoration class: " + (state.restorationClassMap[identifier] ?? "nil"))
    println()
    println("Encoded state:")
    println()
    var error:NSError?
    if let archive = state.restoredObject(identifier, error: &error) {
        println(archive)
        
        if let views = archive["kViewRestorationDataKey"]?.beautified.children where views.count > 0 {
            
            println()
            println("Restorable views:")
            println()
            
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
    println()
}

func printSavedState(println:String -> Void = println) {
    if let libraryDirectory = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .AllDomainsMask, true).first as? String {
        let savedStateDirectory = libraryDirectory.stringByAppendingPathComponent("Saved Application State").stringByAppendingPathComponent("\(NSBundle.mainBundle().bundleIdentifier!).savedState")
        
        var isDirectory:ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(savedStateDirectory, isDirectory: &isDirectory) && isDirectory {
            
            println("Found saved state directory \(savedStateDirectory)")
            
        } else {
            println("Could not find directory \(savedStateDirectory)")
        }
    
    } else {
        println("Could not access libary path")
    }
}

//printSavedState()
