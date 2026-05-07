//
//  APIErrorResponse.swift
//  CICompanion
//
//  Created by Wummiez on 3/20/26.
//

import Foundation

struct APIErrorResponse: Decodable {
    let error: String

    private enum CodingKeys: String, CodingKey {
        case error
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decodeIfPresent(String.self, forKey: .error)
            ?? container.decodeIfPresent(String.self, forKey: .message)
            ?? "Unknown error"
    }
}
