//
//  FileViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/07/20.
//  Copyright © 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa
import SwiftyJSON

class FileViewController: NSViewController, NSOutlineViewDelegate {
    
    var syncthingSystem: SyncthingCommunication {
        let parentView: InspectorTabViewController = self.parentViewController as! InspectorTabViewController
        return parentView.syncthingSystem
    }
    var folder: SyncthingFolder {
        let parentView: InspectorTabViewController = self.parentViewController as! InspectorTabViewController
        return parentView.folder
    }

    @IBOutlet weak var outlineFileListView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // We create a data source for our outline view
        FileOutlineDataSource(with: self.syncthingSystem, forFolder: self.folder.id)
    }
}

class FileOutlineDataSource: NSObject, NSOutlineViewDataSource {
    var syncthingSystem: SyncthingCommunication
    var folderID: String
    
    init(with: SyncthingCommunication, forFolder: String) {
        self.syncthingSystem = with
        self.folderID = forFolder
        // Initialize FileSystemItem
        
        FileSystemItem.rootItem = FileSystemItem(path: "\(folderID)", parent: nil, isAFolder: true)
        syncthingSystem.getDbBrowse(forFolder, levels: nil, prefix: nil) { (response) -> () in
            FileSystemItem.files_json = response
            FileSystemItem.readFileTree()
        }

    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 0// (FileSystemItem.rootItem.numberOfChildren == nil) ? 0 : FileSystemItem.rootItem.numberOfChildren!
        } else {
            let object = item as! FileSystemItem
            return (object.numberOfChildren == nil) ? -1 : object.numberOfChildren!
        }
    }

    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let object = item as! FileSystemItem
        return (object.numberOfChildren != nil)
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return FileSystemItem.rootItem.childAtIndex(index)
        } else {
            let object = item as! FileSystemItem
            return object.childAtIndex(index)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        if item == nil {
            return "\(folderID)"
        } else {
            let object = item as! FileSystemItem
            return object.relativePath
        }
    }
    

}