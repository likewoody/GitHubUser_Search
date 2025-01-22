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

    var body: some Scene {
        WindowGroup {
            UserListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
