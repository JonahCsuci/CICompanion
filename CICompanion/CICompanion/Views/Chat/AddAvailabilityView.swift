import SwiftUI

struct AddAvailabilityView: View {
    var timeBlockSize: Int = 60
    var days: [Date]
    var cols: [GridItem]
    var gridItems: [TimeRange]

    @State private var selectedRanges: Set<TimeRange> = []
    @State private var touchedThisDrag: Set<UUID> = []

    init(
        days: [Date],
        timeBlockSize: Int = 30,
        startTime: Int,
        endTime: Int
    ) {
        self.days = days
        self.timeBlockSize = timeBlockSize

        var tempCols: [GridItem] = []
        var tempGridItems: [TimeRange] = []

        for _ in days {
            tempCols.append(GridItem(.flexible(minimum: 100), spacing: 8))
        }

        for time in stride(from: startTime, to: endTime, by: timeBlockSize) {
            for day in days {
                tempGridItems.append(
                    TimeRange(
                        startTime: time,
                        endTime: time + timeBlockSize,
                        userID: -1,
                        day: day
                    )
                )
            }
        }

        self.cols = tempCols
        self.gridItems = tempGridItems
    }

    var body: some View {
        CIView(heading: {
            CIPageTitle("Add your availabilities")
        }) {
            ScrollView([.vertical, .horizontal]) {
                ZStack {
                    LazyVGrid(columns: cols, spacing: 4) {
                        ForEach(gridItems) { item in
                            AvailabilityCell(
                                item: item,
                                isSelected: selectedRanges.contains(item),
                                touchedThisDrag: $touchedThisDrag,
                                toggle: toggle
                            )
                        }
                    }
                }
                .padding(ViewHelper.padding * 5)
                .clipped()
            }
        }
    }

    private func toggle(_ item: TimeRange) {
        if selectedRanges.contains(item) {
            selectedRanges.remove(item)
        } else {
            selectedRanges.insert(item)
        }
    }
}

struct AvailabilityCell: View {
    let item: TimeRange
    let isSelected: Bool
    @Binding var touchedThisDrag: Set<UUID>
    let toggle: (TimeRange) -> Void

    var body: some View {
        Text("")
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        
            .cornerRadius(ViewHelper.componentRounding)
            .background(isSelected ? ViewHelper.accentBigGreen : ViewHelper.accentRed)
            .foregroundColor(.white)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !touchedThisDrag.contains(item.id) {
                            touchedThisDrag.insert(item.id)
                            toggle(item)
                        }
                    }
                    .onEnded { _ in
                        touchedThisDrag.removeAll()
                    }
            )
            .onTapGesture {
                toggle(item)
            }
    }
}

#Preview {
    AddAvailabilityView(
        days: [
            Date(),
            Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        ],
        startTime: 0,
        endTime: 1080
    )
}
