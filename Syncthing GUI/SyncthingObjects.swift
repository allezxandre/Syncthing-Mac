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

class Connection : Equatable, CustomStringConvertible {
    var deviceID: String
    var ipAddress: String
    var bytesIn: Int = 0
    var bytesOut: Int = 0
    var description: String { // used by print -> http://vperi.com/2014/06/04/textual-representation-for-classes-in-swift/
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

class SyncthingError: Equatable, CustomStringConvertible {
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
        let dateFormatter = NSDateFormatter()
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

struct SyncthingStatus: CustomStringConvertible {
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
class SyncthingFolder: Equatable, CustomStringConvertible {
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
    var syncRatio: Double? {
        if (inSyncBytes == nil)||(folderSize == nil) {
            return nil
        } else {
            return Double(inSyncBytes!)/Double(folderSize!)
        }
    }
    
    var syncPercentage: Double? {
        if (syncRatio == nil) {
            return nil
        } else {
            return syncRatio! * Double(100)
        }
    }
    
    var description: String {
        return "\(id)  (\(path)) - Devices: \(devices)"
    }
    
    init(id withId: String, forPathString: String, withDevices: [String]) {
        self.id = withId
        self.path = NSURL(fileURLWithPath: forPathString.stringByExpandingTildeInPath, isDirectory: true)
        self.devices = withDevices
    }
}

class File {
    var name: String
    var path: NSURL
    var synced: Bool? = nil
    
    init(withName: String, atPath: NSURL) {
        self.name = withName
        self.path = atPath
    }
}

/** An enumeration of [Syncthing events](http://docs.syncthing.net/dev/events.html#events) types */
enum EventType {
    case ConfigSaved, DeviceConnected, DeviceDisconnected, DeviceDiscovered, DeviceRejected, DownloadProgress, FolderCompletion, FolderErrors, FolderRejected, FolderSummary, ItemFinished, ItemStarted, LocalIndexUpdated, Ping, RemoteIndexUpdated, Starting, StartupCompleted, StateChanged, Dummy
    static func getTypeFromString(string: String) -> EventType {
        switch string {
        case "ConfigSaved":
            return .ConfigSaved
        case "DeviceConnected":
            return .DeviceConnected
        case "DeviceDisconnected":
            return .DeviceDisconnected
        case "DeviceDiscovered":
            return .DeviceDiscovered
        case "DeviceRejected":
            return .DeviceRejected
        case "DownloadProgress":
            return .DownloadProgress
        case "FolderCompletion":
            return .FolderCompletion
        case "FolderErrors":
            return .FolderErrors
        case "FolderRejected":
            return .FolderRejected
        case "FolderSummary":
            return .FolderSummary
        case "ItemFinished":
            return .ItemFinished
        case "ItemStarted":
            return .ItemStarted
        case "LocalIndexUpdated":
            return .LocalIndexUpdated
        case "Ping":
            return .Ping
        case "RemoteIndexUpdated":
            return .RemoteIndexUpdated
        case "Starting":
            return .Starting
        case "StartupCompleted":
            return .StartupCompleted
        case "StateChanged":
            return .StateChanged
        default:
            return .Dummy
        }
    }
}

class SyncthingEvent: CustomStringConvertible {
    var id: Int
    var time: NSDate
    let type: EventType
    var data: [String: String]?
    var description: String {
        return "Event #\(id) - \(data)"
    }
    
    init(id: Int, time: NSDate, type: EventType, data: [String: String]?) {
        self.id = id
        self.time = time
        self.type = type
        self.data = data
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

class Syncthing: CustomStringConvertible {
    // Variables
    var system: SyncthingStatus?
    var foldersInSync = Dictionary<String,SyncthingFolder>()
    /** This variable stores all available folders */
    var foldersList: [String] { // If you have duplicate folders, here's the culprit
        var list = [String]()
        for (id, _): (String, SyncthingFolder) in self.foldersInSync {
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
        let inSync: String = (configInSync) ? "In Sync":"Not In Sync"
        let updatable: String = (possibleUpgrade != nil) ? "An upgrade to \(possibleUpgrade) is available":"Syncthing is up-to-date"
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
    func revealFolder(id id: String) {
        if let fileToReveal: NSURL = self.foldersInSync[id]?.path {
            // http://stackoverflow.com/a/7658305/3997690
            print("Revealing file: \(fileToReveal)")
            NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([fileToReveal] as [NSURL])
        } else {
            NSLog("Error revealing folder with ID '\(id)'")
        }
    }
}