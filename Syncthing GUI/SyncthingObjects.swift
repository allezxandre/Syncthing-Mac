//
//  SyncthingObjects.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/06/01.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Foundation
import AppKit

// MARK: Syncthing subclasses

class Connection : Equatable, Printable {
    var deviceID: String
    var ipAddress: String
    var bytesIn: Int = 0
    var bytesOut: Int = 0
    var description: String { // used by println -> http://vperi.com/2014/06/04/textual-representation-for-classes-in-swift/
        return "[\n Device ID: '\(deviceID)',\n IP Address: '\(ipAddress)',\n Bytes In: \(bytesIn),\n Bytes Out: \(bytesOut)\n]"
    }
    init(thisDeviceID: String, thisIpAddress: String) {
        self.deviceID = thisDeviceID
        self.ipAddress = thisIpAddress
    }
    init(thisDeviceID: String, thisIpAddress: String, bytesIn: Int, bytesOut: Int) {
        self.deviceID = thisDeviceID
        self.ipAddress = thisIpAddress
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

class SyncthingError: Equatable, Printable {
    var time: NSDate
    var errorDescription: String
    var description: String {
        return "\(time) — \(errorDescription)"
    }
    init(error: String, withDate: NSDate) {
        self.errorDescription = error
        self.time = withDate
    }
    init(error: String, withDateString: String) {
        self.errorDescription = error
        var dateFormatter = NSDateFormatter()
        // As from Wikipedia:
        // http://en.wikipedia.org/wiki/ISO_8601
        // http://fr.wikipedia.org/wiki/ISO_8601
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSSzzzzzz"
        if let withDate = dateFormatter.dateFromString(withDateString) {
            self.time = withDate
        } else {
            self.time = NSDate()
            NSLog("Error formatting date string: '\(withDateString)'")
        }
    }
}

struct SyncthingStatus: Printable {
    var alloc: Int
    var cpuPercent: Double
    var extAnnounceOK: Dictionary<String, Bool>
    var goRoutines: Int
    var myID: String
    let pathSeparator = "/"
    var sys: Int
    var tilde: String
    var description: String {
        return "[alloc: \(self.alloc), cpuPercent: \(self.cpuPercent), extAnnounceOK: \(self.extAnnounceOK), goRoutines: \(self.goRoutines), myID: \"\(self.myID)\", pathSeparator: \"\(self.pathSeparator)\", sys: \(self.sys), tilde: \"\(self.tilde)\"]"
    }
}

/**
    SyncthingFolders are stored in a dictionnary like `Dictionary<ID,SyncthingFolder>`, so the `id` variable from the `SyncthingFolder` class is a redundant information, but this is intended.
*/
class SyncthingFolder: Equatable, Printable {
    var id: String
    var path: NSURL
    var devices: [String]
    var idle: Bool = false
    var inSyncBytes: Int? = nil
    var outOfSyncBytes: Int? = nil
    var folderSize: Int? {
        if (inSyncBytes == nil)||(outOfSyncBytes == nil) {
            return nil
        } else {
            return inSyncBytes! + outOfSyncBytes!
        }
    }
    var syncPercentage: Double? {
        if (inSyncBytes == nil)||(folderSize == nil) {
            return nil
        } else {
            return Double(inSyncBytes!)/Double(folderSize!) * Double(100)
        }
    }
    var description: String {
        return "\(id)  (\(path)) - Devices: \(devices)"
    }
    
    init(id withId: String, forPathString: String, withDevices: [String]) {
        self.id = withId
        if let location = NSURL(fileURLWithPath: forPathString.stringByExpandingTildeInPath, isDirectory: true) {
            self.path = location
        } else {
            NSLog("Error parsing Folder Path: \(forPathString)")
            self.path = NSURL()
        }
        self.devices = withDevices
    }
}

// MARK: Equatable global functions


func ==(lhs: Connection, rhs: Connection) -> Bool {
    return (lhs.deviceID == rhs.deviceID)
}
func ==(lhs: SyncthingError, rhs: SyncthingError) -> Bool {
    return (lhs.time == rhs.time) && (lhs.errorDescription == rhs.errorDescription)
}
func ==(lhs: SyncthingFolder, rhs: SyncthingFolder) -> Bool {
    return (lhs.id == rhs.id) && (lhs.path == rhs.path)
}

// MARK: Syncthing Object

class Syncthing: Printable {
    // Variables
    var system: SyncthingStatus?
    var foldersInSync = Dictionary<String,SyncthingFolder>()
    /** This variable stores all available folders */
    var foldersList: [String] { // If you have duplicate folders, here's the culprit
        var list = [String]()
        for (id: String, _: SyncthingFolder) in self.foldersInSync {
            list += [id]
        }
        return list
    }
    var connections = [Connection]()
    var errors = [SyncthingError]()
    /** A `String` describing the newest version. If the system is up-to-date, this is a `nil` */
    var possibleUpgrade: String?
    var configInSync: Bool = false
    // For Printable:
    var description: String {
        var inSync: String = (configInSync) ? "In Sync":"Not In Sync"
        var updatable: String = (possibleUpgrade != nil) ? "An upgrade to \(possibleUpgrade) is available":"Syncthing is up-to-date"
        // connections
        var connectionsString = "{\n "
        for connection in connections {
            connectionsString += " \(connection)\n"
        }
        connectionsString += "}"
        // errors
        var errorsString = "{\n"
        for error in errors {
            errorsString += " [\(error)]\n"
        }
        errorsString += "}"
        // folders
        var foldersString = "{\n"
        for folder in foldersInSync {
            foldersString += " [\(folder)]\n"
        }
        foldersString += "}"
        return "System status: \(system)\n\(updatable)\n\(inSync)\nConnections :\(connectionsString)\nFolders: \(foldersString)\nErrors :\(errorsString)"
    }
    
    // Functions
    func revealFolder(#id: String) {
        if let fileToReveal: NSURL = self.foldersInSync[id]?.path {
            // http://stackoverflow.com/a/7658305/3997690
            println("Revealing file: \(fileToReveal)")
            NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([fileToReveal] as [NSURL])
        } else {
            NSLog("Error revealing folder with ID '\(id)'")
        }
    }
}