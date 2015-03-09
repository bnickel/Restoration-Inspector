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
    
    override func fileWrapperOfType(typeName: String, error outError: NSErrorPointer) -> NSFileWrapper? {
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }
    
    override func readFromFileWrapper(fileWrapper: NSFileWrapper, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        
        if let data = (fileWrapper.fileWrappers["data.data"] as? NSFileWrapper)?.regularFileContents {
            applicationState = ApplicationState(data: data, error: nil)
        }
        
        return true

    }
    
    override func presentedItemDidChange() {
        super.presentedItemDidChange()
        readFromURL(fileURL!, ofType: fileType!, error: nil)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            for windowController in self.windowControllers as! [ApplicationStateWindowController] {
                windowController.document = self
            }
        })
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)!
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }
}
