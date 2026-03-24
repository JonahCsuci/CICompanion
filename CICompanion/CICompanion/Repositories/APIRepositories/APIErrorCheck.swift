//
//  APIUtils.swift
//  CICompanion
//
//  Created by Wummiez on 3/20/26.
//

import Foundation

func handleErrorResponse(data: Data, response: URLResponse) throws {
    
    // Checks if response received is valid
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    
    // Checks if response code was successful or an error was returned
    if httpResponse.statusCode != 200 {
        
        // Stores error in APIErrorResponse struct
        let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        
        // Details for error response to be displayed to user
        throw NSError(
            domain: "APIError",
            code: httpResponse.statusCode,
            userInfo: [
                
                // If apiError is nil (no valid JSON was decoded),
                // give defaulted 'Unkown error' to display
                NSLocalizedDescriptionKey: apiError?.error ?? "Unknown error"
            ]
        )
    }
}
