//
//  Tutors.swift
//  CICompanion
//
//  Created by Wummiez on 4/26/26.
//

import SwiftUI

struct Tutors: View {
    
    @StateObject var viewModel: TutorViewModel
    
    @State private var searchText = ""
    @State private var selectedSubject = "All"
    
    // Formats and returns tutored subjects for tab at top of view
    private var subjects: [String] {
        let tutorSubjects = viewModel.tutors.map { $0.subject }
        return ["All"] + Array(Set(tutorSubjects)).sorted()
    }
    
    private var filteredTutors: [Tutor] {
        viewModel.tutors.filter { tutor in
            let matchesSubject =
                selectedSubject == "All" ||
                tutor.subject == selectedSubject
            
            let matchesSearch =
                searchText.isEmpty ||
                tutor.name.localizedCaseInsensitiveContains(searchText) ||
                tutor.subject.localizedCaseInsensitiveContains(searchText) ||
                tutor.supportedCourses.contains {
                    $0.localizedCaseInsensitiveContains(searchText)
                }
            
            return matchesSubject && matchesSearch
        }
    }
    
    var body: some View {
        CIView {
            CIHeader {
                CIPageTitle("Tutors")
                
                CITextField(
                    placeholder: "Search tutor or course",
                    text: $searchText,
                    lines: 1
                )
                
                subjectTabs
                    .padding(.bottom, ViewHelper.padding)
            }
            
            CIScrollView {
                
                if filteredTutors.isEmpty {
                    CIText("No tutors found", color: ViewHelper.text)
                        .padding(.top, ViewHelper.padding)
                } else {
                    ForEach(filteredTutors, id: \.name) { tutor in
                        tutorRow(tutor)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadTutors()
        }
    }
    
    private var subjectTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ViewHelper.spacing) {
                ForEach(subjects, id: \.self) { subject in
                    Button {
                        selectedSubject = subject
                    } label: {
                        Text(subject)
                            .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                            .foregroundColor(selectedSubject == subject ? .white : ViewHelper.text)
                            .padding(.horizontal, ViewHelper.padding)
                            .padding(.vertical, ViewHelper.smallPadding)
                            .background(
                                RoundedRectangle(cornerRadius: ViewHelper.componentRounding)
                                    .fill(selectedSubject == subject ? ViewHelper.accentBlue : ViewHelper.fieldBgColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func tutorRow(_ tutor: Tutor) -> some View {
        CIDropDownCard(
            title: tutor.name,
            subtitle: "\(tutor.subject) • \(daysText(for: tutor))",
            expandedContent: {
                VStack(alignment: .leading, spacing: ViewHelper.spacing) {
                    CIText("Schedule", fontWeight: .bold)
                    
                    ForEach(tutor.schedule, id: \.day) { item in
                        HStack {
                            CIText(item.day, color: ViewHelper.text, fontSize: ViewHelper.metaTextSize)
                            Spacer()
                            CIText(item.time, color: ViewHelper.accentBlue, fontSize: ViewHelper.metaTextSize)
                        }
                    }
                    
                    Divider()
                        .background(ViewHelper.textImportant)
                    
                    CIText("Supported Courses", fontWeight: .bold)
                    
                    ForEach(tutor.supportedCourses, id: \.self) { course in
                        CIText("• \(course)", color: ViewHelper.text, fontSize: ViewHelper.metaTextSize)
                    }
                }
                .padding(.top, ViewHelper.padding)
            },
            color: ViewHelper.accentBlue
        )
    }
    
    private func daysText(for tutor: Tutor) -> String {
        tutor.schedule.map { $0.day }.joined(separator: ", ")
    }
}

#Preview {
    Tutors(
        viewModel: TutorViewModel(
            tutorRepository: TutorRepository()
        )
    )
}
