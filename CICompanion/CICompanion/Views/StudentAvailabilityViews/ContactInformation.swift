import SwiftUI

@MainActor
struct ContactInformation: View {
    
    let messagingRepository: MessagingRepositoryProtocol
    let courseRepository: CourseRepositoryProtocol
    let participantId: String

    @State private var isLoading = false
    @State private var loadError: String?
    @State private var selectedStudent: Student?
    @State private var selectedStudentCourses: [Course] = []
    
    init(
        messagingRepository: MessagingRepositoryProtocol,
        courseRepository: CourseRepositoryProtocol,
        participantId: String
    ) {
        self.messagingRepository = messagingRepository
        self.courseRepository = courseRepository
        self.participantId = participantId
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
                        CIText("No courses found", ViewHelper.text)
                    } else {
                        ForEach(selectedStudentCourses, id: \.id) { course in
                            CIDropDownCard(
                                title: course.courseName,
                                subtitle: course.location,
                                before: {
                                    if course.startTime == "N/A" {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Async")
                                                .font(.system(size: ViewHelper.smallTextSize))
                                            
                                            Text("No times")
                                                .font(.system(size: ViewHelper.smallTextSize))
                                        }
                                        .foregroundColor(ViewHelper.text)
                                        .frame(width: 70, alignment: .leading)
                                    } else {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(course.startTime)
                                                .font(.system(size: ViewHelper.smallTextSize))
                                            
                                            Text(course.endTime)
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
        
        // every free hour from 8 AM to 8 PM
        for hour in 8...20 {
            if isFreeOnWeekdays(hour: hour) {
                freeHours.append(hour)
            }
        }
        
        if freeHours.isEmpty {
            return "Limited"
        }
        
        // group consecutive free hours into time ranges
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
        
        // add the final range
        ranges.append((startHour: rangeStart, endHour: rangeEnd))
        
        // sort by longest range first
        ranges.sort { first, second in
            let firstSize = first.endHour - first.startHour
            let secondSize = second.endHour - second.startHour
            
            if firstSize == secondSize {
                return first.startHour < second.startHour
            }
            
            return firstSize > secondSize
        }
        
        // turn best 1 or 2 ranges into display text
        if ranges.count == 1 {
            let range = ranges[0]
            return "\(formatHour(range.startHour)) - \(formatHour(range.endHour + 1))"
        }
        
        let firstRange = ranges[0]
        let secondRange = ranges[1]
        
        if firstRange.startHour < secondRange.startHour {
            return "\(formatHour(firstRange.startHour)) - \(formatHour(firstRange.endHour + 1)) \(formatHour(secondRange.startHour)) - \(formatHour(secondRange.endHour + 1))"
        } else {
            return "\(formatHour(secondRange.startHour)) - \(formatHour(secondRange.endHour + 1)) \(formatHour(firstRange.startHour)) - \(formatHour(firstRange.endHour + 1))"
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
            
            let isWeekdayCourse =
                course.days.contains("Monday") ||
                course.days.contains("Tuesday") ||
                course.days.contains("Wednesday") ||
                course.days.contains("Thursday") ||
                course.days.contains("Friday")
            
            if !isWeekdayCourse {
                continue
            }
            
            let startHour = parseHour(course.startTime)
            let endHour = parseHour(course.endTime)
            
            if startHour == -1 || endHour == -1 {
                continue
            }
            
            if hour >= startHour && hour < endHour {
                return false
            }
        }
        
        return true
    }

    private func parseHour(_ time: String) -> Int {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        guard let date = formatter.date(from: time) else {
            return -1
        }
        
        return Calendar.current.component(.hour, from: date)
    }
    
    private func loadContact() async {
        isLoading = true
        loadError = nil
        selectedStudent = nil
        selectedStudentCourses = []
        
        defer { isLoading = false }
        
        do {
            let contact = try await messagingRepository.loadContact(studentId: participantId)
            let allCourses = try await courseRepository.loadAllCourses()
            
            selectedStudent = contact
            selectedStudentCourses = allCourses.filter {
                contact.courses.contains($0.id)
            }
            
        } catch {
            loadError = error.localizedDescription
        }
    }
}
