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
    func resetView(displayWheel initializing: Bool) -> ()
}

/** 
The Main View controller from the main Window
*/
class ViewController: NSViewController, SyncthingDisplayDelegate {
    
    var syncthingSystem = SyncthingCommunication()
    var parentWindowController: MainWindowController!
    var delegateInteraction: SyncthingInteractionDelegate!
    
    // MARK: IBOutlets
    @IBOutlet weak var folderTableView: NSTableView!
    @IBOutlet weak var spinningWheel: NSProgressIndicator!
    
    // MARK: IBActions
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        print("button Pressed by \(sender)")
        syncthingSystem.fetchEverything()
    }
    
    @IBAction func useNewSettingsForRemote(sender: NSPopUpButton) {
        resetSyncthing()
        loadSettings(to: syncthingSystem, forClient: sender.indexOfSelectedItem)
        resetView(displayWheel: true)
        syncthingSystem.initiate()
    }
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        //parentWindowController = self.view.window!.windowController as! MainWindowController
        
        /* // To reset settings on your machine, use this:
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
        */
        /** Available settings:
- `Clients`: an Array of clients with 4 parameters: Name, IPaddress, Port and APIkey
- `RefreshRate`: Refresh rate, in seconds
- `ResfreshRateBackground`: Refresh rate when the app is in background, in seconds
        */
        
            // Set up the table appearance
        folderTableView.hidden = true
        spinningWheel.hidden = false
        spinningWheel.startAnimation(nil)
            // Warm up the Syncthing Backend
        syncthingSystem.delegateForDisplay = self
        loadSettings(to: syncthingSystem, forClient: 0)
            // Ready
        syncthingSystem.initiate()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: NSUserDefaults
    
    func loadSettings(to syncthing: SyncthingCommunication, forClient index: Int) {
        let userPreferences = NSUserDefaults.standardUserDefaults()
        // Register defaults so it doesn't crash on first launch
        // I did this twice (in MainWindowController.swift too) because I can't
        NSUserDefaults.standardUserDefaults().registerDefaults(
            ["Clients": [["Name": "Local Syncthing",
                "BaseURL": "http://localhost",
                "Port": 8080,
                "APIkey": ""]],
                "RefreshRate": 1,
                "RefreshRateBackground": 20])
        syncthing.updateInterval = NSTimeInterval(userPreferences.integerForKey("RefreshRate"))
        let client = (userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>])[index]
        syncthing.baseUrlString = client["BaseURL"] as! String
        syncthing.port = client["Port"] as! Int
        syncthing.apiKey = client["APIkey"] as? String
    }
    
    // MARK: Delegate
    
    func reloadData() -> () {
        spinningWheel.stopAnimation(nil)
        spinningWheel.hidden = true
        folderTableView.hidden = false
        reloadTable()
    }
    
    func reloadTable() {
        let selectedRow: Int = folderTableView.selectedRow
        folderTableView.reloadData()
        folderTableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
    }
    
    func resetView(displayWheel initializing: Bool) -> () {
        spinningWheel.hidden = !initializing
        folderTableView.hidden = initializing
        if initializing {
            spinningWheel.startAnimation(nil)
        } else {
            spinningWheel.stopAnimation(nil)
            reloadTable()
        }
    }
    
    private func resetSyncthing() {
        self.syncthingSystem.stopTimers()
        self.syncthingSystem = SyncthingCommunication()
        syncthingSystem.delegateForDisplay = self
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
