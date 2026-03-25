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
        var str = ""
        
        for day in course.days {
            str += day + ", "
        }
        
        // remove the last ", "
        
        str.removeLast(2)
        
        return str
    }
}
