//
//  NetworkError.swift
//  GitHubUser_Search
//
//  Created by Woody on 1/22/25.
//

import Foundation

enum NetworkError: Error {
    case urlError, invalidResponse, dataNil
    case failedToDecode(String), requestFailed(String)
    case serverError(Int)
    
    var description: String {
        switch self {
        case .urlError:
            "URL이 올바르지 않습니다."
        case .invalidResponse:
            "응답값이 유효하지 않습니다."
        case .failedToDecode(let description):
            "디코딩 에러 \(description)"
        case .dataNil:
            "데이터가 없습니다."
        case .serverError(let statusCode):
            "서버 에러 \(statusCode)"
        case .requestFailed(let message):
            "서버 요청 실패 \(message)"
        }
    }
}
