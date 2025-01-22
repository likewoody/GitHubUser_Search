//
//  NetworkUserSession.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Foundation
import Alamofire

public protocol UserSessionProtocol {
    func request(_ convertible: any URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters?,
                 headers: HTTPHeaders?) -> DataRequest
}

public struct UserSession: UserSessionProtocol {
    let session: Session
    
    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = Session(configuration: config)
    }
    
    public func request(_ convertible: any URLConvertible, method: HTTPMethod, parameters: Parameters?, headers: HTTPHeaders?) -> DataRequest {
        session.request(convertible, method: method, parameters: parameters, headers: headers)
    }
}
