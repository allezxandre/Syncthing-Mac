//
//  ViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/05/14.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa
import AppKit

//
//                     Start in this file
//             if you want to understand the logic
//               behind Syncthing Remote for Mac
//


protocol SyncthingDisplayDelegate {
    func reloadData() -> ()
}

/** 
The Main View controller from the main Window
*/
class ViewController: NSViewController, SyncthingDisplayDelegate {
    
    var syncthingSystem = SyncthingCommunication()
    
    var delegateInteraction: SyncthingInteractionDelegate!
    
    // MARK: IBOutlets
    @IBOutlet weak var folderTableView: NSTableView!
    @IBOutlet weak var spinningWheel: NSProgressIndicator!
    
    // MARK: IBActions
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        print("button Pressed by \(sender)")
        syncthingSystem.fetchEverything()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
            // Load settings
        
        /* // To reset settings on your machine, use this:
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        */
        /** Available settings:
- `Clients`: an Array of clients with 4 parameters: Name, IPaddress, Port and APIkey
- `RefreshRate`: Refresh rate, in seconds
- `ResfreshRateBackground`: Refresh rate when the app is in background, in seconds
        */
        //let userPreferences = NSUserDefaults.standardUserDefaults()
        
            // Set up the table appearance
        folderTableView.hidden = true
        spinningWheel.hidden = false
        spinningWheel.startAnimation(nil)
            // Warm up the Syncthing Backend
        syncthingSystem.delegateForDisplay = self
        // syncthingSystem.baseUrlString = firstClient["IPaddress"]
        //syncthingSystem.port =
        // syncthingSystem.apiKey =
            // Ready
        syncthingSystem.fetchEverything()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: NSUserDefaults
    
    func loadSettings(to syncthing: SyncthingCommunication) {
        
    }
    
    // MARK: Delegate
    
    func reloadData() -> () {
        spinningWheel.stopAnimation(nil)
        spinningWheel.hidden = true
        folderTableView.hidden = false
        folderTableView.reloadData()
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        //let source: ViewController = segue.sourceController as! ViewController
        let button = sender as! NSButton
        let folderView: FolderView = button.superview as! FolderView
        let destination: InspectorTabViewController = segue.destinationController as! InspectorTabViewController
        destination.folder = folderView.folder
        destination.syncthingSystem = syncthingSystem
    }
}

// http://nscurious.com/2015/04/08/using-view-based-nstableview-with-swift/

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if syncthingSystem.syncthing.foldersInSync.count > 0 {
            return syncthingSystem.syncthing.foldersInSync.count
        } else {
            return 1
        }
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if syncthingSystem.syncthing.foldersInSync.count > 0 {
            let cell = tableView.makeViewWithIdentifier("syncthingFolderView", owner: nil) as! FolderView
            return cell.frame.height
        } else {
            let cell = tableView.makeViewWithIdentifier("noSyncthingFolderView", owner: nil)
            return cell!.frame.height
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if syncthingSystem.syncthing.foldersInSync.count < 1 {
            return tableView.makeViewWithIdentifier("noSyncthingFolderView", owner: nil)
        }
        let cell = tableView.makeViewWithIdentifier("syncthingFolderView", owner: nil) as! FolderView
        let folderId = syncthingSystem.syncthing.foldersList[row]
        let folder = syncthingSystem.syncthing.foldersInSync[folderId]
        cell.folder = folder!
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
                let formatter = NSNumberFormatter()
                formatter.numberStyle = .PercentStyle
                cell.progressPercentageTextField.stringValue = formatter.stringFromNumber(folder!.syncRatio!)!
            }
        }
            cell.delegateInteraction = self.syncthingSystem
        
        return cell
    }
}
