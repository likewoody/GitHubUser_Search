//
//  GitHubUser_SearchApp.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import SwiftUI

@main
struct GitHubUser_SearchApp: App {
    let persistenceController = PersistenceController.shared
    
    var userCoreData: UserCoreDataProtocol
    var network: UserNetworkProtocol
    var userRepository: UserRepositoryProtocol
    var userUsecase: UserUsecaseProtocol
    var userVM: UserViewModel
    
    init() {
        let viewContext = persistenceController.container.viewContext
        userCoreData = UserCoreData(viewContext: viewContext)
        network = UserNetwork(networkMangaer: UserNetworkManager(session: UserSession()))
        userRepository = UserRepository(userCoreData: userCoreData, network: network)
        userUsecase = UserUsecase(userRepository: userRepository)
        userVM = UserViewModel(usecase: userUsecase)
    }

    var body: some Scene {
        
        WindowGroup {
            UserListView(viewModel: userVM)
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
