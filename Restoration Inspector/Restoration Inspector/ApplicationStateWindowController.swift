//
//  ApplicationStateWindowController.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/9/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Cocoa

class ApplicationStateWindowController: NSWindowController, NSToolbarDelegate {

    override var document: AnyObject? {
        didSet {
            documentDidRefresh()
            documentDidChangeAutorefresh()
        }
    }
    
    func documentDidRefresh() {
        let doc = document as! ApplicationStateDocument
        let viewController = window!.contentViewController as! ApplicationStateViewController
        viewController.applicationState = doc.applicationState
    }
    
    func documentDidChangeAutorefresh() {
        let doc = document as! ApplicationStateDocument
        toolbar.selectedItemIdentifier = doc.shouldAutorefresh ? autorefreshItem.itemIdentifier : nil
    }
    
    func toolbarSelectableItemIdentifiers(toolbar: NSToolbar) -> [AnyObject] {
        return [autorefreshItem.itemIdentifier]
    }
    
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var autorefreshItem: NSToolbarItem!
    
    @IBAction func refreshDocument(sender: AnyObject) {
        let doc = document as! ApplicationStateDocument
        doc.refresh()
    }
    
    @IBAction func toggleAutorefresh(sender: AnyObject) {
        let doc = document as! ApplicationStateDocument
        doc.shouldAutorefresh = !doc.shouldAutorefresh
    }
    
    @IBAction func clearSavedState(sender: AnyObject) {
        let doc = document as! ApplicationStateDocument
        doc.deleteSavedState()
    }
}
