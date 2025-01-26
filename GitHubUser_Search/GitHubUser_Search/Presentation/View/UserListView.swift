//
//  ContentView.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import SwiftUI
import CoreData
import Combine
import SDWebImageSwiftUI

// MARK: View
struct UserListView: View {
    private let pickerButtonType: [PickerButtonType] = [.all, .favorite]
    @State private var cancellable = Set<AnyCancellable>()
    @StateObject private var viewModel: UserViewModel

    init(viewModel: UserViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        // 초기화 시 바인딩 설정
//        viewModel.handleSearchText()
    }

    var body: some View {
        Group {
            userTextField
            
            pickerView
            Spacer()
            
            userView
        }
    }
}

// MARK: TextField
extension UserListView {
    private var userTextField: some View {
        VStack {
            TextField("\(Image(systemName: "magnifyingglass")) 검색어를 입력하세요.", text: $viewModel.searchText)
                .frame(maxWidth: .infinity)
                .textFieldStyle(.roundedBorder)
                .padding()
                .font(.headline)
                .onSubmit(of: .text) {
                    viewModel.handleSearchText()
                }
        }
    }
}

// MARK: Picker
extension UserListView {
    private var pickerView: some View {
        VStack {
            Picker("tab button type", selection: $viewModel.pickerSelecter) {
                ForEach(pickerButtonType, id: \.rawValue) { buttonType in
                    Text(buttonType.rawValue)
                }
            }
            .onChange(of: viewModel.pickerSelecter, { _, _ in
                viewModel.getFavoriteUserList(query: viewModel.searchText)
            })
            .colorMultiply(.blue)
            .pickerStyle(.segmented)
        }
    }
}

// MARK: User ForEach View
extension UserListView {
    private var userView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.headers.isEmpty {
                    setUserBodyList("")
                } else {
                    ForEach(viewModel.headers, id: \.self) { header in
                        setFavoriteUserHeadList(header)
                        setUserBodyList(header)
                    }
                }
                Spacer()
            }
        }
    }
    
    private func setFavoriteUserHeadList(_ header: String) -> some View {
        VStack {
            Text(header)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .font(.title3)
                .bold()
                .foregroundStyle(.gray)
        }
    }
    
    private func setUserBodyList(_ header: String) -> some View {
        Group {
            if viewModel.pickerSelecter == "All" {
                ForEach(viewModel.userList, id: \.user.repository.owner.id) { user, isFavorite in
                    setUserCell(user: user, isFavorite: isFavorite)
                }
            } else {
                ForEach(viewModel.favoriteUserList, id: \.repository.owner.id) { user in
                    existedHeader(header: header, user: user)
                }
            }
        }
    }
    
    private func existedHeader(header: String, user: UserRepositoryModel) -> some View {
        Group {
            if header == user.repository.owner.login.first?.uppercased() {
                setUserCell(user: user, isFavorite: true)
            }
        }
    }
    
    private func setUserCell(user: UserRepositoryModel, isFavorite: Bool) -> some View {
        HStack {
            if let url = URL(string: user.repository.owner.imageURL) {
                WebImage(url: url)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                Image(systemName: "person.circle")
                    .frame(width: 120, height: 120)
                    .clipShape(.rect(cornerRadius: 8))
            }
            Spacer()
            
            Text(user.repository.owner.login)
                .font(.title3)
            
            Spacer()
            
            Button {
                isFavorite
                ? viewModel.deleteFavoriteUser(id: user.repository.owner.id)
                : viewModel.saveFavoriteUser(user: user)
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            // MARK: Paging at the end of userList
            guard let lastUser = viewModel.userList.last else { return }
            if user == lastUser.user {
                viewModel.queryPaging()
            }
        }
        .padding()
    }
}
    
    
// MARK: Preview
#Preview {
    let persistenceController = PersistenceController.shared
    
    let viewContext = persistenceController.container.viewContext
    let userCoreData = UserCoreData(viewContext: viewContext)
    let network = UserNetwork(networkMangaer: UserNetworkManager(session: UserSession()))
    let userRepository = UserRepository(userCoreData: userCoreData, network: network)
    let userUsecase = UserUsecase(userRepository: userRepository)
    let userVM = UserViewModel(usecase: userUsecase)
    
    UserListView(viewModel: userVM)
    //        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
