//
//  TutorRepository.swift
//  CICompanion
//
//  Created by Wummiez on 4/26/26.
//

import Foundation

class TutorRepository {
    
    func loadTutors() throws -> [Tutor] {
        let url = Bundle.main.url(forResource: "tutors", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let tutors = try JSONDecoder().decode([Tutor].self, from: data)
        
        return tutors
    }
}
