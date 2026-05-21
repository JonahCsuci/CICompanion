//
//  CourseViewModel.swift
//  CICompanion
//
//  Created by Emma on 3/23/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class CourseViewModel: ObservableObject {
    @Published var course : Course
    @Published var hasCourse : Bool = false
    
    init(course: Course) {
        _course = Published(initialValue: course)
    }
    
    func getDatesDisplay(course: Course) -> String {
        if course.days.isEmpty {
            return "Arranged"
        }

        return course.days.joined(separator: ", ")
    }
}
