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
                    
                    availabilitySection
                    
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
    
    private var availabilitySection: some View {
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
                
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack(alignment: .top, spacing: 16) {
                        
                        TimeMarker(hour: "8", meridiem: "AM")
                        TimeMarker(hour: "10", meridiem: "AM")
                        TimeMarker(hour: "12", meridiem: "PM")
                        
                        Spacer()
                            .frame(width: 1)
                        
                        TimeMarker(hour: "2", meridiem: "PM")
                        TimeMarker(hour: "4", meridiem: "PM")
                        TimeMarker(hour: "6", meridiem: "PM")
                        TimeMarker(hour: "8", meridiem: "PM")
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        
                        ForEach(Array(8...20), id: \.self) { hour in
                            if hour == 14 {
                                Spacer()
                                    .frame(width: 8)
                            }
                            
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
        
        var ranges: [(start: Int, text: String, size: Int)] = []
        
        var start = freeHours[0]
        var end = freeHours[0]
        
        for hour in freeHours.dropFirst() {
            
            if hour == end + 1 {
                end = hour
            } else {
                ranges.append((
                    start: start,
                    text: "\(formatHour(start)) - \(formatHour(end + 1))",
                    size: end - start + 1
                ))
                
                start = hour
                end = hour
            }
        }
        
        ranges.append((
            start: start,
            text: "\(formatHour(start)) - \(formatHour(end + 1))",
            size: end - start + 1
        ))
        
        ranges.sort {
            if $0.size == $1.size {
                return $0.start < $1.start
            }
            return $0.size > $1.size
        }
        
        if ranges.count == 1 {
            return ranges[0].text
        }
        
        let topTwo = [ranges[0], ranges[1]].sorted { $0.start < $1.start }
        
        return topTwo[0].text + "       " + topTwo[1].text
    }

    private func formatHour(_ hour: Int) -> String {
        
        if hour == 12 {
            return "12 PM"
        }
        
        if hour < 12 {
            return "\(hour) AM"
        }
        
        if hour == 24 {
            return "12 AM"
        }
        
        return "\(hour - 12) PM"
    }

    private func isFreeOnWeekdays(hour: Int) -> Bool {
        
        for course in selectedStudentCourses {
            
            if course.days.contains("Monday") ||
               course.days.contains("Tuesday") ||
               course.days.contains("Wednesday") ||
               course.days.contains("Thursday") ||
               course.days.contains("Friday") {
                
                let start = parseHour(course.startTime)
                let end = parseHour(course.endTime)
                
                if start != -1 && end != -1 {
                    if hour >= start && hour < end {
                        return false
                    }
                }
            }
        }
        
        return true
    }

    private func parseHour(_ time: String) -> Int {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if let date = formatter.date(from: time) {
            return Calendar.current.component(.hour, from: date)
        }
        
        return -1
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
