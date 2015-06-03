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
    
    var synchtingSystem = SyncthingCommunication()
    
    var delegateInteraction: SyncthingInteractionDelegate!
    
    // MARK: IBOutlets
    @IBOutlet weak var folderTableView: NSTableView!
    
    // MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
            // Set up the table appearance
        self.folderTableView.backgroundColor = NSColor.clearColor()
        self.folderTableView.enclosingScrollView?.drawsBackground = false
            // Warm up the Syncthing Backend
        synchtingSystem.delegateForDisplay = self
        synchtingSystem.fetchEverything()
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
        folderTableView.reloadData()
    }
}

// http://nscurious.com/2015/04/08/using-view-based-nstableview-with-swift/

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return synchtingSystem.syncthing.foldersInSync.count
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let cell = tableView.makeViewWithIdentifier("FolderView", owner: self) as! FolderView
        return cell.frame.height
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("FolderView", owner: self) as! FolderView
        let folderId = synchtingSystem.syncthing.foldersList[row]
        let folder = synchtingSystem.syncthing.foldersInSync[folderId]
        // set folder display
            cell.folderName.stringValue = folder!.id
            cell.folderPath.URL = folder!.path
            cell.folderProgressIndicator.startAnimation(nil)
            cell.delegateInteraction = self.synchtingSystem
        
        return cell
    }
}
