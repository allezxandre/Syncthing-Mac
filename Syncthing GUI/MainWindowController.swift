//
//  MainWindowController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/07/20.
//  Copyright © 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    @IBOutlet weak var remoteList: NSPopUpButton!
    
    var mainViewController: ViewController!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        loadRemoteListFromSettings()
        mainViewController = self.window!.contentViewController! as! ViewController
    }
    
    func loadRemoteListFromSettings() {
        let userPreferences = NSUserDefaults.standardUserDefaults()
        // Register user default on first launch
        userPreferences.registerDefaults(
            ["Clients": [["Name": "Local Syncthing",
                "BaseURL": "http://localhost",
                "Port": 8080,
                "APIkey": ""]],
                "RefreshRate": 1,
                "RefreshRateBackground": 20])
        // Get the client list
        let clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        // Update the toolbar list
        remoteList.removeAllItems()
        for client in clients {
            let nameOfRemote: String = client["Name"] as! String
            remoteList.addItemWithTitle(nameOfRemote)
        }
    }

}
