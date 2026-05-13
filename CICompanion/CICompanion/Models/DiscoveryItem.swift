//
//  DiscoveryItem.swift
//  CICompanion
//
//  Created by Emma on 4/30/26.
//

import SwiftUI

protocol DiscoveryItem {
    var title: String { get set }
    var link: String { get set }
    var subtitle: String { get set }
    var metaInfoLn1: String { get set }
    var metaInfoLn2: String { get set }
    var metaInfoLn3: String { get set }
    var date: Date { get set }
}

struct EventDI: DiscoveryItem {
    var title: String // set
    var description: String // set
    var link: String // set
    var timeRange: TimeRange // set
    
    var subtitle: String
    var metaInfoLn1: String
    var metaInfoLn2: String
    var metaInfoLn3: String
    var date: Date
    
    init(title: String, description: String, link: String, timeRange: TimeRange) {
        self.title = title
        self.description = description
        self.link = link
        self.timeRange = timeRange
        
        self.subtitle = "EVENT"
        self.metaInfoLn1 = "\(DateHelper.dateToDayString(timeRange.day))"
        self.metaInfoLn2 = "\(DateHelper.minutesToTimeString(timeRange.startTime)) - \(DateHelper.minutesToTimeString(timeRange.endTime))"
        self.metaInfoLn3 = description
        self.date = timeRange.day
    }
}

struct NewsDI: DiscoveryItem {
    var title: String
    var description: String
    var link: String
    var author: String
    var pubDate: Date?
    var imageURL: String?
    var categories: [String]

    var subtitle: String
    var metaInfoLn1: String
    var metaInfoLn2: String
    var metaInfoLn3: String
    var date: Date

    init(
        title: String,
        description: String,
        link: String,
        author: String,
        pubDate: Date?,
        imageURL: String?,
        categories: [String]
    ) {
        self.title = title
        self.description = description
        self.link = link
        self.author = author
        self.pubDate = pubDate
        self.imageURL = imageURL
        self.categories = categories

        self.subtitle = "NEWS"
        self.metaInfoLn1 = pubDate.map { DateHelper.dateToDayString($0) } ?? ""
        self.metaInfoLn2 = "by " + author
        self.metaInfoLn3 = description
        
        self.date = pubDate ?? Date()
    }
}

struct JobDI: DiscoveryItem {
    var title: String
    var description: String
    var link: String
    var employer: String
    var expires: String
    var pubDate: Date?

    var subtitle: String
    var metaInfoLn1: String
    var metaInfoLn2: String
    var metaInfoLn3: String
    var date: Date

    init(
        title: String,
        description: String,
        link: String,
        employer: String,
        expires: String,
        pubDate: Date?
    ) {
        self.title = title
        self.description = description
        self.link = link
        self.employer = employer
        self.expires = expires
        self.pubDate = pubDate

        self.subtitle = "JOB"
        self.metaInfoLn1 = employer
        self.metaInfoLn2 = expires.isEmpty ? "No expiration listed" : "Expires \(expires)"
        self.metaInfoLn3 = description
        self.date = pubDate ?? Date()
    }
}
