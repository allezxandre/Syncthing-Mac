//
//  FolderCellView.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/06/04.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class FolderCellView: NSTableCellView {
    
    override var backgroundStyle:NSBackgroundStyle{
        didSet {
            if backgroundStyle == .Dark{
                self.layer!.backgroundColor = NSColor.clearColor().CGColor
            } else {
                self.layer!.backgroundColor = NSColor.clearColor().CGColor
            }
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
}
