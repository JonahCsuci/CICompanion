//
//  DateHelper.swift
//  CICompanion
//
//  Created by Emma on 3/30/26.
//

import SwiftUI

class DateHelper {
    public static func datesFromNowToThen(_ start: Date, _ end: Date) -> [Date] {
        var curr : Date = start
        var dates : [Date] = []
        
        while (curr <= end) {
            curr = Calendar.current.date(byAdding: .day, value: 1, to: curr) ?? Date.distantPast
            
            if (curr == Date.distantPast) {
                return dates
            }
            
            dates.append(curr)
        }
        
        return dates
    }
    
    public static func dateToTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        
        return formatter.string(from: date)
    }
    
    public static func timeStringToMinutes(_ timeString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        
        guard let date = formatter.date(from: timeString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        
        return hour * 60 + minute
    }
    
    public static func minutesToTimeString(_ minutesToConvert: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        
        let hours : Int = minutesToConvert / 60;
        let minutes : Int = minutesToConvert % 60;
        
        let components = DateComponents(hour: hours, minute: minutes)
        let date = Calendar.current.date(from: components)!
        
        return formatter.string(from: date)
    }
}
