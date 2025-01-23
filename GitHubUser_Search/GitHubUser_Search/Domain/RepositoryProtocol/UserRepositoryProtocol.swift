//
//  UserRepository.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//
import Combine

protocol UserRepositoryProtocol {
    func getFavoriteUserList() -> AnyPublisher<[UserRepositoryModel], CoreDataError>
    func saveFavoriteUser(user: UserRepositoryModel) -> AnyPublisher<Bool, CoreDataError>
    func deleteFavoriteUser(id: Int) -> AnyPublisher<Bool, CoreDataError>
    func fetchUserList(query: String, page: Int) async -> AnyPublisher<UserItemsModel, NetworkError>
}
