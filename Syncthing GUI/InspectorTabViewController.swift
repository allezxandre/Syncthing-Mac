//
//  InspectorTabViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/07/20.
//  Copyright © 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class InspectorTabViewController: NSTabViewController {
    
    var syncthingSystem: SyncthingCommunication!
    var folder: SyncthingFolder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
