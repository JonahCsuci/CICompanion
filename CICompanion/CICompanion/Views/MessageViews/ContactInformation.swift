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
                    CIErrorMessage(
                        errorMessage: error
                    )
                } else {
                    Text("Courses")
                        .foregroundColor(ViewHelper.textImportant)
                        .font(.system(size: ViewHelper.smallTextSize * 1.5, weight: .semibold))
                        
                    
                    if selectedStudentCourses.isEmpty {
                        CIText("No courses found", ViewHelper.text)
                    } else {
                        ForEach(selectedStudentCourses, id: \.id) { course in
                            CIDropDownCard(
                                title: course.courseName,
                                subtitle: course.location,
                                before: {
                                    if (course.startTime == "N/A") {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Async")
                                                .font(.system(size: ViewHelper.smallTextSize, weight: .regular))
                                        
                                            Text("No times")
                                                .font(.system(size: ViewHelper.smallTextSize, weight: .regular))
                                        }
                                        .foregroundColor(ViewHelper.text)
                                        .frame(width: 60, alignment: .leading)
                                    } else {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(course.startTime)
                                                .font(.system(size: ViewHelper.smallTextSize, weight: .regular))
                                            Text(course.endTime)
                                                .font(.system(size: ViewHelper.smallTextSize, weight: .regular))
                                        }
                                        .foregroundColor(ViewHelper.text)
                                        .frame(width: 60, alignment: .leading)
                                    }
                                },
                                expandedContent: {
                                    Text(course.courseDescription)
                                        .foregroundColor( ViewHelper.text)
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
            await loadContact()
        }
    }
    
    private func loadContact() async {
        isLoading = true
        loadError = nil
        selectedStudent = nil
        selectedStudentCourses = []
        
        defer {
            isLoading = false
        }
        
        do {
            let contact = try await messagingRepository.loadContact(studentId: participantId)
            let allCourses = try await courseRepository.loadAllCourses()
            
            selectedStudent = contact
            selectedStudentCourses = allCourses.filter { contact.courses.contains($0.id) }
            
        } catch {
            loadError = error.localizedDescription
        }
    }
}
