//
//  SyncthingObjects.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/06/01.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Foundation

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

// Equatable global functions


func ==(lhs: Connection, rhs: Connection) -> Bool {
    return (lhs.deviceID == rhs.deviceID)
}

func ==(lhs: SyncthingError, rhs: SyncthingError) -> Bool {
    return (lhs.time == rhs.time) && (lhs.errorDescription == rhs.errorDescription)
}

// Syncthing Object

struct Syncthing: Printable {
    var connections = [Connection]()
    var errors = [SyncthingError]()
    var configInSync: Bool = false
    var description: String {
        var inSync: String = (configInSync) ? "In Sync":"Not In Sync"
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
        return "\(inSync)\nConnections :\(connectionsString)\nErrors :\(errorsString)"
    }
}