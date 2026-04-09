//
//  TestView.swift
//  CICompanion
//
//  Created by Wummiez on 3/18/26.
//

import SwiftUI

struct APITestView: View {
    
    @StateObject var viewModel: APITestViewModel
    
    init(viewModel: APITestViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text(viewModel.statusMessage)
                    .padding()
                
                VStack(spacing: 12) {
                    Button("Load Courses") {
                        viewModel.testLoadCourses()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Load Student Courses") {
                        viewModel.testLoadStudentCourses()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Load Events") {
                        viewModel.testLoadEvents()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Load Student Events") {
                        viewModel.testLoadStudentEvents()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    HStack(spacing: 10) {
                        Button("Add Course 1") {
                            viewModel.testAddCourse(courseId: 1)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Add Course 2") {
                            viewModel.testAddCourse(courseId: 2)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    HStack(spacing: 10) {
                        
                        Button("Delete Course 1") {
                            viewModel.testDeleteCourse(courseId: 1)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Delete Course 2") {
                            viewModel.testDeleteCourse(courseId: 2)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    HStack(spacing: 10) {
                        
                        Button("Add Event 1") {
                            viewModel.testAddEvent(eventId: 1)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Add Event 2") {
                            viewModel.testAddEvent(eventId: 2)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    HStack(spacing: 10) {
                        
                        Button("Delete Event 1") {
                            viewModel.testDeleteEvent(eventId: 1)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Delete Event 2") {
                            viewModel.testDeleteEvent(eventId: 2)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    VStack(spacing: 10) {
                        TextField("Contact email", text: $viewModel.contactEmail)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.roundedBorder)

                        Button("Add Contact") {
                            viewModel.testAddContact()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Load Contacts") {
                            viewModel.testLoadContacts()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Contacts")
                        .font(.headline)

                    if viewModel.contacts.isEmpty {
                        Text("No contacts loaded")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.contacts) { contact in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(contact.name)
                                    Text(contact.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Button("Remove") {
                                    viewModel.testDeleteContact(contactStudentId: contact.id)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Courses")
                        .font(.headline)
                    
                    ForEach(viewModel.courses) { course in
                        Text("\(course.courseName): \(course.courseCode)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Student Courses")
                        .font(.headline)
                    
                    ForEach(viewModel.studentCourses) { course in
                        Text("\(course.courseName): \(course.courseCode)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Events")
                        .font(.headline)
                    
                    ForEach(viewModel.events) { event in
                        Text("\(event.eventTitle): \(event.eventTime)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Student Events")
                        .font(.headline)
                    
                    ForEach(viewModel.studentEvents) { event in
                        Text("\(event.eventTitle): \(event.eventTime)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
}
