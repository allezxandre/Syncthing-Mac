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
    var baseUrl = "http://localhost"
    var port: Int = 8080
    
    func changeUrl(to: String) {
        self.baseUrl = to
    }
    
    func changePort(to: Int) {
        self.port = to
    }
    
    func getConfig() {
        httpGetRequest("/rest/system/config")
    }
    
    func getConnections() {
        httpGetRequest("/rest/system/connections")
    }
    
    func handleConnections() {
        
    }
    
    func httpGetRequest(urlPath: String) {
        Alamofire.request(.GET, baseUrl+":\(port)"+urlPath )
            .responseJSON { (req, res, json, error) in
                if(error != nil) {
                    println(req)
                    println(res)
                } else {
                    println("Received data from \(urlPath) : ")
                    let resultat = JSON(json!)
                    println(resultat);
                }
        }
    }
}