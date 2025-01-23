//
//  GitHubUser_SearchTests.swift
//  GitHubUser_SearchTests
//
//  Created by Woody on 1/23/25.
//

import XCTest
@testable import GitHubUser_Search
import Combine

final class GitHubUser_SearchTests: XCTestCase {
    
    private var session: UserSessionProtocol {
        let session = UserSession()
        return session
    }
    private var networkManager: MoakNetworkManagerProtocol {
        let networkManager = UserNetworkManager(session: session)
        return networkManager
    }
    private var cancellable = Set<AnyCancellable>()
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_UserNetworkManager_TestFunc_Success() throws {
        // given
        let urlString = "https://api.github.com/search/code?q=\("")&page=\(1)"
//        networkManager.fetchUser(urlString: urlString, method: .get, parameters: nil)
        
        // when
        networkManager.testFunc(urlString: urlString)
        
        // then
        print("should be exact urlString and Headers inside func")
    }
    
    
    func test_UserNetworkManager_FetchUser_Success() async throws {
        // given
        let urlString = "https://api.github.com/search/code?q=dd&page=\(1)"
        var userList: [UserItemsModel] = []
        
        // when
        await networkManager.fetchUser(urlString: urlString, method: .get, parameters: nil)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { (user: UserRepositoryModel) in
                print("check user : \(user)")
            }
            .store(in: &cancellable)
        
        // then
        XCTAssertTrue(userList.count > 0)
        
    }

}

