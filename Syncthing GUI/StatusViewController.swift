//
//  StatusViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/07/20.
//  Copyright © 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class StatusViewController: NSViewController {
    
    var syncthingSystem: SyncthingCommunication {
        let parentView: InspectorTabViewController = self.parentViewController as! InspectorTabViewController
        return parentView.syncthingSystem
    }
    var folder: SyncthingFolder {
        let parentView: InspectorTabViewController = self.parentViewController as! InspectorTabViewController
        return parentView.folder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
