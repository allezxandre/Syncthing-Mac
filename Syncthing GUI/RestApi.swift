//
//  RestApi.swift
//  Syncthing GUI
//
//  Created by Alexandre Jouandin on 2015/05/14.
//  Copyright (c) 2015 Alexandre Jouandin. All rights reserved.
//
// This file is where all the frontend <=> backend magic happens.
// It defines all functions that will fetch data for us.

import Foundation
import Alamofire
import SwiftyJSON

protocol SyncthingInteractionDelegate {
    func openFolder(String) -> ()
    func rescanFolder(String) -> ()
}

typealias AnswerHandler = (JSON) -> ()

// As from Syncthing's wiki page: https://github.com/syncthing/syncthing/wiki/REST-Interface
class SyncthingCommunication: NSObject, SyncthingInteractionDelegate {
    // MARK: Delegate
    var delegateForDisplay: SyncthingDisplayDelegate!
    // MARK: Variables
    var baseUrlString: String = "http://localhost"
    var baseUrl: NSURL {
        if let url = NSURL(string: baseUrlString+":"+String(stringInterpolationSegment: port)) {
            return url
        } else {
            NSLog("There was an error retrieving URL: '\(baseUrlString)':'\(port)'")
            // By default, we return localhost on port 8080
            return NSURL(string: "http://localhost:8080")!
        }
    }
    var port: Int = 8080
    var apiKey: String? = nil
    var syncthing: Syncthing = Syncthing()
        // Boolean variables
    /** Is true when the Syncthing server is answering Ping requests */
    var systemIsOnline: Bool {
        didSet {
            if systemIsOnline {
                fetchEverything()
                startTimers()
            }
        }
    }
    
    var updateInterval: NSTimeInterval = NSTimeInterval(60)
    
    var gotConfig = false
    var gotSyncStatus = false
    var gotConnections = false
    var gotErrors = false
    var gotSystemStatus = false
    /** Returns `true` if everything has been fetched at least once */
    var fetchedAll: Bool {
        return (gotConfig && gotSyncStatus && gotConnections && gotErrors && gotSystemStatus)
    }
    
    override init() {
        self.systemIsOnline = false
    }
    
    deinit {
        print("Syncthing object for IPAddress '\(baseUrlString)' is being deinitialized")
    }
    
    // MARK: Getters
    
        // System Endpoints
    func initiate() {
        systemIsOnline = false
        pingSyncthingServer()
    }
    
    func startTimers() {
        NSTimer.scheduledTimerWithTimeInterval(updateInterval, target: self, selector: "periodicUpdate:", userInfo: nil, repeats: true)
    }
    
    func periodicUpdate(timer: NSTimer) {
        print("Timer interval: \(timer.timeInterval)")
        getSystemStatus()
        getSyncStatus()
        getConnections()
        getErrors()
        delegateForDisplay.resetView(displayWheel: false)
    }
    
    func fetchEverything() {
        getSystemStatus()
        getConfig()
        getSyncStatus()
        getConnections()
        getErrors()
    }
    
    func pingSyncthingServer() {
        // http://docs.syncthing.net/rest/system-ping-get.html
        httpRequest(.GET, urlPath:"/rest/system/ping", returnFunction: { (reponse:JSON) -> () in
            self.systemIsOnline = (reponse["ping"].stringValue == "pong")
            print("System is online: \(self.systemIsOnline)")
        })
    }
    
    func getConfig() {
        // http://docs.syncthing.net/rest/system-config-get.html
        httpRequest(.GET, urlPath:"/rest/system/config", returnFunction: handleConfig)
    }
    
    func getSyncStatus() {
        // http://docs.syncthing.net/rest/system-config-insync-get.html
        httpRequest(.GET, urlPath:"/rest/system/config/insync", returnFunction: {
            (reponse: JSON) in
                self.syncthing.configInSync = reponse["configInSync"].boolValue
                self.gotSyncStatus = true
        })
    }
    
    func getConnections() {
        // http://docs.syncthing.net/rest/system-connections-get.html
        httpRequest(.GET, urlPath:"/rest/system/connections", returnFunction: handleConnections)
    }
    
    func getErrors() {
        // http://docs.syncthing.net/rest/system-error-get.html
        httpRequest(.GET, urlPath:"/rest/system/error", returnFunction: {
            (reponse: JSON) in
            for (_, subJson): (String, JSON) in reponse["errors"] {
                self.syncthing.errors += [SyncthingError(error: subJson["error"].stringValue, withDateString: subJson["time"].stringValue)]
            }
            self.gotErrors = true
        })
    }
    
    func getSystemStatus() {
        // http://docs.syncthing.net/rest/system-upgrade-get.html
        httpRequest(.GET, urlPath:"/rest/system/upgrade", returnFunction: { (reponse) -> () in
            if reponse["newer"].boolValue {
                self.syncthing.possibleUpgrade = reponse["latest"].stringValue
            } else {
                self.syncthing.possibleUpgrade = nil
            }
        })
        // http://docs.syncthing.net/rest/system-status-get.html
        httpRequest(.GET, urlPath:"/rest/system/status", returnFunction: { (reponse) -> () in
            var annouceDict = Dictionary<String, Bool>()
            for (key, subJson): (String, JSON) in reponse["extAnnounceOK"] {
                annouceDict += Dictionary(dictionaryLiteral: (key, subJson.boolValue))
            }
            self.syncthing.system = SyncthingStatus(alloc: reponse["alloc"].intValue, cpuPercent: reponse["cpuPercent"].doubleValue, extAnnounceOK: annouceDict, goRoutines: reponse["goRoutines"].intValue, myID: reponse["myID"].stringValue, sys: reponse["sys"].intValue, tilde: reponse["tilde"].stringValue)
            self.gotSystemStatus = true
        })
    }
    
        // Database Endpoints
    /**
    Browse the file database according to [Syncthing's documentation](http://docs.syncthing.net/rest/db-browse-get.html).
    */
    func getDbBrowse(folder: String, levels: Int? = nil, prefix: String? = nil, handlerFunction: AnswerHandler) {
        // http://docs.syncthing.net/rest/db-browse-get.html
        var parameters = ["folder": folder]
        if levels != nil {
            parameters += ["levels": String(stringInterpolationSegment: levels)]
        }
        if prefix != nil {
            parameters += ["prefix": prefix!]
        }
        httpRequest(.GET, urlPath: "/rest/db/browse", parameters: parameters, body: nil) { (response) -> () in
            handlerFunction(response)
        }
    }
    
    func getFolderStatus(folder: String) {
        // http://docs.syncthing.net/rest/db-status-get.html
        httpRequest(.GET, urlPath:"/rest/db/status", parameters: ["folder": folder], returnFunction: handleFolderStatus(folder))
    }
    
    // MARK: POSTERS
        // Database Endpoints
    
    /** An HTTP POST request to ask for a folder re-scan. [Please see documentation](http://docs.syncthing.net/rest/db-scan-post.html) for more information */
    func rescanFolder(id: String) {
        // http://docs.syncthing.net/rest/db-scan-post.html
        httpRequest(.POST, urlPath: "/rest/db/scan", parameters: ["folder": id], body: nil, returnFunction: nil)
    }
    
    // MARK: Handlers
    // (they should be private)
    
    private func handleConnections(reponse: JSON) {
        for (key, subJson): (String, JSON) in reponse["connections"] {
            syncthing.connections += [Connection(thisDeviceID: key, thisIpAddress: subJson["address"].stringValue, bytesIn: subJson["inBytesTotal"].intValue, bytesOut: subJson["outBytesTotal"].intValue)]
        }
        gotConnections = true
    }
    
    private func handleFolderStatus(folderString: String)(reponse: JSON) -> () {
        print("handleFolderStatus(\(folderString))(\(reponse))")
        syncthing.foldersInSync[folderString]?.idle = (reponse["state"].stringValue == "idle")
        syncthing.foldersInSync[folderString]?.inSyncBytes = reponse["inSyncBytes"].intValue
        syncthing.foldersInSync[folderString]?.outOfSyncBytes = reponse["needBytes"].intValue
        self.delegateForDisplay.reloadData()
    }
    
    private func handleConfig(reponse: JSON) {
        // Fetch folders
        for (_, folder): (String, JSON) in reponse["folders"] {
            // Loop through folder devices
            var folderDevices = [String]()
            for (_, device): (String, JSON) in folder["devices"] {
                folderDevices += [device["deviceID"].stringValue]
            }
            // Get ID and Path (that's all we take for now)
            let id = folder["id"].stringValue
            let path = folder["path"].stringValue
            self.syncthing.foldersInSync += Dictionary(dictionaryLiteral: (id, SyncthingFolder(id: id, forPathString: path, withDevices: folderDevices)))
            getFolderStatus(id)
        }
        gotConfig = true
        return
    }
    
    // MARK: Alamofire's HTTP
    
    /**
    Sends a `requestType` request to the Syncthing Server for `urlPath`, with `parameters`. For `POST` requests, a the request body might be set in the `body` parameter. 
    
    The server response is then passed on to the `returnFunction` if there was no error.
    
    - parameter requestType: The HTTP request type
    - parameter urlPath: The request's REST path
    - parameter parameters: A dictionnary of parameters for the URL
    - parameter body: The JSON data to pass to the body for a `POST` request
    - parameter returnFunction: The callback function when an answer has been received
    */
    private func httpRequest(requestType: Alamofire.Method, urlPath: String,parameters: Dictionary<String,String>? = nil, body: Dictionary<String,AnyObject>? = nil, returnFunction: AnswerHandler?) {
        // Prepare Request
        let completeUrl = NSURL(string: urlPath, relativeToURL: self.baseUrl)
        // Create an url of type NSMutableURLRequest
        let urlMutableRequest: NSMutableURLRequest = NSMutableURLRequest(URL: completeUrl!)
        // var JSONSerializationError: NSError? = nil
        switch requestType {
        case .GET:
            urlMutableRequest.HTTPMethod = "GET"
        case .POST:
            urlMutableRequest.HTTPMethod = "POST"
            // Process body if requestType is .POST
            if (body != nil) {
                do {
                    urlMutableRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(body!, options: [])
                } catch let error as NSError {
                    print(error)
                    urlMutableRequest.HTTPBody = nil
                }
            }
        default:
            NSLog("Received unexpected requestType: \(requestType)")
            urlMutableRequest.HTTPMethod = "GET"
        }
        // Add API key to headers
        urlMutableRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        // Add parameters to URL
        let urlRequest: URLRequestConvertible
        if parameters != nil {
            urlRequest = Alamofire.ParameterEncoding.URL.encode(urlMutableRequest, parameters: parameters).0
        } else {
            urlRequest = urlMutableRequest
        }
        
        // Make Request
        Alamofire.request(urlRequest)
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    print(req)
                    print(res)
                    print("Error retrieving JSON: \n\(error!)")
                } else {
                    print("Received data from \(urlPath)")
                    if returnFunction != nil {
                        let resultat = JSON(json!)
                        returnFunction!(resultat)
                        // Display our Syncthing object for debugging purposes
                        if self.fetchedAll {
                            print(self.syncthing)
                            self.delegateForDisplay.reloadData()
                        }
                        return
                    }
                    return
                }
        }
    }
    
    // MARK: SyncthingInteractionDelegate
    
    func openFolder(id: String) {
        syncthing.revealFolder(id: id)
    }
}