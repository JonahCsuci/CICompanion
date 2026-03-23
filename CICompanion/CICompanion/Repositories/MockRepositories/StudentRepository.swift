//
//  StudentRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/9/26.
//

import Foundation

class StudentRepository: StudentRepositoryProtocol {
    
    // Stored student in memory (mock data)
    private var student: Student?
    
    // Load student from JSON the first time
    func loadStudent() async throws -> Student {
        
        // If student has previously been loaded in, return it back
        if let student {
            return student
        }
        
        let url = Bundle.main.url(forResource: "student", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decodedStudent = try JSONDecoder().decode(Student.self, from: data)
        
        student = decodedStudent
        return decodedStudent
    }
    
    // Add a course to the student's courses array
    func addStudentCourse(courseId: Int) async throws {
        
        if var student = student {
            if !student.courses.contains(courseId) {
                student.courses.append(courseId)
            }
            self.student = student
        }
    }
    
    // Remove a course from the student's courses array
    func deleteStudentCourse(courseId: Int) async throws {
        
        if var student = student {
            student.courses.removeAll { $0 == courseId }
            self.student = student
        }
    }
    
    func hasStudentCourse(courseId: Int) async throws -> Bool {
        if let student = student {
            return student.courses.contains(courseId)
        } else {
            return false
        }
    }
    
    // Add event to the student's event array
    func addStudentEvent(eventId: Int) async throws {
        
        if var student = student {
            if !student.events.contains(eventId) {
                student.events.append(eventId)
            }
            self.student = student
        }
    }

    // Remove event from the student's event array
    func deleteStudentEvent(eventId: Int) async throws {
        
        if var student = student {
            student.events.removeAll { $0 == eventId }
            self.student = student
        }
    }
}
