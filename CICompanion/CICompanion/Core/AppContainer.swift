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
    let courseRepository = CourseRepository()
    let eventsRepository = EventsRepository()
    
    // ViewModels that receive the repository object
    
    //lazy means the variable will not be created until it is first used
    // Basically are created when something accesses them for the first time
    lazy var coursesViewModel = CourseViewModel(repository: courseRepository)
    lazy var studentCoursesViewModel = StudentCoursesViewModel(repository: courseRepository)
    lazy var eventsViewModel = EventsViewModel(repository: eventsRepository)
    
    // Explaining coursesViewModel (studentCoursesViewModel behaves the same way)
    // coursesViewModel is an object of the CourseViewModel class
    // When it is created, we pass in the CourseRepository object that was created at the top of AppContainer
    // Because CourseViewModel accepts a CourseRepository object in its initializer,
    // the ViewModel can use that repository object to load course data.
    
    // This is dependency injection, instead of a class creating the objects it needs,
    // those objects are created elsewhere (like in this class) and passed in
    // This keeps code easier to organize, reuse, and change later to my understanding
    
}
