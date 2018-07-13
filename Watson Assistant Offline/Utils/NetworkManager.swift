//
//  NetworkManager.swift
//  Watson Assistant Offline
//
//  Created by Wilson on 7/12/18.
//  Copyright © 2018 Wilson Ding. All rights reserved.
//

import Foundation
import Alamofire

class NetworkManager {
    typealias NetworkHandler = (_ success: Bool, _ message: String?) -> Void
    
    private let backendUrl = "https://capes.mybluemix.net"
    
    static let instance = NetworkManager()
    
    public func send(_ message: String, uuid: String, networkHandler: @escaping NetworkHandler) {
        
        guard
            let sanitizedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            !sanitizedMessage.isEmpty
        else {
            return
        }
        
        let endpoint = "/message?msg=\(sanitizedMessage)&uuid=\(uuid)"
        
        Alamofire.request(backendUrl + endpoint).validate().responseString { response in
            switch response.result {
            case .success:
                guard let message = response.result.value else { return }
                networkHandler(true, message)
            case .failure(let error):
                print(error.localizedDescription)
                networkHandler(false, error.localizedDescription)
            }
        }
    }

    public func rescue(_ uuid: String, lat: Double, long: Double, networkHandler: @escaping NetworkHandler) {
        let endpoint = "/panic?lat=\(lat)&long=\(long)&uuid=\(uuid)"
        
        Alamofire.request(backendUrl + endpoint).validate().responseString { response in
            switch response.result {
            case .success:
                networkHandler(true, nil)
            case .failure(let error):
                print(error.localizedDescription)
                networkHandler(false, error.localizedDescription)
            }
        }
    }
}
