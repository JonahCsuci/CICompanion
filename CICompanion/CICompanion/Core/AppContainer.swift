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
    
    // Shared auth/session state
    let sessionManager = SessionManager()
    
    // Shared student repository object, used by course and events repositories
    lazy var studentRepository: StudentRepositoryProtocol =
    APIStudentRepository(sessionManager: sessionManager)
    
    lazy var courseRepository: CourseRepositoryProtocol =
        APICourseRepository(studentRepository: studentRepository)
    
    
    lazy var tutorRepository = TutorRepository()
    
    lazy var tutorViewModel = TutorViewModel(tutorRepository: tutorRepository)
    
    lazy var apiTestViewModel = APITestViewModel(
        courseRepository: courseRepository,
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
    
    lazy var myAcademicCalendarViewModel = AcademicCalendarViewModel(
        courseRepository: courseRepository,
        studentRepository: studentRepository
    )

    lazy var messagingRepository: MessagingRepositoryProtocol =
        APIMessagingRepository(sessionManager: sessionManager)

    lazy var conversationsViewModel = ConversationsViewModel(
        messagingRepository: messagingRepository
    )

    lazy var contactRequestsViewModel = ContactRequestsViewModel(
        studentRepository: studentRepository
    )

    lazy var realtimeService = RealtimeService()
}
