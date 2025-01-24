//
//  UserViewModel.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/23/25.
//

import Foundation
import Combine

//public protocol UserViewModelProtocol: ObservableObject {
//    var searchText: String { get set }
////    func handleEvent()
////    func transform(input: UserViewModel.Input) -> UserViewModel.Output
//}

public class UserViewModel: ObservableObject {

    private let usecase: UserUsecaseProtocol
    
//    @Published public var userList = CurrentValueSubject<[UserRepositoryModel], any Error>([])
    
    private let allFavoriteUserList = PassthroughSubject<[UserRepositoryModel], any Error>()
    private var cancellable = Set<AnyCancellable>()
    
    @Published public var userList: [UserRepositoryModel] = []
    @Published public var favoriteUserList: UserRepositoryModel?
//    {
//        willSet {
//            print("userList will set : \(newValue)")
//        }
//    }
    @Published public var paging: Int = 1 {
        willSet {
            queryPaging()
        }
    }
    @Published public var searchText: String = ""
    {
        willSet {
            Task{
                try await Task.sleep(nanoseconds: 30000)
                handleSearchText()
            }
        }
    }
    
    init(usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
    
//    public struct Input {
//////        let tabButtonType: AnyPublisher<TabButtonType, any Error>
//        let query: AnyPublisher<String, any Error>
//////        let paging: AnyPublisher<Int, any Error>
//////        let saveFavorite: AnyPublisher<UserRepositoryModel, any Error>
//////        let deleteFavorite: AnyPublisher<Int, any Error>
//    }
//    public struct Output {
//        let userList: AnyPublisher<[UserRepositoryModel], any Error>
//        let error: AnyPublisher<String, any Error>
//    }
    
    private func handleSearchText() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard ((self?.validQuery(query: query)) != nil) else {
                    self?.getFavoriteUserList(query: "")
                    return
                }
                self?.getFavoriteUserList(query: query)
                self?.fetchUser(query: query, page: 1)
            }
            .store(in: &cancellable)
        
        print("finished userList :\n\(userList)")
    }
    
    private func queryPaging() {
        $paging
            .sink { [weak self] page in
                guard let self = self else { return }
                self.fetchUser(query: self.searchText, page: page)
            }
            .store(in: &cancellable)
    }
    
    public func saveFavoriteUser(user: UserRepositoryModel) {
        let result = usecase.saveFavoriteUser(user: user)
        result
            .sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error.description)
                }
            } receiveValue: { [weak self] boolResult in
                if boolResult {
                    self?.handleSearchText()
                }
            }
            .store(in: &cancellable)
    }
//        searchText.publisher
////            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
//            .sink { query in
//                print(query)
//            }
//            .store(in: &cancellable)
//        input.query
//            .subscribe(on: DispatchQueue.global(qos: .background))
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                case .finished: break
//                case .failure(let error):
//                    print(error.localizedDescription)
//                }
//            }, receiveValue: {  query in
////                [weak self]
//                print("receiveValeu query check \(query)")
////                guard ((self?.validQuery(query: query)) != nil) else {
////                    self?.getFavoriteUserList(query: "")
////                    return
////                }
////                self?.getFavoriteUserList(query: query)
////                self?.fetchUser(query: query, page: 1)
//            })
//            .store(in: &cancellable)
            
//        return Output()
    
    private func validQuery(query: String) -> Bool {
        // 유효성 검사도 할 수 있고 등등
        if query.isEmpty {
            return false
        } else {
            return true
        }
    }
    
    private func fetchUser(query: String, page: Int) {
        userList = []
        guard let queryAllowed = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        Task{
            await usecase.fetchUserList(query: queryAllowed, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print(error.description)
                    }
                } receiveValue: { [weak self] users in
                    print("query check : \(queryAllowed)\n user check : \(users)")
                    if page == 1 {
                        self?.userList = users.items
                    } else {
                        self?.userList += users.items
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
//                    self?.favoriteUserList.send(users)
                } else {
//                    let filteredUserList = users.filter { $0.repository.owner.login.contains(query.lowercased()) }
//                    self?.favoriteUserList.send(filteredUserList)
                }
//                self?.allFavoriteUserList.send(users)
            })
            .store(in: &cancellable)
        
    }
}

public enum PickerButtonType: String {
    case all, favorite
}
