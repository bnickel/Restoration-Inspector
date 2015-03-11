//
//  ApplicationStateDocument.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/9/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Cocoa
import KeyedArchiveInspector

class ApplicationStateDocument: NSDocument {
    
    var applicationState:ApplicationState?
    
    var shouldAutorefresh:Bool = true {
        didSet {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                for windowController in self.windowControllers as! [ApplicationStateWindowController] {
                    windowController.documentDidChangeAutorefresh()
                }
            })
        }
    }
    
    override func fileWrapperOfType(typeName: String, error outError: NSErrorPointer) -> NSFileWrapper? {
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }
    
    override func readFromFileWrapper(fileWrapper: NSFileWrapper, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        if let data = (fileWrapper.fileWrappers["data.data"] as? NSFileWrapper)?.regularFileContents {
            applicationState = ApplicationState(data: data, error: nil)
        } else {
            applicationState = nil
        }
        
        return true
    }
    
    override func presentedItemDidChange() {
        super.presentedItemDidChange()
        if shouldAutorefresh {
            refresh()
        }
    }
    
    func refresh() {
        readFromURL(fileURL!, ofType: fileType!, error: nil)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            for windowController in self.windowControllers as! [ApplicationStateWindowController] {
                windowController.documentDidRefresh()
            }
        })
    }
    
    func deleteSavedState() {
        for child in NSFileManager.defaultManager().contentsOfDirectoryAtURL(fileURL!, includingPropertiesForKeys: nil, options: nil, error: nil) as! [NSURL] {
            NSFileManager.defaultManager().removeItemAtURL(child, error: nil)
            refresh()
        }
    }

    override class func autosavesInPlace() -> Bool {
        return false
    }
    
    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)!
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }
}
