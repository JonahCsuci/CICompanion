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
    
    // Shared student repository object, used by course and events repositories
    let studentRepository: StudentRepositoryProtocol = StudentRepository()
    
    lazy var courseRepository: CourseRepositoryProtocol =
        CourseRepository(studentRepository: studentRepository)
    
    lazy var eventsRepository: EventsRepositoryProtocol =
        EventsRepository(studentRepository: studentRepository)
    
    lazy var apiTestViewModel = APITestViewModel(
        courseRepository: courseRepository,
        eventsRepository: eventsRepository,
        studentRepository: studentRepository
    )
    
    lazy var studentCoursesViewModel = StudentCoursesViewModel(
        courseRepository: courseRepository,
        studentRepository: studentRepository
    )
    
    lazy var coursesListViewModel = CoursesListViewModel(
        courseRepository: courseRepository,
        studentRepository: studentRepository
    )
    
    lazy var addClassViewModel = AddClassViewModel(
        courseRepository: courseRepository,
        studentRepository: studentRepository
    )
    
    lazy var myAcademicCalendarViewModel = MyAcademicCalendarViewModel(
        courseRepository: courseRepository,
        studentRepository: studentRepository
    )
    
    lazy var eventsViewModel = EventsViewModel(
        eventsRepository: eventsRepository,
        studentRepository: studentRepository
    )
}
