//
//  DiscoveryView.swift
//  CICompanion
//
//  Created by Emma on 5/4/26.
//

import SwiftUI

enum DiscoveryMode: String, CaseIterable {
    case news = "Feed"
    case tutoring = "Tutoring"
}

struct DiscoveryView: View {
    @State private var selectedMode: DiscoveryMode = .news
    @State private var items: [EventDI] = []
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

                if selectedMode == .news {
                    if isLoading {
                        VStack {
                            Spacer()

                            CILoadingPage()

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        DiscoveryNewsList(items: items)
                    }
                } else {
                    Tutors(viewModel: tutorViewModel, showsTitle: false)
                }
            }
        }
        .task {
            do {
                items = try await fetchRSSFeed(
                    from: "https://civiewnews.com/feed/"
                )
            } catch {
                print(error)
            }

            isLoading = false
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

struct DiscoveryNewsList<Item: DiscoveryItem>: View {
    let items: [Item]

    var body: some View {
        CIScrollView {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                NavigationLink {
                    DiscoveryDetailView(item: item)
                } label: {
                    NewsCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct NewsCard<Item: DiscoveryItem>: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.subtitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ViewHelper.accentBlue)

                Spacer()

                Text(shortDate(item.metaInfoLn2))
                    .font(.system(size: 11))
                    .foregroundColor(ViewHelper.text)
            }

            Text(item.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}

struct DiscoveryDetailView<Item: DiscoveryItem>: View {
    let item: Item
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

                    Text(shortDate(item.metaInfoLn2))
                        .font(.system(size: ViewHelper.metaTextSize))
                        .foregroundColor(ViewHelper.text)

                    Text(item.metaInfoLn1)
                        .font(.system(size: ViewHelper.textSize))
                        .foregroundColor(ViewHelper.textImportant)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
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
