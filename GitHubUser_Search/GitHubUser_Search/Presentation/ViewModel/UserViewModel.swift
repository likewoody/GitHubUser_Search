//
//  UserViewModel.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/23/25.
//

import Foundation
import Combine

// MARK: ViewModel
public class UserViewModel: ObservableObject {
    private let usecase: UserUsecaseProtocol
    private var cancellable = Set<AnyCancellable>()
    private var allFavoriteUserList: [UserRepositoryModel] = []
    private var favoriteUserList: [UserRepositoryModel] = []
    private var paging: Int = 1
    @Published public var headers: [String] = []
    @Published public var userList: [(user: UserRepositoryModel, isFavorite: Bool)] = []
    @Published public var pickerSelecter: String = "All"
    @Published public var searchText: String = ""
    
    init(usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
    
    // MARK: Function SearchText & Query
    public func handleSearchText() {
        cancellable.removeAll() // 기존 구독 제거
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if self?.pickerSelecter == "All" {
                    print("this is all")
                    self?.handleSearchTextChange(query: query)
                } else {
                    self?.getFavoriteUserList(query: query)
                }
            }
            .store(in: &cancellable)
        
        print("test searchText : \(searchText)")
    }
    
    private func handleSearchTextChange(query: String) {
        // 검색 로직 처리
        guard validQuery(query: query) else { return }
        Task{
            await fetchUser(query: query, page: 1)
        }
    }
    
    public func queryPaging() {
        cancellable.removeAll() // 기존 구독 제거
        paging += 1
        Task {
            await self.fetchUser(query: self.searchText, page: paging)
        }
    }
    
    
    private func validQuery(query: String) -> Bool {
        // 유효성 검사도 할 수 있고 등등
        if query.isEmpty {
            return false
        } else {
            print("userList reset here")
            DispatchQueue.main.async { [weak self] in
                self?.userList = []
            }
            return true
        }
    }
    
    private func fetchUser(query: String, page: Int) async {
        cancellable.removeAll() // 기존 구독 제거
        guard let queryAllowed = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        Task{
            // 1번 호출
            print("and come to fetchUser now")
            await usecase.fetchUserList(query: queryAllowed, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished: break
                    case .failure(let error):
                        print(error.description)
                    }
                } receiveValue: { [weak self] users in
                    if page == 1 {
                        self?.userList = users.items.map { user in
                            (user: user, isFavorite: false)
                        }
                        print("and get userList : \n \(self?.userList)")
                    } else {
                        self?.userList += users.items.map { user in
                            (user: user, isFavorite: false)
                        }
                    }
                    self?.getFavoriteUserList(query: query)
                }
                .store(in: &cancellable)
        }
    }
    
    // MARK: Function Save & Delete
    public func saveFavoriteUser(user: UserRepositoryModel) {
        cancellable.removeAll() // 기존 구독 제거
        print("test save FaovirteUser : \(user)")
        let result = usecase.saveFavoriteUser(user: user)
        result
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error.description)
                }
            } receiveValue: { [weak self] saveResult in
                if saveResult {
                    self?.getFavoriteUserList(query: self?.searchText ?? "")
                }
            }
            .store(in: &cancellable)
    }
    
    public func deleteFavoriteUser(id: Int) {
        cancellable.removeAll() // 기존 구독 제거
        let result = usecase.deleteFavoriteUser(id: id)
        result
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error.description)
                }
            } receiveValue: { [weak self] deleteResult in
                if deleteResult {
                    self?.getFavoriteUserList(query: self?.searchText ?? "")
                }
            }
            .store(in: &cancellable)
    }
    
    public func getFavoriteUserList(query: String) {
        cancellable.removeAll() // 기존 구독 제거
        usecase.getFavoriteUserList()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished : break
                case .failure(let error):
                    print(error.description)
                }
            }, receiveValue: { [weak self] users in
                guard let self = self else { return }
                if query.isEmpty {
                    self.favoriteUserList = users
                } else {
                    let filteredUsers = users.filter { $0.repository.owner.login.contains(query.lowercased())}
                    self.favoriteUserList = filteredUsers
                    print("is filteredUser emtpy? :\n \(filteredUsers)")
                }
                
                print("getFavoriteUserList : \n\(favoriteUserList)")
                self.allFavoriteUserList = users
                self.checkFavoriteStatus(query: query)
                
            })
            .store(in: &cancellable)
    }
    
    // MARK: Check Picker Tab Button Type
    private func checkFavoriteStatus(query: String) {
        cancellable.removeAll() // 기존 구독 제거
        $pickerSelecter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] picked in
                guard let self = self else { return }
//                print("test pickerSelecter")
                switch picked {
                case "All":
                    headers = []
                    let user = userList.map { user, isFavorite -> UserRepositoryModel in
                        return user
                    }
                    let result = usecase.checkFavoriteStatus(userList: user, favortieUserList: allFavoriteUserList)
                    
                    userList = result
                case "Favorite":
                    let dict = usecase.convertListToDict(favoriteUserList: favoriteUserList)
                    let keys = dict.keys.sorted()
                    keys.forEach { [weak self] key in
                        guard let self = self else { return }
                        headers.append(key)
                        guard let result = dict[key] else { return }
                        userList.append(contentsOf: result.map { user -> (UserRepositoryModel, Bool) in
                                return (user, true)
                            })
                    }
                    print("keys check : \(keys)")
                default: break
                }
            }
            .store(in: &cancellable)
    }
}

// MARK: Picker Enum
public enum PickerButtonType: String {
    case all = "All"
    case favorite = "Favorite"
}
