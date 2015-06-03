//
//  RestApi.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/05/14.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol SyncthingInteractionDelegate {
    func openFolder(id: String) -> ()
}

// As from Syncthing's wiki page: https://github.com/syncthing/syncthing/wiki/REST-Interface
class SyncthingCommunication: SyncthingInteractionDelegate {
    // MARK: Delegate
    var delegateForDisplay: SyncthingDisplayDelegate!
    // MARK: Variables
    var baseUrl = "http://localhost"
    var port: Int = 8080
    var syncthing: Syncthing = Syncthing()
        // Boolean variables
    /** Is true when the Syncthing server is answering Ping requests */
    var systemIsOnline = true
    
    var gotConfig = false
    var gotSyncStatus = false
    var gotConnections = false
    var gotErrors = false
    var gotSystemStatus = false
    /** Returns `true` if everything has been fetched */
    var fetchedAll: Bool {
        return (gotConfig && gotSyncStatus && gotConnections && gotErrors && gotSystemStatus)
    }
    
    // MARK: Basic class operations
    
    func changeUrl(to: String) {
        self.baseUrl = to
    }
    
    func changePort(to: Int) {
        self.port = to
    }
    
    // MARK: Getters
    
        // System Endpoints
    
    func fetchEverything() {
        pingSyncthingServer()
        getSystemStatus()
        getConfig()
        getSyncStatus()
        getConnections()
        getErrors()
    }
    
    func pingSyncthingServer() {
        // http://docs.syncthing.net/rest/system-ping-get.html
        httpGetRequest("/rest/system/ping", returnFunction: { (reponse:JSON) -> () in
            self.systemIsOnline = (reponse["ping"].stringValue == "pong")
            println("System is online: \(self.systemIsOnline)")
        })
    }
    
    func getConfig() {
        // http://docs.syncthing.net/rest/system-config-get.html
        httpGetRequest("/rest/system/config", returnFunction: handleConfig)
    }
    
    func getSyncStatus() {
        // http://docs.syncthing.net/rest/system-config-insync-get.html
        httpGetRequest("/rest/system/config/insync", returnFunction: {
            (reponse: JSON) in
                self.syncthing.configInSync = reponse["configInSync"].boolValue
                self.gotSyncStatus = true
        })
    }
    
    func getConnections() {
        // http://docs.syncthing.net/rest/system-connections-get.html
        httpGetRequest("/rest/system/connections", returnFunction: handleConnections)
    }
    
    func getErrors() {
        // http://docs.syncthing.net/rest/system-error-get.html
        httpGetRequest("/rest/system/error", returnFunction: {
            (reponse: JSON) in
            for (key: String, subJson: JSON) in reponse["errors"] {
                self.syncthing.errors += [SyncthingError(error: subJson["error"].stringValue, withDateString: subJson["time"].stringValue)]
            }
            self.gotErrors = true
        })
    }
    
    func getSystemStatus() {
        // http://docs.syncthing.net/rest/system-upgrade-get.html
        httpGetRequest("/rest/system/upgrade", returnFunction: { (reponse) -> () in
            if reponse["newer"].boolValue {
                self.syncthing.possibleUpgrade = reponse["latest"].stringValue
            } else {
                self.syncthing.possibleUpgrade = nil
            }
        })
        // http://docs.syncthing.net/rest/system-status-get.html
        httpGetRequest("/rest/system/status", returnFunction: { (reponse) -> () in
            var annouceDict = Dictionary<String, Bool>()
            for (key: String, subJson: JSON) in reponse["extAnnounceOK"] {
                annouceDict += Dictionary(dictionaryLiteral: (key, subJson.boolValue))
            }
            self.syncthing.system = SyncthingStatus(alloc: reponse["alloc"].intValue, cpuPercent: reponse["cpuPercent"].doubleValue, extAnnounceOK: annouceDict, goRoutines: reponse["goRoutines"].intValue, myID: reponse["myID"].stringValue, sys: reponse["sys"].intValue, tilde: reponse["tilde"].stringValue)
            self.gotSystemStatus = true
        })
    }
    
        // Database Endpoints
    
    func getDbBrowse(folder: String = "default",levels: Int? = nil) {
        // http://docs.syncthing.net/rest/db-browse-get.html
        if levels != nil {
            httpGetRequest("/rest/db/browse", "?folder=\(folder)") { (reponse) -> () in
                println(reponse) // That's all we do for now
            }
        } else {
            httpGetRequest("/rest/db/browse", "?folder=\(folder)&levels=\(levels)") { (reponse) -> () in
                println(reponse) // That's all we do for now
            }
        }
    }
    
    // MARK: Handlers
    // (they should be private)
    
    typealias AnswerHandler = (JSON) -> ()
    
    private func handleConnections(reponse: JSON) {
        for (key: String, subJson:JSON) in reponse["connections"] {
            syncthing.connections += [Connection(thisDeviceID: key, thisIpAddress: subJson["address"].stringValue, bytesIn: subJson["inBytesTotal"].intValue, bytesOut: subJson["outBytesTotal"].intValue)]
        }
        gotConnections = true
    }
    
    private func handleConfig(reponse: JSON) {
        // Fetch folders
        for (key: String, folder: JSON) in reponse["folders"] {
            // Loop through folder devices
            var folderDevices = [String]()
            for (key: String, device: JSON) in folder["devices"] {
                folderDevices += [device["deviceID"].stringValue]
            }
            // Get ID and Path (that's all we take for now)
            let id = folder["id"].stringValue
            let path = folder["path"].stringValue
            self.syncthing.foldersInSync += Dictionary(dictionaryLiteral: (id, SyncthingFolder(id: id, forPathString: path, withDevices: folderDevices)))
        }
        gotConfig = true
        return
    }
    
    // MARK: Alamofire's HTTP
    
    /** 
    Sends a `GET` request to the Syncthing Server for `urlPath`. The server response is then passed on to the `returnFunction` if there was no error.
    
    :param: urlPath The request's REST path
    :param: returnFunction The callback function when an answer has been received
    */
    private func httpGetRequest(urlPath: String,_ options: String = "", returnFunction: AnswerHandler?) {
        Alamofire.request(.GET, baseUrl+":\(port)"+urlPath+options )
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    println(req)
                    println(res)
                } else {
                    println("Received data from \(urlPath)")
                    let resultat = JSON(json!)
                    if returnFunction != nil {
                        returnFunction!(resultat)
                        // Display our Syncthing object
                        if self.fetchedAll {
                            println(self.syncthing)
                            self.delegateForDisplay.reloadData()
                        }
                        return
                    } else {
                        return
                    }
                }
        }
    }
    
    // MARK: SyncthingInteractionDelegate
    
    func openFolder(id: String) {
        syncthing.revealFolder(id: id)
    }
}