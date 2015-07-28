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
    
    override func windowDidLoad() {
        super.windowDidLoad()
        loadRemoteListFromSettings()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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
    
    @IBAction func remoteListButtonChange(sender: NSPopUpButton) {
        let newRemote = sender.titleOfSelectedItem!
        print("User selected \(newRemote) as the syncthing system")
    }

}
