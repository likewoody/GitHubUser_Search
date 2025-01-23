//
//  UserViewModel.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/23/25.
//

import Foundation
import Combine

public protocol UserViewModelProtocol {
    func transform(input: UserViewModel.Input) -> UserViewModel.Output
}

public class UserViewModel: UserViewModelProtocol {
    
    private let usecase: UserUsecaseProtocol
    private let userList = CurrentValueSubject<[UserRepositoryModel], any Error>([])
    private let favoriteUserList = PassthroughSubject<[UserRepositoryModel], any Error>()
    private let allFavoriteUserList = PassthroughSubject<[UserRepositoryModel], any Error>()
    private var cancellable = Set<AnyCancellable>()
    
    
    init(usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
    
    public struct Input {
        let tabButtonType: AnyPublisher<TabButtonType, any Error>
        let query: AnyPublisher<String, any Error>
        let paging: AnyPublisher<Int, any Error>
        let saveFavorite: AnyPublisher<UserRepositoryModel, any Error>
        let deleteFavorite: AnyPublisher<Int, any Error>
    }
    
    public struct Output {
//        let userList: AnyPublisher<[UserRepositoryModel], any Error>
//        let error: AnyPublisher<String, any Error>

    }
    
    public func transform(input: Input) -> Output {
        input.query
            .subscribe(on: DispatchQueue.global(qos: .background))
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }, receiveValue: {  query in
//                [weak self]
                print("receiveValeu query check \(query)")
//                guard ((self?.validQuery(query: query)) != nil) else {
//                    self?.getFavoriteUserList(query: "")
//                    return
//                }
//                self?.getFavoriteUserList(query: query)
//                self?.fetchUser(query: query, page: 1)
            })
            .store(in: &cancellable)
            
        return Output()
    }
    
    private func validQuery(query: String) -> Bool {
        // 유효성 검사도 할 수 있고 등등
        if query.isEmpty {
            return false
        } else {
            return true
        }
    }
    
    private func fetchUser(query: String, page: Int) {
        guard let queryAllowed = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        Task{
            await usecase.fetchUserList(query: query, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print(error.description)
                    }
                } receiveValue: { [weak self] users in
                    if page == 1 {
                        self?.userList.send(users.items)
                    } else {
                        self?.userList.send((self?.userList.value)! + users.items)
                    }
                }
                .store(in: &cancellable)
        }
    }
    
    private func getFavoriteUserList(query: String) {
        usecase.getFavoriteUserList()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished : break
                case .failure(let error):
                    print(error.description)
                }
            }, receiveValue: { [weak self] users in
                if query.isEmpty {
                    self?.favoriteUserList.send(users)
                } else {
                    let filteredUserList = users.filter { $0.repository.owner.login.contains(query.lowercased()) }
                    self?.favoriteUserList.send(filteredUserList)
                }
                self?.allFavoriteUserList.send(users)
            })
            .store(in: &cancellable)
        
    }
}

public enum TabButtonType: String {
    case all, favorite
}
