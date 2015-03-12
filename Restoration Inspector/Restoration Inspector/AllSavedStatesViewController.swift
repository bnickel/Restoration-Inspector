//
//  AllSavedStatesViewController.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/12/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Cocoa

class AllSavedStatesViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    private var selectingFromNotification = false
    
    private var simulators:[iOSSimulator] = [] {
        didSet {
            outlineView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "selectItemFromNotification:", name: NSWindowDidBecomeKeyNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        simulators = findAllSimulators()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0
            self.outlineView.expandItem(nil, expandChildren: true)
        }, completionHandler: nil)
        selectItemFromNotification(nil)
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        return ((item as? Outlineable) ?? self).children.count
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        return ((item as? Outlineable) ?? self).children[index]
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return ((item as? Outlineable) ?? self).children.count > 0
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        
        if let simulator = item as? iOSSimulator,
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as? NSTableCellView {
                view.textField?.stringValue = "\(simulator.name) (\(simulator.runtime))"
                return view
        } else if let URL = item as? NSURL,
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as? NSTableCellView {
                view.textField?.stringValue = URL.lastPathComponent!.stringByDeletingPathExtension
                return view
        } else {
            fatalError("Could not create view for \(item)")
        }
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        return item is NSURL
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        if outlineView.selectedRow != -1 && !selectingFromNotification {
            
            if let URL = outlineView.itemAtRow(outlineView.selectedRow) as? NSURL {
                NSDocumentController.sharedDocumentController().openDocumentWithContentsOfURL(URL, display: true, completionHandler: { (document, wasOpen, error) -> Void in
                    return
                })
            }
        }
    }
    
    private func exactURL(URL:NSURL?) -> NSURL? {
        for simulator in simulators {
            for exactURL in simulator.savedStates {
                if exactURL == URL {
                    return exactURL
                }
            }
        }
        return nil
    }
    
    func selectItemFromNotification(notification:NSNotification?) {
        let documentController = NSDocumentController.sharedDocumentController() as! NSDocumentController
        
        let URL = (documentController.currentDocument as? NSDocument)?.fileURL
        
        selectingFromNotification = true
        if !outlineView.selectItem(exactURL(URL)) {
            outlineView.deselectAll(self)
        }
        selectingFromNotification = false
    }
}

@objc protocol Outlineable {
    var children: [Outlineable] { get }
}

extension iOSSimulator: Outlineable {
    @objc var children:[Outlineable] {
        return savedStates
    }
}

extension NSURL : Outlineable {
    @objc var children:[Outlineable] {
        return []
    }
}

extension AllSavedStatesViewController: Outlineable {
    
    @objc var children:[Outlineable] {
        return simulators
    }
}

// From http://stackoverflow.com/a/1299834/860000
extension NSOutlineView {
    
    func expandParentOfItem(var item:AnyObject?) {
        while let parent:AnyObject = parentForItem(item) where isExpandable(parent) {
            
            if !isItemExpanded(parent) {
                expandItem(parent)
            }
            
            item = parent
        }
    }
    
    func selectItem(item:AnyObject?) -> Bool {
        var itemIndex = rowForItem(item)
        if itemIndex < 0 {
            expandParentOfItem(item)
            itemIndex = rowForItem(item)
        }
        
        if itemIndex >= 0 {
            selectRowIndexes(NSIndexSet(index: itemIndex), byExtendingSelection: false)
            return true
        } else {
            return false
        }
    }
}
