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
        // Initialize FileSystemItem
        FileSystemItem.rootItem = FileSystemItem(path: "\(folderID)", parent: nil, isAFolder: true)
        syncthingSystem.getDbBrowse(forFolder, levels: nil, prefix: nil) { (response) -> () in
            FileSystemItem.files_json = response
            FileSystemItem.readFileTree()
        }
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return (FileSystemItem.rootItem.numberOfChildren == nil) ? 0 : FileSystemItem.rootItem.numberOfChildren!
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
            return FileSystemItem.rootItem
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

class FileSystemItem: NSObject {
    var relativePath: String
    var parent: FileSystemItem?
    var children: [FileSystemItem]?
    
    static var initialized: Bool = false
    static var files_json: JSON!
    static var rootItem: FileSystemItem!
    
    init(path: String, parent: FileSystemItem?, isAFolder: Bool) {
        self.relativePath = path.lastPathComponent
        self.parent = parent
        if isAFolder {
            self.children = [FileSystemItem]()
        } else {
            self.children = nil
        }
    }
    
    /** Reads the JSON file tree using `files_json` and `rootItem` */
    class func readFileTree() -> () {
        // We suppose that `files_json` has been loaded and `rootItem` has been initialized
        for (key, subjson): (String, JSON) in files_json {
            rootItem.interpretTypeOfChild(name: key, json: subjson)
        }
        initialized = true
    }
    
    /** Interprets a JSON to build the FileSystemTree */
    private func interpretTypeOfChild(name name: String, json: JSON) {
        if let _ = json[1].int {
            // We have a size, so this is a file
            // Create item
            let file = FileSystemItem(path: name, parent: parent, isAFolder: false)
            // Add it to list of childrens of the parent folder
            self.children! += [file]
        } else {
            // We don't have a size, so this is a folder
            // Create item
            let file = FileSystemItem(path: name, parent: parent, isAFolder: true)
            // Add it to list of childrens of the parent folder
            self.children! += [file]
            // loop through childrens
            for (key, subjson): (String, JSON) in json {
                file.interpretTypeOfChild(name: key, json: subjson)
            }
        }
    }
    
    /** Returns the full path of an item by recursively appending its parents `relativePath`s */
    var fullPath: String {
        if parent == nil {
            return relativePath
        } else {
            return parent!.fullPath.stringByAppendingPathComponent(relativePath)
        }
    }
    
    func childAtIndex(n: Int) -> FileSystemItem {
        if !FileSystemItem.initialized {
            return FileSystemItem.rootItem
        }
        assert(self.children != nil, "`self.children` is nil. Looks like you're trying to access the childrens of a file")
        return self.children![n]
    }
    
    var numberOfChildren: Int? {
        if !FileSystemItem.initialized {
            return nil
        }
        return (self.children == nil) ? nil : (self.children!.count)
    }
}