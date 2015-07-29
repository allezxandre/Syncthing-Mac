//
//  SettingsViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/07/27.
//  Copyright © 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {
    
    let userPreferences = NSUserDefaults.standardUserDefaults()
    
    // MARK: IBOutlets
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var addressTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var apiKeyTextField: NSSecureTextField!
    @IBOutlet weak var removeNsButton: NSButton!
    
    @IBOutlet weak var foregroundIntervalTextField: NSTextField!
    @IBOutlet weak var backgroundIntervalTextField: NSTextField!
    
    // MARK: IBActions
    @IBAction func addNewRemoteButton(sender: NSButton) {
        var clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        clients += [[
            "Name": "Default",
            "BaseURL": "http://localhost",
            "Port": 8080,
            "APIkey": ""]]
        userPreferences.setObject(clients, forKey: "Clients")
        // Reload table
        tableView.reloadData()
        // select last row
        tableView.selectRowIndexes(NSIndexSet(index: (clients.count - 1)), byExtendingSelection: false)
    }
    
    @IBAction func removeRemoteButtonPressed(sender: NSButton) {
        let clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        var newClients = [Dictionary<String, AnyObject>]()
        for (var i = 0; i<clients.count; i++) {
            if (i != tableView.selectedRow) {
                newClients += [clients[i]]
            }
        }
        userPreferences.setObject(newClients, forKey: "Clients")
        // Reload table
        tableView.reloadData()
        // select last row
        tableView.selectRowIndexes(NSIndexSet(index: (newClients.count - 1)), byExtendingSelection: false)
    }
    
    @IBAction func endEditingName(sender: NSTextField) {
        let ok = verifyName(sender.stringValue)
        if ok {
            saveSettings()
            // We also need to update the table row
            let selectedIndex = NSIndexSet(index: tableView.selectedRow)
            tableView.reloadDataForRowIndexes(selectedIndex, columnIndexes: NSIndexSet(index: 0))
        }
    }
    @IBAction func endEditingProperty(sender: NSTextField) {
        saveSettings()
    }
    @IBAction func endEditingApiKey(sender: NSSecureTextField) {
        saveSettings()
    }
    @IBAction func endEditingInterval(sender: NSTextField) {
        saveUpdateIntervalFields()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Link with dataSource
        // (delegate was already set with Interface Builder)
        let dataSource = tableView.delegate() as! TableViewDataSource
        dataSource.settingsViewController = self
        // Disable all UI elements
        enableAll(!(tableView.selectedRow == -1))
        // load data to update interval fields
        loadUpdateIntervalFields()
    }
    
    /** Handle a change in the TableView selection */
    func changedSelection() {
        let selectedClientIndex = tableView.selectedRow
        if selectedClientIndex == -1 {
            enableAll(false)
        } else {
            enableAll(true)
            loadPanel(forClientIndex: selectedClientIndex)
        }
    }
    
    /** Make sure the name is not already in use */
    private func verifyName(name: String) -> Bool {
        // NOT IMPLEMENTED
        return true
    }
    
    /** Load settings for the selected remote using data from NSUserDefaults */
    private func loadPanel(forClientIndex index: Int) {
        let clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        let client = clients[index]
        nameField.stringValue = client["Name"] as! String
        addressTextField.stringValue = client["BaseURL"] as! String
        portTextField.stringValue = String(client["Port"] as! Int)
        apiKeyTextField.stringValue = client["APIkey"] as! String
    }
    
    /** Load settings for the update interval (bottom panel in settings) */
    func loadUpdateIntervalFields() {
        foregroundIntervalTextField.stringValue = String(userPreferences.integerForKey("RefreshRate"))
        backgroundIntervalTextField.stringValue = String(userPreferences.integerForKey("RefreshRateBackground"))
    }
    
    /** Save settings from all fields in the currently selected table row */
    private func saveSettings() {
        let clientIndex = tableView.selectedRow
        // This function needs a selectedRow
        assert(clientIndex != -1)
        var clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        clients[clientIndex]["Name"] = nameField.stringValue
        clients[clientIndex]["BaseURL"] = addressTextField.stringValue
        if let port = Int(portTextField.stringValue) {
            clients[clientIndex]["Port"] = port
        } else {
            clients[clientIndex]["Port"] = 0
            print("Port: \(Int(portTextField.stringValue))")
        }
        clients[clientIndex]["APIkey"] = apiKeyTextField.stringValue
        userPreferences.setObject(clients, forKey: "Clients")
    }
    
    /** Save settings for the update interval (bottom panel in settings) */
    func saveUpdateIntervalFields() {
        if let interval = Int(foregroundIntervalTextField.stringValue) {
            userPreferences.setInteger(interval, forKey: "RefreshRate")
        } else {
            userPreferences.setInteger(1, forKey: "RefreshRate")
        }
        if let interval = Int(backgroundIntervalTextField.stringValue) {
            userPreferences.setInteger(interval, forKey: "RefreshRateBackground")
        } else {
            userPreferences.setInteger(20, forKey: "RefreshRateBackground")
        }
        
    }
    
    /** Enable/disable all elements in the right panel according to `enable` */
    private func enableAll(enable: Bool) {
        nameField.enabled = enable
        addressTextField.enabled = enable
        portTextField.enabled = enable
        apiKeyTextField.enabled = enable
        let clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        removeNsButton.enabled = (enable && clients.count > 1)
    }
    
}

class TableViewDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    let userPreferences = NSUserDefaults.standardUserDefaults()
    var settingsViewController: SettingsViewController!
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        let clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        return clients.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let clients = userPreferences.objectForKey("Clients") as! [Dictionary<String, AnyObject>]
        let string = clients[row]["Name"] as! String
        print(string)
        let cell = tableView.makeViewWithIdentifier("RemoteListCellView", owner: nil) as! NSTableCellView
        cell.textField?.stringValue = string
        return cell
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        settingsViewController.changedSelection()
    }
    
   
}