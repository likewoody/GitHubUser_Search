//
//  UserNetworkManagerProtocol.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Foundation
import Combine
import Alamofire

protocol UserNetworkManagerProtocol {
    func fetchUser<T: Codable>(urlString: String, method: HTTPMethod, parameters: Parameters?) async -> AnyPublisher<T, NetworkError>
}

public struct UserNetworkManager: UserNetworkManagerProtocol {
    
    
    let session: UserSessionProtocol
    var headers: HTTPHeaders {
        var api_key: String {
            guard let path = Bundle.main.path(forResource: "GitHubUser-Search-Info", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path),
                  let key = dict["API_KEY"] as? String else {
                fatalError("looking for api key error")
            }
            return key
        }

        let header = HTTPHeader(name: "Authorization", value: "Bearer \(api_key)")
        return HTTPHeaders([header])
    }
    
    init(session: UserSessionProtocol) {
        self.session = session
    }
    
    func fetchUser<T: Codable>(urlString: String, method: HTTPMethod, parameters: Parameters?) async -> AnyPublisher<T, NetworkError> {
        
        let result = await session.request(urlString, method: method, parameters: parameters, headers: headers)
            .serializingData()
            .response
        
        return Just(result)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { response -> T in
                if let error = response.error {
                    throw NetworkError.requestFailed(error.localizedDescription)
                }
                
                guard let data = response.data else {
                    throw NetworkError.dataNil
                }
                
                return try JSONDecoder().decode(T.self, from: data)
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                return NetworkError.invalidResponse
            }
            .eraseToAnyPublisher()
//            .decode(type: T.self, decoder: JSONDecoder())
        
//        if let error = result.error {
//            return Fail(error: NetworkError.requestFailed(error.localizedDescription)).eraseToAnyPublisher()
//        }
//        
//        guard let response = result.response else {
//            return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
//        }
//        guard let data = result.data else {
//            return Fail(error: NetworkError.dataNil).eraseToAnyPublisher()
//        }
//        
//        if 200..<400 ~= response.statusCode {
//            return Just(data)
//                .setFailureType(to: NetworkError)
//                .decode(type: T.self, decoder: JSONDecoder())
//        }
//        do {
//            
//            
//        } catch {
//            <#statements#>
//        }
        
        
    }
}
