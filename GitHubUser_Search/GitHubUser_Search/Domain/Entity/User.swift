//
//  User.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Foundation

public struct UserItemsModel: Codable {
    let items: [UserRepositoryModel]
}

public struct UserRepositoryModel: Codable {
    let repository: UserOwnerModel
}

public struct UserOwnerModel: Codable {
    let owner: UserModel
}

public struct UserModel: Codable {
    let id: Int
    let login, imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case imageURL = "avatar_url"
    }
    
    public init(id: Int, login: String, imageURL: String) {
        self.id = id
        self.login = login
        self.imageURL = imageURL
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.login = try container.decode(String.self, forKey: .login)
        self.imageURL = try container.decode(String.self, forKey: .imageURL)
    }
}
