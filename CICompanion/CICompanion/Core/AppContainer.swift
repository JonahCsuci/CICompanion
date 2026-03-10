//
//  AppContainer.swift
//  CICompanion
//
//  Created by Wummiez on 3/6/26.
//

import Foundation

// AppContainer = central place for dependency injection.
// It creates shared objects once and passes them where needed.
class AppContainer {
    
    // Shared repository object
    let studentRepository = StudentRepository()
    lazy var courseRepository: CourseRepositoryProtocol = CourseRepository(studentRepository: studentRepository)
    
    lazy var eventRepository: EventsRepositoryProtocol = EventsRepository(studentRepository: studentRepository)
    
    // ViewModels that receive the repository object
    lazy var studentCoursesViewModel = StudentCoursesViewModel(repository: courseRepository)
    lazy var eventsCourseViewModel = EventsViewModel(repository: eventRepository)
}
