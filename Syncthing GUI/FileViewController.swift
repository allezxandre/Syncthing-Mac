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
        outlineFileListView.setDataSource(FileOutlineDataSource(with: self.syncthingSystem, forFolder: self.folder.id))
    }
}

class FileOutlineDataSource: NSObject, NSOutlineViewDataSource {
    var syncthingSystem: SyncthingCommunication
    var folderID: String
    
    init(with: SyncthingCommunication, forFolder: String) {
        self.syncthingSystem = with
        self.folderID = forFolder
        FileSystemItem.rootItem = FileSystemItem(path: "\(folderID)/", parent: nil)
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 1
        } else {
            let object = item as! FileSystemItem
            return (object.numberOfChildren == nil) ? 0 : object.numberOfChildren!
        }
    }

    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let object = item as! FileSystemItem
        return (object.numberOfChildren != nil)
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return FileSystemItem.rootItem!
        } else {
            let object = item as! FileSystemItem
            return object.childAtIndex(index)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        if item == nil {
            return "/"
        } else {
            let object = item as! FileSystemItem
            return object.relativePath
        }
    }
    

}

class FileSystemItem: NSObject {
    var relativePath: String
    var parent: FileSystemItem?
    var children: NSMutableArray
    
    static var rootItem: FileSystemItem? = nil
    
    init(path: String, parent: FileSystemItem?) {
        self.relativePath = path.lastPathComponent
        self.parent = parent
        self.children = NSMutableArray()
    }
    
    var fullPath: String {
        if parent == nil {
            return relativePath
        } else {
            return parent!.fullPath.stringByAppendingPathComponent(relativePath)
        }
    }
    
    func childAtIndex(n: Int) -> FileSystemItem {
        return children.objectAtIndex(n) as! FileSystemItem
    }
    
    var numberOfChildren: Int? {
        let tmp = self.children
        return (tmp == NSMutableArray()) ? nil : (tmp.count)
    }
}