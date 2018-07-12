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
    
    let backendUrl = "ayylmao"  // TODO: replace
    
    public func send(_ message: String, lat: Double, long: Double, uuid: String, networkHandler: @escaping NetworkHandler) {
        
        guard
            let sanitizedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            !sanitizedMessage.isEmpty
        else {
            
            return
        }
        
        let endpoint = "/message?msg=\(sanitizedMessage)&lat=\(lat)&long=\(long)&uid=\(uuid)"
        
        Alamofire.request(backendUrl + endpoint, method: .post).validate().responseString { response in
            switch response.result {
            case .success:
                networkHandler(true, response.result.value)
            case .failure(let error):
                print(error.localizedDescription)
                networkHandler(false, error.localizedDescription)
            }
        }
    }
}
