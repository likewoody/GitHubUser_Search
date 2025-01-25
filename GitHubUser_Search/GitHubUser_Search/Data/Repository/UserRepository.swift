//
//  Repository.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/23/25.
//

import Foundation
import Combine

public struct UserRepository: UserRepositoryProtocol {
    let userCoreData: UserCoreDataProtocol
    let network: UserNetworkProtocol
    
    init(userCoreData: UserCoreDataProtocol, network: UserNetworkProtocol) {
        self.userCoreData = userCoreData
        self.network = network
    }
    
    func getFavoriteUserList() -> AnyPublisher<[UserRepositoryModel], CoreDataError> {
        userCoreData.getFavoriteUserList()
    }
    
    func saveFavoriteUser(user: UserRepositoryModel) -> AnyPublisher<Bool, CoreDataError> {
        userCoreData.saveFavoriteUser(user: user)
    }
    
    func deleteFavoriteUser(id: Int) -> AnyPublisher<Bool, CoreDataError> {
        userCoreData.deleteFavoriteUser(id: id)
    }
    
    func fetchUserList(query: String, page: Int) async -> AnyPublisher<UserItemsModel, NetworkError> {
        await network.fetchUser(query: query, page: page)
    }
}
