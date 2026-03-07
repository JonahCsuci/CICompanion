//
//  CourseRepository.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

// Repository = data layer.
// Its job is to load data.
// For now it reads local JSON files.
// Later this can be changed to API/database code.
class CourseRepository {
    
    // During this sprint I will change these to fetch from database
    // You can mess with these if you want to fetch the data from
    // the JSON files differently at the moment
    
    // Load all courses from courses.json
    func loadAllCourses() throws -> [Course] {
        let url = Bundle.main.url(forResource: "courses", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let courses = try JSONDecoder().decode([Course].self, from: data)
        return courses
    }
    
    // Load the student from student.json
    func loadStudent() throws -> Student {
        let url = Bundle.main.url(forResource: "student", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let student = try JSONDecoder().decode(Student.self, from: data)
        return student
    }
    
    // Load only the courses that belong to the student
    func loadStudentCourses() throws -> [Course] {
        let courses = try loadAllCourses()
        let student = try loadStudent()
        
        let myCourses = courses.filter {
            student.courses.contains($0.id)
        }
        
        return myCourses
    }
}
