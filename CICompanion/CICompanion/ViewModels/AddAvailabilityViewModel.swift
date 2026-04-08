//
//  AddAvailabilityViewModel.swift
//  CICompanion
//
//  Created by Emma on 4/8/26.
//

import SwiftUI
import Combine
import Foundation

@MainActor
class AddAvailabilityViewModel: ObservableObject {
    let meetingScheduler: MeetingScheduler

    let courses: [Course]
    @Published var selectedRanges: [TimeRange] = []

    init(
        meetingScheduler: MeetingScheduler,
        courses: [Course]
    ) {
        self.meetingScheduler = meetingScheduler
        self.courses = courses
    }
    
    
}
