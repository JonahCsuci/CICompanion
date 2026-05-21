//
//  BusScheduleView.swift
//  CICompanion
//

import SwiftUI

struct BusScheduleView: View {
    private let routes = BusScheduleCatalog.routes

    @State private var routeIndex = 0
    @State private var directionIndex = 0
    @State private var serviceIndex = 0
    @State private var expandedTripIndex: Int?
    @Environment(\.dismiss) private var dismiss

    private var route: BusRouteSchedule { routes[routeIndex] }
    private var direction: BusScheduleDirection { route.directions[directionIndex] }
    private var schedule: BusServiceSchedule { direction.schedules[serviceIndex] }
    private var accent: Color { routeAccent(for: route.id) }

    var body: some View {
        CIView {
            CIHeader {
                HStack(spacing: ViewHelper.spacing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: ViewHelper.navIconSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)
                            .frame(width: ViewHelper.navButtonSize, height: ViewHelper.navButtonSize)
                            .background(Circle().fill(ViewHelper.fieldBgColor))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")

                    CIPageTitle("Bus Schedule")

                    Spacer()
                }

                routePicker
                directionPicker
                servicePicker
                    .padding(.bottom, ViewHelper.spacing)
            }

            CIScrollView {
                sourceCard

                LazyVStack(spacing: 12) {
                    ForEach(Array(schedule.trips.enumerated()), id: \.offset) { index, trip in
                        BusTripCard(
                            trip: trip,
                            stops: schedule.stops,
                            accent: accent,
                            isExpanded: expandedTripIndex == index
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedTripIndex = expandedTripIndex == index ? nil : index
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var routePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ViewHelper.spacing) {
                ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
                    selectorButton(
                        title: route.title,
                        isSelected: routeIndex == index,
                        color: routeAccent(for: route.id)
                    ) {
                        routeIndex = index
                        directionIndex = 0
                        serviceIndex = 0
                        expandedTripIndex = nil
                    }
                }
            }
        }
    }

    private var directionPicker: some View {
        HStack(spacing: ViewHelper.spacing) {
            ForEach(Array(route.directions.enumerated()), id: \.element.id) { index, direction in
                selectorButton(
                    title: direction.title,
                    isSelected: directionIndex == index,
                    color: accent
                ) {
                    directionIndex = index
                    serviceIndex = 0
                    expandedTripIndex = nil
                }
            }
        }
    }

    private var servicePicker: some View {
        HStack(spacing: ViewHelper.spacing) {
            ForEach(Array(direction.schedules.enumerated()), id: \.element.id) { index, schedule in
                selectorButton(
                    title: schedule.serviceDays,
                    isSelected: serviceIndex == index,
                    color: accent
                ) {
                    serviceIndex = index
                    expandedTripIndex = nil
                }
            }
        }
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: ViewHelper.spacing) {
            HStack(spacing: ViewHelper.spacing) {
                Image(systemName: "bus.fill")
                    .font(.system(size: ViewHelper.bigIconSize, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(width: ViewHelper.navButtonSize, height: ViewHelper.navButtonSize)
                    .background(Circle().fill(accent.opacity(ViewHelper.opacity)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(route.title)
                        .font(.system(size: ViewHelper.textSize, weight: .bold))
                        .foregroundColor(ViewHelper.textImportant)

                    Text("\(route.subtitle) - \(direction.title) - \(schedule.serviceDays)")
                        .font(.system(size: ViewHelper.smallTextSize))
                        .foregroundColor(ViewHelper.text)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: ViewHelper.spacing) {
                if let pdfURL = URL(string: route.pdfURL) {
                    Link(destination: pdfURL) {
                        sourceButtonLabel("Official PDF", icon: "doc.text.fill")
                    }
                }

                if let sourceURL = URL(string: route.sourceURL) {
                    Link(destination: sourceURL) {
                        sourceButtonLabel("VCTC Page", icon: "link")
                    }
                }
            }
        }
        .padding(ViewHelper.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }

    private func sourceButtonLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: ViewHelper.spacing) {
            Image(systemName: icon)
                .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
            Text(title)
                .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
        }
        .foregroundColor(ViewHelper.textImportant)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ViewHelper.cardBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }

    private func selectorButton(
        title: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: ViewHelper.smallTextSize, weight: .semibold))
                .foregroundColor(isSelected ? ViewHelper.textImportant : ViewHelper.text)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(isSelected ? color : ViewHelper.fieldBgColor)
                .cornerRadius(ViewHelper.componentRounding)
        }
        .buttonStyle(.plain)
    }

    private func routeAccent(for routeId: String) -> Color {
        switch routeId {
        case "hwy-101":
            return ViewHelper.accentOrange
        case "hwy-126":
            return ViewHelper.accentRed
        case "east-county":
            return ViewHelper.accentPurple
        default:
            return ViewHelper.accentBlue
        }
    }
}

private struct BusTripCard: View {
    let trip: BusTrip
    let stops: [String]
    let accent: Color
    let isExpanded: Bool
    let onToggle: () -> Void

    private var startTime: String { trip.times.first ?? "-" }
    private var endTime: String { trip.times.last ?? "-" }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .center, spacing: ViewHelper.spacing) {
                    RoundedRectangle(cornerRadius: ViewHelper.componentRounding / 4)
                        .fill(accent)
                        .frame(width: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route \(trip.routeNumber)")
                            .font(.system(size: ViewHelper.textSize, weight: .bold))
                            .foregroundColor(ViewHelper.textImportant)

                        Text("\(startTime) to \(endTime)")
                            .font(.system(size: ViewHelper.smallTextSize))
                            .foregroundColor(ViewHelper.text)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: ViewHelper.iconSize, weight: .semibold))
                        .foregroundColor(ViewHelper.text)
                }
                .padding(ViewHelper.padding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .overlay(ViewHelper.text.opacity(0.25))

                VStack(spacing: 0) {
                    ForEach(Array(zip(stops, trip.times).enumerated()), id: \.offset) { _, item in
                        BusStopTimeRow(stop: item.0, time: item.1, accent: accent)
                    }
                }
                .padding(.horizontal, ViewHelper.padding)
                .padding(.bottom, ViewHelper.smallPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ViewHelper.fieldBgColor)
        .cornerRadius(ViewHelper.componentRounding)
    }
}

private struct BusStopTimeRow: View {
    let stop: String
    let time: String
    let accent: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: ViewHelper.spacing) {
            Text(time)
                .font(.system(size: ViewHelper.smallTextSize, weight: .bold))
                .foregroundColor(timeColor)
                .frame(width: 58, alignment: .leading)

            Text(stop)
                .font(.system(size: ViewHelper.smallTextSize))
                .foregroundColor(ViewHelper.textImportant)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, ViewHelper.smallPadding)
    }

    private var timeColor: Color {
        switch time {
        case "-", "DROP":
            return ViewHelper.text
        case "FLAG":
            return accent
        default:
            return ViewHelper.accentBlue
        }
    }
}
