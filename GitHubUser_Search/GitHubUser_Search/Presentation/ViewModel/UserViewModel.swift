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
    private var pickerTabButtonType: PickerButtonType = .all
    
    @Published public var headers: [String] = []
    @Published public var userList: [(user: UserRepositoryModel, isFavorite: Bool)] = []
    @Published public var pickerSelecter: String = "All" {
        willSet {
            if newValue == "All" {
                pickerTabButtonType = .all
            } else {
                pickerTabButtonType = .favorite
            }
            getFavoriteUserList(query: searchText)
        }
    }
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
    
    // MARK: Function SearchText & Query
    private func handleSearchText() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self,
                      self.validQuery(query: query) else {
                      self!.fetchUser(query: "", page: 1)
                    return
                }
                self.fetchUser(query: query, page: 1)
                
            }
            .store(in: &cancellable)
    }
    
    private func queryPaging() {
        $paging
            .sink { [weak self] page in
                guard let self = self else { return }
                self.fetchUser(query: self.searchText, page: page)
            }
            .store(in: &cancellable)
    }
    
    private func validQuery(query: String) -> Bool {
        // 유효성 검사도 할 수 있고 등등
        if query.isEmpty {
            return false
        } else {
            userList = []
            return true
        }
    }
    
    private func fetchUser(query: String, page: Int) {
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
                        self?.userList = []
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
                guard let self = self else { return }
                
                if query.isEmpty {
                    self.favoriteUserList = users
                } else {
                    let filteredUserList = users.filter { $0.repository.owner.login.contains(query.lowercased()) }
                    self.favoriteUserList = filteredUserList
                }
                
                self.allFavoriteUserList = users
                self.checkFavoriteStatus(query: query)
            })
            .store(in: &cancellable)
    }
    
    // MARK: Check Picker Tab Button Type
    private func checkFavoriteStatus(query: String) {
        switch pickerTabButtonType {
        case .all:
            let user = userList.map { user, isFavorite -> UserRepositoryModel in
                return user
            }
            let result = usecase.checkFavoriteStatus(userList: user, favortieUserList: favoriteUserList)
            
            userList = result
        
        case .favorite:
            let dict = usecase.convertListToDict(favoriteUserList: allFavoriteUserList)
            let keys = dict.keys.sorted()
            keys.forEach { key in
                headers.append(key)
                guard let result = dict[key] else { return }
                userList = result.map { user -> (user: UserRepositoryModel, isFavorite: Bool) in
                    (user, true)
                }
            }
        }
    }
}

// MARK: Picker Enum
public enum PickerButtonType: String {
    case all = "All"
    case favorite = "Favorite"
}
