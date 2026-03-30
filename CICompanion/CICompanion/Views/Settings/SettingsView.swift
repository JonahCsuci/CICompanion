//
//  SettingsView.swift
//  CICompanion
//
//  The Settings tab — provides class management (add/remove) and app preferences.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Dependencies
    
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    
    // MARK: - Local State
    
    @State private var showAddClass = false
    @State private var showRemoveClass = false
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                List {
                    Section {
                        Button {
                            showAddClass = true
                        } label: {
                            Label("Add Class", systemImage: "plus.circle.fill")
                        }
                        
                        Button {
                            showRemoveClass = true
                        } label: {
                            Label("Remove Class", systemImage: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text("My Classes")
                    }
                    
                    Section {
                        NavigationLink {
                            NotificationSettingsView(courses: [])
                        } label: {
                            Label("Notifications", systemImage: "bell.fill")
                        }
                    } header: {
                        Text("Preferences")
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddClass) {
                AddClassSheet(
                    courseRepository: courseRepository,
                    studentRepository: studentRepository
                )
            }
            .sheet(isPresented: $showRemoveClass) {
                RemoveClassSheet(
                    courseRepository: courseRepository,
                    studentRepository: studentRepository
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Add Class Sheet

/// Lists available courses the student can add.
private struct AddClassSheet: View {
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    @Environment(\.dismiss) private var dismiss
    
    @State private var availableCourses: [Course] = []
    @State private var isLoading = true
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if availableCourses.isEmpty {
                    Text("All courses already added")
                        .foregroundColor(.gray)
                } else {
                    List(availableCourses) { course in
                        Button {
                            Task {
                                try? await studentRepository.addStudentCourse(courseId: course.id)
                                dismiss()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(course.courseCode) - \(course.courseName)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                HStack(spacing: 8) {
                                    Text(course.instructor)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("•")
                                        .foregroundColor(.gray)
                                    Text(course.location)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(red: 0.12, green: 0.14, blue: 0.20))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            do {
                let all = try await courseRepository.loadAllCourses()
                let student = try await studentRepository.loadStudent()
                availableCourses = all.filter { !student.courses.contains($0.id) }
            } catch {
                availableCourses = []
            }
            isLoading = false
        }
    }
}

// MARK: - Remove Class Sheet

/// Lists the student's current courses for removal.
private struct RemoveClassSheet: View {
    let courseRepository: CourseRepositoryProtocol
    let studentRepository: StudentRepositoryProtocol
    @Environment(\.dismiss) private var dismiss
    
    @State private var studentCourses: [Course] = []
    @State private var isLoading = true
    
    private let bgColor = Color(red: 0.08, green: 0.10, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if studentCourses.isEmpty {
                    Text("No classes to remove")
                        .foregroundColor(.gray)
                } else {
                    List(studentCourses) { course in
                        Button {
                            Task {
                                try? await studentRepository.deleteStudentCourse(courseId: course.id)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(course.courseCode) - \(course.courseName)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(course.location)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(red: 0.12, green: 0.14, blue: 0.20))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Remove Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            do {
                studentCourses = try await courseRepository.loadStudentCourses()
            } catch {
                studentCourses = []
            }
            isLoading = false
        }
    }
}

#Preview {
    SettingsView(
        courseRepository: CourseRepository(studentRepository: StudentRepository()),
        studentRepository: StudentRepository()
    )
}
