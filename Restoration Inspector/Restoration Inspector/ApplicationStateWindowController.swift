//
//  ApplicationStateWindowController.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/9/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Cocoa

class ApplicationStateWindowController: NSWindowController {

    override var document: AnyObject? {
        didSet {
            let viewController = window!.contentViewController as! ApplicationStateViewController
            viewController.applicationState = (document as! ApplicationStateDocument).applicationState
        }
    }
}
