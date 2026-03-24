//
//  APIUtils.swift
//  CICompanion
//
//  Created by Wummiez on 3/20/26.
//

import Foundation

func handleErrorResponse(data: Data, response: URLResponse) throws {
    
    // Ensures the response is a valid HTTP response
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    
    // Checks if the status code indicates a failure
    if httpResponse.statusCode != 200 {
        
        // Attempts to decode error message returned from API
        let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        
        // Throw an error with status code and message for UI/display
        throw NSError(
            domain: "APIError",
            code: httpResponse.statusCode,
            userInfo: [
                
                // Use API error message if available, otherwise fallback on Unknown error
                NSLocalizedDescriptionKey: apiError?.error ?? "Unknown error"
            ]
        )
    }
}
