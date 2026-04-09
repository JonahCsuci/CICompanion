//
//  MeetingScheduler.swift
//  CICompanion
//
//  Created by Emma on 4/6/26.
//

import Foundation

struct MeetingScheduler: Identifiable, Codable {
    // stuff that needs to save and get loaded in database
    var availableTimeRanges : [TimeRange]
    var daysAllowed : [Date]
    var timeBlockMinutes = 60
    var id = UUID()
    var startTime: Int
    var endTime: Int
    var conversationID: Int
    
    // other stuff, don't worry about this sergio
    private var calendar: Calendar { .current }
    
    func timeRangesForDay(date: Date) -> [TimeRange] {
        return availableTimeRanges.filter {
            calendar.isDate($0.day, inSameDayAs: date)
        }
    }
    
    init(
        availableTimeRanges: [TimeRange] = [],
        daysAllowed: [Date],
        timeBlockMinutes: Int = 60,
        startTime: Int,
        endTime: Int,
        conversationID: Int
    ) {
        self.availableTimeRanges = availableTimeRanges
        self.daysAllowed = daysAllowed
        self.timeBlockMinutes = timeBlockMinutes
        self.startTime = startTime
        self.endTime = endTime
        self.conversationID = conversationID
    }
    
    func bestTimes(studyRoomTimes: [TimeRange]) -> [TimeRange] {
        var slots: [TimeRange: TimeRange] = [:]
        var peoplePerSlot: [TimeRange: Set<String>] = [:]

        for day in daysAllowed {
            for range in timeRangesForDay(date: day) {
                for i in stride(from: range.startTime, to: range.endTime, by: timeBlockMinutes) {
                    let key = TimeRange(
                        startTime: i,
                        endTime: i + timeBlockMinutes,
                        userID: "",
                        day: day
                    )

                    if slots[key] == nil {
                        slots[key] = TimeRange(
                            startTime: i,
                            endTime: i + timeBlockMinutes,
                            userID: "",
                            day: day,
                            isStudyRoomAvailable: false,
                            peopleAvailable: 0
                        )
                    }

                    peoplePerSlot[key, default: []].insert(range.userID)
                    slots[key]!.peopleAvailable = peoplePerSlot[key]!.count
                }
            }
            
            for range in studyRoomTimes {
                if !calendar.isDate(range.day, inSameDayAs: day) {
                    continue
                }

                for i in stride(from: range.startTime, to: range.endTime, by: timeBlockMinutes) {
                    let key = TimeRange(
                        startTime: i,
                        endTime: i + timeBlockMinutes,
                        userID: "",
                        day: day
                    )

                    if slots[key] == nil {
                        slots[key] = TimeRange(
                            startTime: i,
                            endTime: i + timeBlockMinutes,
                            userID: "",
                            day: day,
                            isStudyRoomAvailable: true,
                            peopleAvailable: 0
                        )
                    } else {
                        slots[key]!.isStudyRoomAvailable = true
                    }
                }
            }
        }

        let sortedSlots = slots.values.sorted {
            if calendar.isDate($0.day, inSameDayAs: $1.day) {
                return $0.startTime < $1.startTime
            }
            return $0.day < $1.day
        }

        var merged: [TimeRange] = []

        for time in sortedSlots {
            if let last = merged.last,
               calendar.isDate(last.day, inSameDayAs: time.day),
               time.startTime == last.endTime,
               time.peopleAvailable == last.peopleAvailable,
               time.isStudyRoomAvailable == last.isStudyRoomAvailable {
                merged[merged.count - 1].endTime = time.endTime
            } else {
                merged.append(time)
            }
        }

        return merged.sorted {
            if $0.peopleAvailable != $1.peopleAvailable {
                return $0.peopleAvailable > $1.peopleAvailable
            }

            if $0.isStudyRoomAvailable != $1.isStudyRoomAvailable {
                return $0.isStudyRoomAvailable && !$1.isStudyRoomAvailable
            }

            return ($0.endTime - $0.startTime) > ($1.endTime - $1.startTime)
        }
    }
}
