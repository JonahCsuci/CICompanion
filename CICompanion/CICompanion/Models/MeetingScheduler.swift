//
//  MeetingScheduler.swift
//  CICompanion
//
//  Created by Emma on 4/6/26.
//

import Foundation

struct MeetingScheduler: Identifiable, Codable {
    // stuff that needs to save and get loaded in database
    var availableTimeRanges : [TimeRange] = []
    var daysAllowed : [Date]
    var timeBlockMinutes = 60
    var id = UUID()
    var startTime: Int
    var endTime: Int
    var conversationID: Int
    var title: String
    var respondees: Set<String> = Set()
    
    // other stuff, don't worry about this sergio
    private var calendar: Calendar { .current }
    
    func timeRangesForDay(date: Date) -> [TimeRange] {
        return availableTimeRanges.filter {
            calendar.isDate($0.day, inSameDayAs: date)
        }
    }
    
    func bestTimes(studyRooms: [Int: [TimeRange]]) -> [MeetingProposal] {
        let mergedStudyRooms = mergeStudyRooms(studyRooms)
        var results: [MeetingProposal] = []

        for day in daysAllowed {
            var dayProposals: [MeetingProposal] = []

            for slotStart in stride(from: startTime, to: endTime - timeBlockMinutes + 1, by: timeBlockMinutes) {
                let slotEnd = slotStart + timeBlockMinutes

                let availablePeople = timeRangesForDay(date: day)
                    .filter { $0.startTime <= slotStart && $0.endTime >= slotEnd }
                    .reduce(into: Set<String>()) { $0.formUnion($1.peopleAvailable) }

                let matchingRoomID = mergedStudyRooms.first { _, roomTimes in
                    roomTimes
                        .filter { calendar.isDate($0.day, inSameDayAs: day) }
                        .contains { $0.startTime <= slotStart && $0.endTime >= slotEnd }
                }?.key

                if let last = dayProposals.last,
                   last.timeRange.endTime == slotStart,
                   last.timeRange.peopleAvailable == availablePeople,
                   last.studyRoomID == matchingRoomID {
                    let extended = TimeRange(
                        startTime: last.timeRange.startTime,
                        endTime: slotEnd,
                        day: day,
                        isStudyRoomAvailable: matchingRoomID != nil,
                        peopleAvailable: availablePeople
                    )
                    dayProposals[dayProposals.count - 1] = MeetingProposal(
                        timeRange: extended,
                        conversationID: conversationID,
                        title: title,
                        respondees: Set(),
                        studyRoomID: matchingRoomID
                    )
                } else {
                    dayProposals.append(MeetingProposal(
                        timeRange: TimeRange(
                            startTime: slotStart,
                            endTime: slotEnd,
                            day: day,
                            isStudyRoomAvailable: matchingRoomID != nil,
                            peopleAvailable: availablePeople
                        ),
                        conversationID: conversationID,
                        title: title,
                        respondees: Set(),
                        studyRoomID: matchingRoomID
                    ))
                }
            }

            results.append(contentsOf: dayProposals)
        }

        return results.sorted {
            let lhs = $0.timeRange
            let rhs = $1.timeRange

            if lhs.peopleAvailable.count != rhs.peopleAvailable.count {
                return lhs.peopleAvailable.count > rhs.peopleAvailable.count
            }
            if lhs.isStudyRoomAvailable != rhs.isStudyRoomAvailable {
                return lhs.isStudyRoomAvailable && !rhs.isStudyRoomAvailable
            }
            if !calendar.isDate(lhs.day, inSameDayAs: rhs.day) {
                return lhs.day < rhs.day
            }
            return lhs.startTime < rhs.startTime
        }
    }

    private func mergeStudyRooms(_ studyRooms: [Int: [TimeRange]]) -> [Int: [TimeRange]] {
        var merged: [Int: [TimeRange]] = [:]
        for (roomID, roomTimes) in studyRooms {
            var mergedTimes: [TimeRange] = []
            for roomTime in roomTimes.sorted(by: { $0.startTime < $1.startTime }) {
                if let last = mergedTimes.last, last.endTime >= roomTime.startTime {
                    mergedTimes[mergedTimes.count - 1] = TimeRange(
                        startTime: last.startTime,
                        endTime: max(last.endTime, roomTime.endTime),
                        day: last.day,
                        isStudyRoomAvailable: true,
                        peopleAvailable: last.peopleAvailable
                    )
                } else {
                    mergedTimes.append(roomTime)
                }
            }
            merged[roomID] = mergedTimes
        }
        return merged
    }
}
