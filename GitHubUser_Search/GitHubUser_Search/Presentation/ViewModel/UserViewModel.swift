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
    @Published public var paging: Int = 1
    @Published public var headers: [String] = []
    @Published public var userList: [(user: UserRepositoryModel, isFavorite: Bool)] = []
    @Published public var pickerSelecter: String = "All"
    @Published public var searchText: String = ""
    
    init(usecase: UserUsecaseProtocol) {
        self.usecase = usecase
        handleSearchText()
        DispatchQueue.main.async { [weak self] in
            self?.setupBindings()
        }
        
    }
    
    // MARK: Function SearchText & Query
    public func handleSearchText() {
//        cancellable.removeAll() // 기존 구독 제거
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                print("is this searchText accessed?")
                self?.handleSearchTextChange(query: query)
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
    
    private func queryPaging() {
        $paging
            .receive(on: DispatchQueue.main)
            .sink { page in
                Task {
                    await self.fetchUser(query: self.searchText, page: page)
                }
            }
            .store(in: &cancellable)
    }
    
    
    private func validQuery(query: String) -> Bool {
        // 유효성 검사도 할 수 있고 등등
        if query.isEmpty {
            return false
        } else {
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
                    let filteredUsers = users.filter { $0.repository.owner.login.contains(query.lowercased())}
                    self.favoriteUserList = filteredUsers
                }
                
                self.allFavoriteUserList = users
                self.checkFavoriteStatus(query: query)
                
            })
            .store(in: &cancellable)
    }
    
    // MARK: Picker Button Binding
    @MainActor private func setupBindings() {
        // 한 번만 바인딩
        $pickerSelecter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                Task {
                    guard let self = self else { return }
                    if newValue == "All" {
                        self.pickerTabButtonType = .all
                    } else {
                        self.pickerTabButtonType = .favorite
                    }
//                    DispatchQueue.main.async {
                    self.userList = []
//                    }
                    await self.fetchUser(query: self.searchText, page: 1)
                }
            }
            .store(in: &cancellable)
    }
    
    // MARK: Check Picker Tab Button Type
    private func checkFavoriteStatus(query: String) {
        $pickerSelecter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] picked in
                guard let self = self else { return }
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
                        userList = result.map { user -> (UserRepositoryModel, Bool) in
                            print("favorite user check : \n \(user)")
                            return (user, true)
                        }
                    }
                    print("keys check : \(keys)")
                    print("userList check : \n\(userList)")
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
