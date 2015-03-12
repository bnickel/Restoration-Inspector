//
//  AppDelegate.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/9/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "windowWillClose:", name: NSWindowWillCloseNotification, object: nil)
        
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        if NSApplication.sharedApplication().windows.count == 0 {
            showSavedStatesWindow()
        }
    }
    
    func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
        return false
    }
    
    func windowWillClose(aNotification: NSNotification) {
        if NSApplication.sharedApplication().windows.count == 1 && (aNotification.object as? NSWindow)?.identifier != "All Saved States" {
            showSavedStatesWindow()
        }
    }
    
    @IBOutlet weak var savedStatesMenuItem: NSMenuItem!
    func showSavedStatesWindow() {
        // As far as I can tell, this is the best way to create the controller and have the window retain the window controller.
        NSApplication.sharedApplication().sendAction(savedStatesMenuItem.action, to: savedStatesMenuItem.target, from: savedStatesMenuItem)
    }
}

