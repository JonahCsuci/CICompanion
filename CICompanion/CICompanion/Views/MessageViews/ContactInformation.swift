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
        VStack(alignment: .leading, spacing: 12) {
            Text("Student")
                .font(.title2)
                .bold()
            
            if let student = selectedStudent {
                Text(student.name)
                    .font(.headline)
                
                Text("ID: \(student.email)")
                    .foregroundColor(.secondary)
            } else {
                Text("ID: \(participantId)")
                    .foregroundColor(.secondary)
            }
            
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                }
                .padding(.top, 8)
                
            } else if let error = loadError {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 8)
                
            } else {
                Text("Courses")
                    .font(.headline)
                    .padding(.top, 8)
                
                if selectedStudentCourses.isEmpty {
                    Text("No courses found")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(selectedStudentCourses, id: \.id) { course in
                                Text(course.courseName)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
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
