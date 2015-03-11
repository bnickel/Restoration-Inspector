//
//  ViewController.swift
//  Restoration Inspector
//
//  Created by Brian Nickel on 3/9/15.
//  Copyright (c) 2015 Stack Exchange, Inc. All rights reserved.
//

import Cocoa
import KeyedArchiveInspector

class ApplicationStateViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    weak var applicationState:ApplicationState? {
        didSet {
            textView.string = applicationState?.description ?? "No saved state."
            textView.font = NSFont(name: "Menlo", size: 12)
        }
    }
}

