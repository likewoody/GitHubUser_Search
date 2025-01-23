//
//  UserUsecase.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Combine

protocol UserUsecaseProtocol {
    func getFavoriteUserList() -> AnyPublisher<[UserRepositoryModel], CoreDataError>
    func saveFavoriteUser(user: UserRepositoryModel) -> AnyPublisher<Bool, CoreDataError>
    func deleteFavoriteUser(id: Int) -> AnyPublisher<Bool, CoreDataError>
    func fetchUserList(query: String, page: Int) async -> AnyPublisher<UserItemsModel, NetworkError>
    func checkFavoriteStatus(userList: [UserRepositoryModel], favortieUserList: [UserRepositoryModel]) -> [(user: UserRepositoryModel, isFavorite: Bool)]
    func convertListToDict(favoriteUserList: [UserRepositoryModel]) -> [String:[UserRepositoryModel]]
}

public struct UserUsecase: UserUsecaseProtocol {
    
    let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func getFavoriteUserList() -> AnyPublisher<[UserRepositoryModel], CoreDataError> {
        userRepository.getFavoriteUserList()
    }
    
    func saveFavoriteUser(user: UserRepositoryModel) -> AnyPublisher<Bool, CoreDataError> {
        userRepository.saveFavoriteUser(user: user)
    }
    
    func deleteFavoriteUser(id: Int) -> AnyPublisher<Bool, CoreDataError> {
        userRepository.deleteFavoriteUser(id: id)
    }
    
    func fetchUserList(query: String, page: Int) async -> AnyPublisher<UserItemsModel, NetworkError> {
        await userRepository.fetchUserList(query: query, page: page)
    }
    
    func checkFavoriteStatus(userList: [UserRepositoryModel], favortieUserList: [UserRepositoryModel]) -> [(user: UserRepositoryModel, isFavorite: Bool)] {
        let setFavoriteUserList = Set(favortieUserList)
        
        let returnValue = userList.map { user in
            if setFavoriteUserList.contains(user) {
                return (user, true)
            } else { return (user, false) }
        }
        
        return returnValue
    }
    
    func convertListToDict(favoriteUserList: [UserRepositoryModel]) -> [String : [UserRepositoryModel]] {
        return favoriteUserList.reduce(into: [String:[UserRepositoryModel]]()) { result, user in
            if let firstString = user.repository.owner.login.first {
                let key = firstString.uppercased()
                result[key, default: []].append(user)
            }
        }
    }
}
