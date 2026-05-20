import SwiftUI

@MainActor
struct ContactInformation: View {
    
    let messagingRepository: MessagingRepositoryProtocol
    let courseRepository: CourseRepositoryProtocol
    let participantId: String
    let currentStudentId: String?

    @State private var isLoading = false
    @State private var loadError: String?
    @State private var selectedStudent: Student?
    @State private var selectedStudentCourses: [Course] = []
    @State private var sharedCourseIds: Set<Int> = []
    
    init(
        messagingRepository: MessagingRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol,
        participantId: String,
        currentStudentId: String? = nil
    ) {
        self.messagingRepository = messagingRepository
        self.courseRepository = courseRepository
        self.participantId = participantId
        self.currentStudentId = currentStudentId
    }
    
    var body: some View {
        CIView {
            CIScrollView {
                
                if let student = selectedStudent {
                    VStack(alignment: .leading, spacing: 4) {
                        CIPageTitle(student.name)
                        
                        Text("Email: \(student.email)")
                            .foregroundColor(ViewHelper.text)
                            .font(.system(size: ViewHelper.textSize))
                    }
                }
                
                if isLoading {
                    CILoadingPage()
                    
                } else if let error = loadError {
                    CIErrorMessage(errorMessage: error)
                    
                } else {
                    
                    VStack(alignment: .leading, spacing: ViewHelper.biggerSpacing) {
                       
                        Text("Weekday Availability")
                            .foregroundColor(ViewHelper.textImportant)
                            .font(.system(size: ViewHelper.textSize, weight: .semibold))
                            
                        VStack(alignment: .leading, spacing: 12) {
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Most Available Times")
                                    .font(.system(size: ViewHelper.smallTextSize, weight: .medium))
                                    .foregroundColor(ViewHelper.text)
                                
                                Text(bestMeetingWindow())
                                    .font(.system(size: ViewHelper.textSize + 2, weight: .bold))
                                    .foregroundColor(ViewHelper.accentBlue)
                                
                                Rectangle()
                                    .fill(ViewHelper.text)
                                    .frame(height: 0.5)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                
                                HStack(alignment: .top, spacing: 34.4) {
                                    TimeMarker(hour: "8", meridiem: "AM")
                                    TimeMarker(hour: "10", meridiem: "AM")
                                    TimeMarker(hour: "12", meridiem: "PM")
                                    TimeMarker(hour: "2", meridiem: "PM")
                                    TimeMarker(hour: "4", meridiem: "PM")
                                    TimeMarker(hour: "6", meridiem: "PM")
                                    TimeMarker(hour: "8", meridiem: "PM")
                                }
                                
                                HStack(alignment: .center, spacing: 10) {
                                    ForEach(Array(8...20), id: \.self) { hour in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                isFreeOnWeekdays(hour: hour)
                                                ? ViewHelper.accentBlue
                                                : ViewHelper.cardBgColor
                                            )
                                            .frame(width: 14, height: 32)
                                    }
                                }
                            }
                        }
                        .padding(ViewHelper.padding)
                        .background(ViewHelper.fieldBgColor)
                        .cornerRadius(ViewHelper.componentRounding)
                    }
                    
                    Text("Courses")
                        .foregroundColor(ViewHelper.textImportant)
                        .font(.system(size: ViewHelper.textSize, weight: .semibold))
                    
                    if selectedStudentCourses.isEmpty {
                        CIText("No courses found", color: ViewHelper.text)
                    } else {
                        ForEach(selectedStudentCourses, id: \.id) { course in
                            ZStack(alignment: .topTrailing) {
                                CIDropDownCard(
                                    title: course.courseName,
                                    subtitle: course.location,
                                    before: {
                                        if let occurrence = course.firstScheduledOccurrence {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(occurrence.startTime)
                                                    .font(.system(size: ViewHelper.smallTextSize))

                                                Text(occurrence.endTime)
                                                    .font(.system(size: ViewHelper.smallTextSize))
                                            }
                                            .foregroundColor(ViewHelper.text)
                                            .frame(width: 70, alignment: .leading)
                                        } else {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Arranged")
                                                    .font(.system(size: ViewHelper.smallTextSize))
                                                
                                                Text("No times")
                                                    .font(.system(size: ViewHelper.smallTextSize))
                                            }
                                            .foregroundColor(ViewHelper.text)
                                            .frame(width: 70, alignment: .leading)
                                        }
                                    },
                                    expandedContent: {
                                        Text(course.courseDescription)
                                            .foregroundColor(ViewHelper.text)
                                            .lineLimit(10)
                                    },
                                    color: ViewHelper.accentBlue
                                )
                                
                                if sharedCourseIds.contains(course.id) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(ViewHelper.accentBlue)
                                        .padding(.top, 14)
                                        .padding(.trailing, 14)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .task(id: participantId) {
            if selectedStudent == nil {
                await loadContact()
            }
        }
    }
    
    private func bestMeetingWindow() -> String {
        
        var freeHours: [Int] = []
        
        for hour in 8...20 {
            if isFreeOnWeekdays(hour: hour) {
                freeHours.append(hour)
            }
        }
        
        if freeHours.isEmpty {
            return "Limited"
        }
        
        var ranges: [(startHour: Int, endHour: Int)] = []
        
        var rangeStart = freeHours[0]
        var rangeEnd = freeHours[0]
        
        for hour in freeHours.dropFirst() {
            if hour == rangeEnd + 1 {
                rangeEnd = hour
            } else {
                ranges.append((startHour: rangeStart, endHour: rangeEnd))
                rangeStart = hour
                rangeEnd = hour
            }
        }
        
        ranges.append((startHour: rangeStart, endHour: rangeEnd))
        
        ranges.sort { first, second in
            let firstSize = first.endHour - first.startHour
            let secondSize = second.endHour - second.startHour
            
            if firstSize == secondSize {
                return first.startHour < second.startHour
            }
            
            return firstSize > secondSize
        }
        
        if ranges.count == 1 {
            let range = ranges[0]
            return "\(formatHour(range.startHour)) - \(formatHour(range.endHour + 1))"
        }

        let firstRange = ranges[0]
        let secondRange = ranges[1]

        if firstRange.startHour < secondRange.startHour {
            return "\(formatHour(firstRange.startHour)) - \(formatHour(firstRange.endHour + 1))      \(formatHour(secondRange.startHour)) - \(formatHour(secondRange.endHour + 1))"
        } else {
            return "\(formatHour(secondRange.startHour)) - \(formatHour(secondRange.endHour + 1))      \(formatHour(firstRange.startHour)) - \(formatHour(firstRange.endHour + 1))"
        }
    }

    private func formatHour(_ hour: Int) -> String {
        
        if hour == 24 {
            return "12 AM"
        }
        
        if hour == 12 {
            return "12 PM"
        }
        
        if hour < 12 {
            return "\(hour) AM"
        }
        
        return "\(hour - 12) PM"
    }

    private func isFreeOnWeekdays(hour: Int) -> Bool {
        
        for course in selectedStudentCourses {
            for occurrence in course.scheduledOccurrences {
                let isWeekdayCourse =
                    occurrence.days.contains("Monday") ||
                    occurrence.days.contains("Tuesday") ||
                    occurrence.days.contains("Wednesday") ||
                    occurrence.days.contains("Thursday") ||
                    occurrence.days.contains("Friday")

                if !isWeekdayCourse {
                    continue
                }

                let startHour = parseHour(occurrence.startTime)
                let endHour = parseHour(occurrence.endTime)

                if startHour == -1 || endHour == -1 {
                    continue
                }

                if hour >= startHour && hour < endHour {
                    return false
                }
            }
        }
        
        return true
    }

    private func parseHour(_ time: String) -> Int {
        guard let minutes = DateHelper.timeStringToMinutes(time) else {
            return -1
        }

        return minutes / 60
    }
    
    private func loadContact() async {
        isLoading = true
        loadError = nil
        selectedStudent = nil
        selectedStudentCourses = []
        sharedCourseIds = []
        
        defer { isLoading = false }
        
        do {
            let contact = try await messagingRepository.loadContact(studentId: participantId)
            let allCourses = try await courseRepository.loadAllCourses()
            
            selectedStudent = contact
            selectedStudentCourses = allCourses.filter {
                contact.courses.contains($0.id)
            }
            
            if let currentStudentId {
                let currentStudent = try await messagingRepository.loadContact(studentId: currentStudentId)
                
                sharedCourseIds = Set(currentStudent.courses).intersection(Set(contact.courses))
            }
            
        } catch {
            loadError = error.localizedDescription
        }
    }
}
