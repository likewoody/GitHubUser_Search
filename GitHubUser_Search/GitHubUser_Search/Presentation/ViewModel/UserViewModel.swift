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
    private var paging: Int = 1
    @Published public var headers: [String] = []
    @Published public var userList: [(user: UserRepositoryModel, isFavorite: Bool)] = []
    @Published public var favoriteUserList: [UserRepositoryModel] = []
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
                self?.handleSearchTextChange(query: query)
                self?.getFavoriteUserList(query: query)
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
        paging += 1
        Task {
            await self.fetchUser(query: self.searchText, page: paging)
        }
    }
    
    
    private func validQuery(query: String) -> Bool {
        // 유효성 검사도 할 수 있고 등등
        DispatchQueue.main.async { [weak self] in
            self?.userList = []
            self?.favoriteUserList = []
        }
        if query.isEmpty {
            return false
        } else {
            return true
        }
    }
    
    private func fetchUser(query: String, page: Int) async {
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
                    if page == 1 {
                        self?.userList = users.items.map { user in
                            (user: user, isFavorite: false)
                        }
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
                }
                self.allFavoriteUserList = users
                self.setUserListByPickerSegment()
                
            })
            .store(in: &cancellable)
    }
    
    // MARK: Check Picker Tab Button Type
    private func setUserListByPickerSegment() {
        headers = []
        $pickerSelecter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] picked in
                guard let self = self else { return }
                switch picked {
                case "All":
                    let user = userList.map { user, isFavorite -> UserRepositoryModel in
                        return user
                    }
                    let result = usecase.checkFavoriteStatus(userList: user, favortieUserList: allFavoriteUserList)
                    
                    userList = result
                case "Favorite":
                    let dict = usecase.convertListToDict(favoriteUserList: favoriteUserList)
                    let keys = dict.keys.sorted()
                    keys.forEach { [weak self] key in
                        guard let self = self,
                            let result = dict[key] else { return }
                        headers.append(key)
                        favoriteUserList.append(contentsOf: result)
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
