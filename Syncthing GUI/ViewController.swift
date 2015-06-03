//
//  ViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/05/14.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa
import AppKit

protocol SyncthingDisplayDelegate {
    func reloadData() -> ()
}

class ViewController: NSViewController, SyncthingDisplayDelegate {
    
    var syncthingSystem = SyncthingCommunication()
    
    var delegateInteraction: SyncthingInteractionDelegate!
    
    // MARK: IBOutlets
    @IBOutlet weak var folderTableView: NSTableView!
    @IBOutlet weak var spinningWheel: NSProgressIndicator!
    
    // MARK: IBActions
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        println("button Pressed by \(sender)")
        syncthingSystem.fetchEverything()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
            // Set up the table appearance
        folderTableView.hidden = true
        spinningWheel.hidden = false
        spinningWheel.startAnimation(nil)
        self.folderTableView.backgroundColor = NSColor.clearColor()
        self.folderTableView.enclosingScrollView?.drawsBackground = false
            // Warm up the Syncthing Backend
        syncthingSystem.delegateForDisplay = self
        syncthingSystem.fetchEverything()
            // Load nib to the TableView
        let nib = NSNib(nibNamed: "FolderView", bundle: NSBundle.mainBundle())
        folderTableView.registerNib(nib!, forIdentifier: "FolderView")
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: Delegate
    
    func reloadData() -> () {
        spinningWheel.stopAnimation(nil)
        spinningWheel.hidden = true
        folderTableView.hidden = false
        folderTableView.reloadData()
    }
}

// http://nscurious.com/2015/04/08/using-view-based-nstableview-with-swift/

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return syncthingSystem.syncthing.foldersInSync.count
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let cell = tableView.makeViewWithIdentifier("FolderView", owner: self) as! FolderView
        return cell.frame.height
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("FolderView", owner: self) as! FolderView
        let folderId = syncthingSystem.syncthing.foldersList[row]
        let folder = syncthingSystem.syncthing.foldersInSync[folderId]
        // set folder display
            cell.folderName.stringValue = folder!.id
            cell.folderPath.URL = folder!.path
            cell.syncIdle = folder!.idle
        if !folder!.idle {
            // folder is not idle
            if folder?.syncPercentage == nil {
                cell.folderProgressIndicator.indeterminate = true
                cell.folderProgressIndicator.startAnimation(nil)
            } else {
                cell.folderProgressIndicator.stopAnimation(nil)
                cell.folderProgressIndicator.indeterminate = false
                cell.folderProgressIndicator.doubleValue = folder!.syncPercentage!
            }
        }
            cell.delegateInteraction = self.syncthingSystem
        
        return cell
    }
}
