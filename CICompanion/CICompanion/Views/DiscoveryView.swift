//
//  DiscoveryView.swift
//  CICompanion
//
//  Created by Emma on 5/4/26.
//

import SwiftUI
internal import ClientRuntime

enum DiscoveryMode: String, CaseIterable {
    case card = "Card View"
    case list = "List View"
}

struct DiscoveryView: View {
    @State private var selectedMode: DiscoveryMode = .card
    @State var items: [DiscoveryItem]
    var studentRepository: StudentRepositoryProtocol

    @ObservedObject var tutorViewModel: TutorViewModel

    var body: some View {
        NavigationStack {
            CIView {
                CIHeader {
                    CIPageTitle("Discover")

                    DiscoveryModePicker(selectedMode: $selectedMode)
                        .padding(.bottom, ViewHelper.biggerSpacing)
                }

                
                if (items.isEmpty) {
                    VStack {
                        Spacer()
                        
                        CILoadingPage()
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if selectedMode == .card {
                    DiscoveryCards(items: items, tutorViewModel: tutorViewModel, studentRepository: studentRepository)
                } else {
                    DiscoveryList(items: items, tutorViewModel: tutorViewModel, studentRepository: studentRepository)
                }
            }
        }
    }
}

struct DiscoveryModePicker: View {
    @Binding var selectedMode: DiscoveryMode
    
    var body: some View {
        HStack(spacing: ViewHelper.spacing) {
            ForEach(DiscoveryMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: ViewHelper.textSize, weight: .semibold))
                        .foregroundColor(selectedMode == mode ? .white : ViewHelper.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMode == mode ? ViewHelper.accentBlue : ViewHelper.fieldBgColor)
                        .cornerRadius(ViewHelper.componentRounding)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DiscoveryCards: View {
    let items: [DiscoveryItem]
    let tutorViewModel: TutorViewModel
    let studentRepository: StudentRepositoryProtocol

    var body: some View {
        CIScrollView {
            CIDropDownCard(
                title: "Looking for tutors?",
                subtitle: "Instantly find tutors for any subject",
                before: {},
                expandedContent: {
                    Tutors(viewModel: tutorViewModel, showsTitle: false).padding(ViewHelper.padding)
                },
                color : ViewHelper.accentBlue,
                onOpen : {},
                bigTitle : true
            )
            LazyVStack(spacing: 12) {
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 12) {
                        ForEach(rows[rowIndex], id: \.self) { item in
                            NavigationLink {
                                DiscoveryDetailView(item: item, studentRepository: studentRepository)
                            } label: {
                                Card(item: item)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }

                        if rows[rowIndex].count == 1 {
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var rows: [[DiscoveryItem]] {
        stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
    }
}

struct Card: View {
    let item: DiscoveryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.subtitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(ViewHelper.padding)
                .background(
                    item.subtitle == "NEWS" ? ViewHelper.accentPurple :
                    item.subtitle == "JOB" ? ViewHelper.accentOrange :
                    ViewHelper.accentGreen
                )
                .cornerRadius(ViewHelper.componentRounding)

            Text(item.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(item.metaInfoLn1)
                .font(.system(size: 14))
                .foregroundColor(ViewHelper.accentBlue)
                .lineLimit(2)
            
            Text(item.metaInfoLn2)
                .font(.system(size: 14))
                .foregroundColor(ViewHelper.text)
                .lineLimit(1)
            
            Text(item.metaInfoLn3)
                .font(.system(size: 14))
                .foregroundColor(ViewHelper.text)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}

struct DiscoveryList: View {
    let items: [DiscoveryItem]
    let tutorViewModel: TutorViewModel
    let studentRepository: StudentRepositoryProtocol
    @State var search: String = ""
    @State var showEvents: Bool = true
    @State var showNews: Bool = true
    @State var showJobs: Bool = true

    var body: some View {
        VStack {
            CITextField(placeholder: "Search for events, news, or jobs", text: $search, lines: 1)
            HStack {
                Button(action: {
                    showEvents.toggle()
                }) {
                    Circle()
                        .fill((showEvents) ? ViewHelper.accentGreen : ViewHelper.text)
                        .frame(maxWidth: 6)
                    CIText("Events", color: (showEvents) ? ViewHelper.textImportant : ViewHelper.text)
                }
                .padding(ViewHelper.padding)
                .background(ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
                Button(action: {
                    showNews.toggle()
                }) {
                    Circle()
                        .fill((showNews) ? ViewHelper.accentPurple : ViewHelper.text)
                        .frame(maxWidth: 6)
                    CIText("News", color: (showNews) ? ViewHelper.textImportant : ViewHelper.text)
                }
                .padding(ViewHelper.padding)
                .background(ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
                Button(action: {
                    showJobs.toggle()
                }) {
                    Circle()
                        .fill((showJobs) ? ViewHelper.accentOrange : ViewHelper.text)
                        .frame(maxWidth: 6)
                    CIText("Jobs", color: (showJobs) ? ViewHelper.textImportant : ViewHelper.text)
                }
                .padding(ViewHelper.padding)
                .background(ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
            }
            CIScrollView {
                LazyVStack {
                    ForEach(Array(items.filter({
                        if ($0.subtitle == "EVENT" && !showEvents) {return false}
                        
                        if ($0.subtitle == "NEWS" && !showNews) {return false}
                        
                        if ($0.subtitle == "JOB" && !showJobs) {return false}
                        
                        return search == "" || $0.title.lowercased().contains(search.lowercased()) || $0.metaInfoLn3.lowercased().contains(search.lowercased())
                    }).enumerated()), id: \.offset) { _, item in
                        NavigationLink {
                            DiscoveryDetailView(item: item, studentRepository: studentRepository)
                        } label: {
                            ListCard(item: item)
                        }
                    }
                    HStack{
                        Spacer()
                    }
                }
            }
            .padding(ViewHelper.padding)
            .background(ViewHelper.cardBgColor)
            .cornerRadius(ViewHelper.componentRounding)
        }
    }

    private var rows: [[DiscoveryItem]] {
        stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
    }
}

struct ListCard: View {
    let item: DiscoveryItem

    var body: some View {
        HStack {
            Rectangle().fill(
                item.subtitle == "NEWS" ? ViewHelper.accentPurple :
                item.subtitle == "JOB" ? ViewHelper.accentOrange :
                ViewHelper.accentGreen
            )
                .frame(maxWidth: 6)
                    
                    .cornerRadius(ViewHelper.componentRounding)
            
            .padding(ViewHelper.padding)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(item.subtitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(
                            item.subtitle == "NEWS" ? ViewHelper.accentPurple :
                            item.subtitle == "JOB" ? ViewHelper.accentOrange :
                            ViewHelper.accentGreen
                        )
                    
                    Spacer()
                }
                
                Text(item.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.metaInfoLn1)
                    .font(.system(size: 14))
                    .foregroundColor(ViewHelper.accentBlue)
                    .lineLimit(1)
                
                Text(item.metaInfoLn2)
                    .font(.system(size: 14))
                    .foregroundColor(ViewHelper.text)
                    .lineLimit(1)
                
                Text(item.metaInfoLn3)
                    .font(.system(size: 14))
                    .foregroundColor(ViewHelper.text)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}

struct DiscoveryDetailView: View {
    let item: DiscoveryItem
    @Environment(\.dismiss) private var dismiss
    let studentRepository: StudentRepositoryProtocol
    
    @State private var hasEvent: Bool = false
    var event : Event?
    
    init(item: DiscoveryItem, studentRepository: StudentRepositoryProtocol) {
        self.item = item
        self.studentRepository = studentRepository

        if (item.timeRange != nil) {
            self.event = Event(name: item.title, description: item.metaInfoLn3.substringAfter("\n"), location: item.metaInfoLn3.substringBefore("\n"), timeRange: item.timeRange!)
        }
    }

    var body: some View {
        ZStack {
            ViewHelper.bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: ViewHelper.biggerSpacing) {
                    Text(item.subtitle)
                        .font(.system(size: ViewHelper.metaTextSize, weight: .bold))
                        .foregroundColor(ViewHelper.accentBlue)

                    Text(item.title)
                        .font(.system(size: ViewHelper.titleTextSize, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if (item.subtitle == "NEWS") {
                        if let imgURL = item.imageURL {
                            AsyncImage(url: URL(string: imgURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                    } placeholder: {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    }
                        }
                    }

                    Text(item.metaInfoLn1)
                        .font(.system(size: ViewHelper.textSize))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(item.metaInfoLn2)
                        .font(.system(size: ViewHelper.textSize))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(item.metaInfoLn3)
                        .font(.system(size: ViewHelper.textSize))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if (event != nil) {
                        if (hasEvent) {
                            Button {
                                Task {
                                    do {
                                        try await studentRepository.deleteStudentEvent(event: event!)
                                    } catch {
                                        
                                    }
                                }
                                
                                hasEvent = !hasEvent
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash").font(.system(size: ViewHelper.textSize, weight: .bold))
                                        .foregroundColor(ViewHelper.textImportant)
                                    CIText("Remove event from calendar", fontWeight: .bold)
                                    Spacer()
                                }
                            }
                            .padding(ViewHelper.padding)
                            .background(ViewHelper.accentRed)
                            .cornerRadius(ViewHelper.componentRounding)
                        } else {
                            Button {
                                Task {
                                    do {
                                        try await studentRepository.addStudentEvent(event: event!)
                                    } catch {
                                        
                                    }
                                }
                                
                                hasEvent = !hasEvent
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus").font(.system(size: ViewHelper.textSize, weight: .bold))
                                        .foregroundColor(ViewHelper.textImportant)
                                    CIText("Add event to calendar", fontWeight: .bold)
                                    Spacer()
                                }
                            }
                            .padding(ViewHelper.padding)
                            .background(ViewHelper.accentBlue)
                            .cornerRadius(ViewHelper.componentRounding)
                        }
                    }
                    
                    Link(destination: URL(string: item.link)!) {
                        HStack {
                            Spacer()
                            Image(systemName: "link").font(.system(size: ViewHelper.textSize, weight: .bold))
                                .foregroundColor(ViewHelper.textImportant)
                            CIText("Learn More", fontWeight: .bold)
                            Spacer()
                        }
                    }
                    .padding(ViewHelper.padding)
                    .background(ViewHelper.accentBlue)
                    .cornerRadius(ViewHelper.componentRounding)
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .foregroundColor(ViewHelper.accentBlue)
                }
            }
        }
        .task {
            do {
                if (event != nil) {
                    hasEvent = try await studentRepository.hasStudentEvent(event: event!)
                }
            } catch {
                
            }
        }
    }
}

func shortDate(_ raw: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"

    guard let date = formatter.date(from: raw) else {
        return raw
    }

    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

