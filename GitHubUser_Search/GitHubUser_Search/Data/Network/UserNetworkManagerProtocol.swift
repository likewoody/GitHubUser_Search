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
            guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path),
                  let key = dict["API_KEY"] as? String else {
                fatalError("api key error")
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
                    print("response error에서 시작인가?")
                    throw NetworkError.requestFailed(error.localizedDescription)
                }
                
                guard let data = response.data else {
                    print("data error에서 시작인가?")
                    throw NetworkError.dataNil
                }
                print("decode error에서 시작인가?")
                return try JSONDecoder().decode(T.self, from: data)
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                print("invalidResponse Error")
                return NetworkError.invalidResponse
            }
            .eraseToAnyPublisher()
    }
}
