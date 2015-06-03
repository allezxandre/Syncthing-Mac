//
//  FolderView.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/06/03.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class FolderView: NSView {
    
    var delegateInteraction: SyncthingInteractionDelegate!
    
    // MARK: IBOutlets
    @IBOutlet weak var folderName: NSTextField!
    @IBOutlet weak var folderPath: NSPathControl!
    @IBOutlet weak var folderProgressIndicator: NSProgressIndicator!
    
    // MARK: IBActions
    @IBAction func revealFolder(sender: NSButton) {
        self.delegateInteraction.openFolder(folderName.stringValue)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
}
