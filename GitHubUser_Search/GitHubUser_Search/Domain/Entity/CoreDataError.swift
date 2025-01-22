//
//  CoreDataError.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Foundation

public enum CoreDataError: Error {
    case notFoundEntity(String), saveFavoriteUserFailed(String), deleteFavoriteUserFailed(String), readEntity(String)
    
    public var description: String {
        switch self {
        case .notFoundEntity(let objectName):
            "객체를 찾을 수 없습니다 : \(objectName)"
        case .saveFavoriteUserFailed(let message):
            "객체 저장 실패 : \(message)"
        case .readEntity(let message):
            "객체 삭제 실패 : \(message)"
        case .deleteFavoriteUserFailed(let message):
            "객체 읽기 실패 : \(message)"
        }
    }
}
