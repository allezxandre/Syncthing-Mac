//
//  FolderViewController.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/06/03.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Cocoa

class FolderViewController: NSViewController {

    @IBOutlet weak var folderName: NSTextField!
    @IBOutlet weak var folderPath: NSPathControl!
    @IBOutlet weak var folderProgressIndicator: NSProgressIndicator!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
