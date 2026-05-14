//
//  DiscoveryItem.swift
//  CICompanion
//
//  Created by Emma on 4/30/26.
//

import SwiftUI

struct DiscoveryItem: Hashable {
    var title: String
    var link: String
    var subtitle: String
    var metaInfoLn1: String
    var metaInfoLn2: String
    var metaInfoLn3: String
    var date: Date
    var imageURL: String?
    var timeRange: TimeRange?
}

func EventDI(title: String, description: String, link: String, timeRange: TimeRange) -> DiscoveryItem {
    let subtitle = "EVENT"
    let metaInfoLn1 = "\(DateHelper.dateToDayString(timeRange.day))"
    let metaInfoLn2 = "\(DateHelper.minutesToTimeString(timeRange.startTime)) - \(DateHelper.minutesToTimeString(timeRange.endTime))"
    let metaInfoLn3 = description
    let date = timeRange.day
    
    return DiscoveryItem(title: title, link: link, subtitle: subtitle, metaInfoLn1: metaInfoLn1, metaInfoLn2: metaInfoLn2, metaInfoLn3: metaInfoLn3, date: date, timeRange: timeRange)
}

func NewsDI(
    title: String,
    description: String,
    link: String,
    author: String,
    pubDate: Date?,
    imageURL: String?,
    categories: [String]
) -> DiscoveryItem {
    let subtitle = "NEWS"
    let metaInfoLn1 = pubDate.map { DateHelper.dateToDayString($0) } ?? ""
    let metaInfoLn2 = "by " + author
    let metaInfoLn3 = description
    
    let date = pubDate ?? Date()
    
    return DiscoveryItem(title: title, link: link, subtitle: subtitle, metaInfoLn1: metaInfoLn1, metaInfoLn2: metaInfoLn2, metaInfoLn3: metaInfoLn3, date: date, imageURL: imageURL)
}

func JobDI(
    title: String,
    description: String,
    link: String,
    employer: String,
    expires: String,
    pubDate: Date?
) -> DiscoveryItem {
    let subtitle = "JOB"
    let metaInfoLn1 = employer
    let metaInfoLn2 = expires.isEmpty ? "No expiration listed" : "Expires \(expires)"
    let metaInfoLn3 = description
    let date = pubDate ?? Date()
    
    return DiscoveryItem(title: title, link: link, subtitle: subtitle, metaInfoLn1: metaInfoLn1, metaInfoLn2: metaInfoLn2, metaInfoLn3: metaInfoLn3, date: date)
}
