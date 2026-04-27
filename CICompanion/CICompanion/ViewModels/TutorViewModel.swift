//
//  TutorViewModel.swift
//  CICompanion
//
//  Created by Wummiez on 4/26/26.
//

import Foundation
import Combine

@MainActor
class TutorViewModel: ObservableObject {
    
    @Published var tutors: [Tutor] = []
    
    let tutorRepository: TutorRepository
    
    init(tutorRepository: TutorRepository) {
        self.tutorRepository = tutorRepository
    }
    
    func loadTutors() {
        do {
            tutors = try tutorRepository.loadTutors()
        } catch {
            print("Error loading tutors:", error)
        }
    }
}
