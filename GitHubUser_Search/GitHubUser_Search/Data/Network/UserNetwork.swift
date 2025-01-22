//
//  UserNetwork.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Foundation
import Combine

protocol UserNetworkProtocol {
    func fetchUser(query: String, page: Int) async -> AnyPublisher<UserItemsModel, NetworkError>
}

public struct UserNetwork: UserNetworkProtocol {
    var networkMangaer: UserNetworkManagerProtocol

    init(networkMangaer: UserNetworkManagerProtocol) {
        self.networkMangaer = networkMangaer
    }
    
    func fetchUser(query: String, page: Int) async -> AnyPublisher<UserItemsModel, NetworkError> {
        let urlString = "https://api.github.com/search/code?q=\(query)&page=\(page)"
        return await networkMangaer.fetchUser(urlString: urlString, method: .get, parameters: nil)
    }
    
}
