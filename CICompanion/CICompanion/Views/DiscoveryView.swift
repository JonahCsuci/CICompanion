//
//  DiscoveryView.swift
//  CICompanion
//
//  Created by Emma on 5/4/26.
//

import SwiftUI

enum DiscoveryMode: String, CaseIterable {
    case card = "Card View"
    case list = "List View"
}

struct DiscoveryView: View {
    @State private var selectedMode: DiscoveryMode = .list
    @State private var items: [any DiscoveryItem] = []
    @State private var isLoading = true

    @ObservedObject var tutorViewModel: TutorViewModel

    var body: some View {
        NavigationStack {
            CIView {
                CIHeader {
                    CIPageTitle("Discover")

                    DiscoveryModePicker(selectedMode: $selectedMode)
                        .padding(.bottom, ViewHelper.biggerSpacing)
                }

                if selectedMode == .card {
                    if isLoading {
                        VStack {
                            Spacer()

                            CILoadingPage()

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        DiscoveryCards(items: items, tutorViewModel: tutorViewModel)
                    }
                } else {
                    DiscoveryList(items: items, tutorViewModel: tutorViewModel)
                }
            }
        }
        .task {
            do {
                items = try await fetchRSSFeedEvent(
                    from: "https://25livepub.collegenet.com/calendars/csuci-calendar-of-events.rss"
                )
                items.append(contentsOf: try await fetchRSSFeedNews(from: "https://www.csuci.edu/news/rss.xml"))
                
                items.append(contentsOf: try await fetchRSSFeedJobs(from: "https://app.joinhandshake.com/external_feeds/17849/public.rss?token=ss6SQ8oINSf-Aj-BCHpRYrd6LWYPw4Fz01B2FwGp6A0BH93Y6VWXAQ"))
                
                let events = items
                    .filter { $0.subtitle == "EVENT" }
                    .sorted { $0.date < $1.date }

                let news = items
                    .filter { $0.subtitle == "NEWS" }
                    .sorted { $0.date > $1.date }
                
                let jobs = items
                    .filter { $0.subtitle == "JOB" }
                    .sorted { $0.date < $1.date }

                items = interweave(events: events, news: news, jobs: jobs)
            } catch {
                print(error)
            }

            isLoading = false
        }
    }
    
    func interweave(events: [any DiscoveryItem], news: [any DiscoveryItem], jobs: [any DiscoveryItem]) -> [any DiscoveryItem] {
        var result: [any DiscoveryItem] = []
        var eventIndex = 0
        var newsIndex = 0
        var jobsIndex = 0

        while eventIndex < events.count || newsIndex < news.count || jobsIndex < jobs.count {
            let option = Int.random(in: 0...2)

            if option == 0, newsIndex < news.count {
                result.append(news[newsIndex])
                newsIndex += 1
            } else if option == 1, eventIndex < events.count {
                result.append(events[eventIndex])
                eventIndex += 1
            } else if jobsIndex < jobs.count {
                result.append(jobs[jobsIndex])
                jobsIndex += 1
            } else if eventIndex < news.count {
                result.append(events[jobsIndex])
                eventIndex += 1
            } else if newsIndex < news.count {
                result.append(news[newsIndex])
                newsIndex += 1
            }
        }
         
        return result
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
    let items: [any DiscoveryItem]
    let tutorViewModel: TutorViewModel

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
            VStack(spacing: 12) {
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 12) {
                        ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                            let item = rows[rowIndex][colIndex]

                            NavigationLink {
                                DiscoveryDetailView(item: item)
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

    private var rows: [[any DiscoveryItem]] {
        stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
    }
}

struct Card: View {
    let item: any DiscoveryItem

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
    let items: [any DiscoveryItem]
    let tutorViewModel: TutorViewModel
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
                VStack {
                    ForEach(Array(items.filter({
                        if ($0.subtitle == "EVENT" && !showEvents) {return false}
                        
                        if ($0.subtitle == "NEWS" && !showNews) {return false}
                        
                        if ($0.subtitle == "JOB" && !showJobs) {return false}
                        
                        return search == "" || $0.title.lowercased().contains(search.lowercased()) || $0.metaInfoLn3.lowercased().contains(search.lowercased())
                    }).enumerated()), id: \.offset) { _, item in
                        NavigationLink {
                            DiscoveryDetailView(item: item)
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

    private var rows: [[any DiscoveryItem]] {
        stride(from: 0, to: items.count, by: 2).map {
            Array(items[$0..<min($0 + 2, items.count)])
        }
    }
}

struct ListCard: View {
    let item: any DiscoveryItem

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
    let item: any DiscoveryItem
    @Environment(\.dismiss) private var dismiss

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
                    
                    if (item is NewsDI) {
                        let news : NewsDI = item as! NewsDI
                        
                        if let imgURL = news.imageURL {
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

#Preview {
    DiscoveryView(
        tutorViewModel: TutorViewModel(
            tutorRepository: TutorRepository()
        )
    )
}
