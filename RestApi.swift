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

// As from Syncthing's wiki page: https://github.com/syncthing/syncthing/wiki/REST-Interface
class RESTcall {
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
    /** Returns `true` if everything has been fetched */
    var fetchedAll: Bool {
        return (gotConfig && gotSyncStatus && gotConnections && gotErrors)
    }
    
    // MARK: Basic class operations
    
    func changeUrl(to: String) {
        self.baseUrl = to
    }
    
    func changePort(to: Int) {
        self.port = to
    }
    
    // MARK: Getters
    
    func getAll() {
        pingSyncthingServer()
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
        gotConfig = true
        return
    }
    
    // MARK: Alamofire's HTTP
    
    private func httpGetRequest(urlPath: String, returnFunction: AnswerHandler?) {
        Alamofire.request(.GET, baseUrl+":\(port)"+urlPath )
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
                        }
                        return
                    } else {
                        return
                    }
                }
        }
    }
}