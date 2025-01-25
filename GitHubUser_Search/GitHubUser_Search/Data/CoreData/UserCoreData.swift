//
//  UserCoreData.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/23/25.
//

import Combine
import CoreData

public protocol UserCoreDataProtocol {
    func getFavoriteUserList() -> AnyPublisher<[UserRepositoryModel], CoreDataError>
    func saveFavoriteUser(user: UserRepositoryModel) -> AnyPublisher<Bool, CoreDataError>
    func deleteFavoriteUser(id: Int) -> AnyPublisher<Bool, CoreDataError>
}

public struct UserCoreData: UserCoreDataProtocol {
    
    let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    public func getFavoriteUserList() -> AnyPublisher<[UserRepositoryModel], CoreDataError> {
        let fetchRequest: NSFetchRequest<FavoriteUser> = FavoriteUser.fetchRequest()
        do {
            let result = try viewContext.fetch(fetchRequest)
            let userList: [UserRepositoryModel] = result.compactMap { favoriteUser in
                if let login = favoriteUser.login,
                   let imageURL = favoriteUser.imageURL {
                    return UserRepositoryModel(repository: UserOwnerModel(owner: UserModel(id: Int(favoriteUser.id), login: login, imageURL: imageURL)))
                }
                return nil
            }
            return Just(userList)
                .setFailureType(to: CoreDataError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: CoreDataError.readEntity(error.localizedDescription)).eraseToAnyPublisher()
        }
    }
    public func saveFavoriteUser(user: UserRepositoryModel) -> AnyPublisher<Bool, CoreDataError> {
        guard let entity = NSEntityDescription.entity(forEntityName: "FavoriteUser", in: viewContext) else { return Fail(error: CoreDataError.notFoundEntity("FavoriteUser Not Found Error")).eraseToAnyPublisher()}
        
        let userObject = NSManagedObject(entity: entity, insertInto: viewContext)
        userObject.setValue(user.repository.owner.id, forKey: "id")
        userObject.setValue(user.repository.owner.login, forKey: "login")
        userObject.setValue(user.repository.owner.imageURL, forKey: "imageURL")
        do {
            try viewContext.save()
            return Just(true)
                .setFailureType(to: CoreDataError.self)
                .eraseToAnyPublisher()
        } catch  {
            return Fail(error: CoreDataError.saveFavoriteUserFailed("ENTITY SAVE ERROR :\n\(error.localizedDescription)")).eraseToAnyPublisher()
        }
        
    }
    public func deleteFavoriteUser(id: Int) -> AnyPublisher<Bool, CoreDataError> {
        let fetchRequest: NSFetchRequest<FavoriteUser> = FavoriteUser.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        do {
            let result = try viewContext.fetch(fetchRequest)
            guard let resultFirst = result.first else { return Fail(error: CoreDataError.notFoundEntity("USER DELETE BY ID ERROR")).eraseToAnyPublisher()}
            viewContext.delete(resultFirst)
            try viewContext.save()
            return Just(true)
                .setFailureType(to: CoreDataError.self)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: CoreDataError.deleteFavoriteUserFailed("USER DELETE BY ID ERROR \n\(error.localizedDescription)")).eraseToAnyPublisher()
        }
    }
}
