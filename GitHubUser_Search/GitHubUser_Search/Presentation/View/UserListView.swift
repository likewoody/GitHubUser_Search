//
//  ContentView.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import SwiftUI
import CoreData
import Combine

struct UserListView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteUser.login, ascending: true)],
//        animation: .default)
//    private var coreDataFavoriteUser: FetchedResults<FavoriteUser>
//    @State private var userList: [UserRepositoryModel] = []
    @State private var cancellable = Set<AnyCancellable>()
    private let viewModel: UserViewModelProtocol
    
    init(viewModel: UserViewModelProtocol) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                Text("test")
//                ForEach(userList, id: \.repository.owner.id) { user in
//                    user.repository.owner.id
//                }
            }
//            List {
//                ForEach(coreDataFavoriteUser) { user in
//                    NavigationLink {
//                        Text("Item at \(user.id)")
//                    } label: {
//                        Text(user.login!)
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
        }
//        .onAppear(perform: {
//            print("onAppear start")
//            let session = UserSession()
//            let networkManager = UserNetworkManager(session: session)
////
//            let urlString = "https://api.github.com/search/code?q=dd&page=1"
//            Task {
//                print("task start")
//                await networkManager.fetchUser(urlString: urlString, method: .get, parameters: nil)
//                    .receive(on: DispatchQueue.main)
//                    .sink { completion in
//                        switch completion {
//                        case .finished: break
//                        case .failure(let error):
//                            print(error.description)
//                        }
//                    } receiveValue: { (user: UserItemsModel) in
//                        print(user.items)
//                    }
//                    .store(in: &cancellable)
//                
//                print("task finish")
//            }
//            print("onAppear finish")
//        })
    }

//    private func addItem() {
//        withAnimation {
//            let newItem = FavoriteUser(context: viewContext)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
////            offsets.map { items[$0] }.forEach(viewContext.delete)
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
}

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
