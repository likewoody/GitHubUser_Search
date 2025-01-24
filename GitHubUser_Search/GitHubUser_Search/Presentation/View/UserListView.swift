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
    let pickerButtonType: [PickerButtonType] = [.all, .favorite]
    @State private var cancellable = Set<AnyCancellable>()
    @State private var pickerSelecter: String = "all"
    @StateObject private var viewModel: UserViewModel

    init(viewModel: UserViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            userTextField
            
            pickerView
            Spacer()
            
            userView
            Spacer()
        }
    }
}

// MARK: TextField
extension UserListView {
    var userTextField: some View {
        VStack {
            TextField("\(Image(systemName: "magnifyingglass")) 검색어를 입력하세요.", text: $viewModel.searchText)
                .frame(maxWidth: .infinity)
                .textFieldStyle(.roundedBorder)
                .padding()
                .font(.headline)
        }
    }
}

// MARK: Picker
extension UserListView {
    var pickerView: some View {
        VStack {
            Picker("tab button type", selection: $pickerSelecter) {
                ForEach(pickerButtonType, id: \.rawValue) { buttonType in
                    Text(buttonType.rawValue.capitalized)
                }
            }
            .colorMultiply(.blue)
            .pickerStyle(.segmented)
        }
    }
}

extension UserListView {
    var userView: some View {
        ScrollView {
            ForEach(viewModel.userList, id: \.repository.owner.id) { user in
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
                    Image(systemName: "heart")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
                .padding()
            }
        }
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
