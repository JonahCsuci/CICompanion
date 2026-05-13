//
//  RSSFeedService.swift
//  CICompanion
//
//  Created by Wummiez on 5/5/26.
//

import Foundation

func fetchRSSFeedEvent(from urlString: String) async throws -> [DiscoveryItem] {
    guard let url = URL(string: urlString) else {
        return []
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let xml = String(data: data, encoding: .utf8) else {
        return []
    }

    let blocks = xml.components(separatedBy: "<item>").dropFirst()

    return blocks.map { block in
        makeEventDI(
            title: cleanRSS(extractTag("title", from: block)),
            description: cleanRSS(extractTag("description", from: block)),
            link: cleanRSS(extractTag("link", from: block))
        )
    }
}

func fetchRSSFeedNews(from urlString: String) async throws -> [DiscoveryItem] {
    guard let url = URL(string: urlString) else {
        return []
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let xml = String(data: data, encoding: .utf8) else {
        return []
    }

    let blocks = xml.components(separatedBy: "<item>").dropFirst()

    return blocks.map { block in
        makeNewsDI(
            title: cleanRSS(extractTag("title", from: block)),
            description: cleanRSS(extractTag("description", from: block)),
            link: cleanRSS(extractTag("link", from: block)),
            author: cleanRSS(extractTag("author", from: block)),
            pubDate: parseRSSPubDate(cleanRSS(extractTag("pubDate", from: block))),
            imageURL: extractMediaContentURL(from: block),
            categories: extractTags("category", from: block).map(cleanRSS)
        )
    }
}

func fetchRSSFeedJobs(from urlString: String) async throws -> [DiscoveryItem] {
    guard let url = URL(string: urlString) else {
        return []
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let xml = String(data: data, encoding: .utf8) else {
        return []
    }

    let blocks = xml.components(separatedBy: "<item>").dropFirst()

    return blocks.map { block in
        let description = cleanRSS(extractTag("description", from: block))

        return makeJobDI(
            title: cleanRSS(extractTag("title", from: block)),
            description: description,
            link: cleanRSS(extractTag("link", from: block)),
            employer: extractJobField("Employer:", from: description),
            expires: extractJobField("Expires:", from: description),
            pubDate: parseRSSPubDate(cleanRSS(extractTag("pubDate", from: block)))
        )
    }
}

func extractTag(_ tag: String, from text: String) -> String {
    guard
        let start = text.range(of: "<\(tag)>"),
        let end = text.range(of: "</\(tag)>")
    else {
        return ""
    }

    return String(text[start.upperBound..<end.lowerBound])
}

func extractTags(_ tag: String, from text: String) -> [String] {
    let pattern = "<\(tag)>(.*?)</\(tag)>"

    guard let regex = try? NSRegularExpression(
        pattern: pattern,
        options: [.dotMatchesLineSeparators]
    ) else {
        return []
    }

    let range = NSRange(text.startIndex..<text.endIndex, in: text)

    return regex.matches(in: text, range: range).compactMap {
        guard let matchRange = Range($0.range(at: 1), in: text) else {
            return nil
        }

        return String(text[matchRange])
    }
}

func extractMediaContentURL(from text: String) -> String? {
    let pattern = #"<media:content\s+url="([^"]+)""#

    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return nil
    }

    let range = NSRange(text.startIndex..<text.endIndex, in: text)

    guard
        let match = regex.firstMatch(in: text, range: range),
        let matchRange = Range(match.range(at: 1), in: text)
    else {
        return nil
    }

    return cleanRSS(String(text[matchRange]))
}

func extractJobField(_ label: String, from text: String) -> String {
    guard let start = text.range(of: label) else {
        return ""
    }

    let afterLabel = text[start.upperBound...]
    let stopLabels = ["Employer:", "Expires:", "Hours/Week:", "Purpose of Position:", "Job Responsibilities:", "Required Knowledge"]

    let end = stopLabels
        .compactMap { afterLabel.range(of: $0)?.lowerBound }
        .filter { $0 != afterLabel.startIndex }
        .min()

    let value = end.map {
        String(afterLabel[..<$0])
    } ?? String(afterLabel)

    return value.trimmingCharacters(in: .whitespacesAndNewlines)
}

func cleanRSS(_ text: String) -> String {
    var result = text

    for _ in 0..<3 {
        let old = result

        result = result
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#160;", with: " ")
            .replacingOccurrences(of: "&ndash;", with: "-")
            .replacingOccurrences(of: "&#8211;", with: "-")
            .replacingOccurrences(of: "&mdash;", with: "-")
            .replacingOccurrences(of: "&#8212;", with: "-")
            .replacingOccurrences(of: "&#8230;", with: "...")
            .replacingOccurrences(of: "&amp;", with: "&")

        if result == old {
            break
        }
    }

    return result
        .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        .replacingOccurrences(of: "<[^>]*>?", with: "", options: .regularExpression)
        .replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        .replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func makeEventDI(title: String, description: String, link: String) -> EventDI {
    let lines = description
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    let dateAndTime = lines.indices.contains(1) ? lines[1] : ""

    let timeRange = parseTimeRange(dateAndTime) ?? TimeRange(
        startTime: 0,
        endTime: 0,
        day: Date()
    )

    return EventDI(
        title: title,
        description: description,
        link: link,
        timeRange: timeRange
    )
}

func makeNewsDI(
    title: String,
    description: String,
    link: String,
    author: String,
    pubDate: Date?,
    imageURL: String?,
    categories: [String]
) -> NewsDI {
    NewsDI(
        title: title,
        description: description,
        link: link,
        author: author,
        pubDate: pubDate,
        imageURL: imageURL,
        categories: categories
    )
}

func makeJobDI(
    title: String,
    description: String,
    link: String,
    employer: String,
    expires: String,
    pubDate: Date?
) -> JobDI {
    JobDI(
        title: title,
        description: description,
        link: link,
        employer: employer,
        expires: expires,
        pubDate: pubDate
    )
}

func parseTimeRange(_ text: String) -> TimeRange? {
    let cleaned = text
        .replacingOccurrences(of: "–", with: "-")
        .replacingOccurrences(of: "—", with: "-")
        .replacingOccurrences(of: "&ndash;", with: "-")
        .replacingOccurrences(of: "&mdash;", with: "-")
        .replacingOccurrences(of: "&nbsp;", with: " ")

    let parts = cleaned.components(separatedBy: ", ")
    guard parts.count >= 3 else {
        return nil
    }

    let dateText = "\(parts[1]), \(parts[2])"

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM d, yyyy"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    guard let day = dateFormatter.date(from: dateText) else {
        return nil
    }

    guard let timeText = parts.last else {
        return nil
    }

    var times = timeText
        .components(separatedBy: "-")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    guard times.count == 2 else {
        return nil
    }

    let endSuffix = times[1].lowercased().contains("pm") ? "pm" :
        times[1].lowercased().contains("am") ? "am" : ""

    if !times[0].lowercased().contains("am"),
       !times[0].lowercased().contains("pm"),
       !endSuffix.isEmpty {
        times[0] += endSuffix
    }

    guard
        let start = minutesSinceMidnight(times[0]),
        let end = minutesSinceMidnight(times[1])
    else {
        return nil
    }

    return TimeRange(
        startTime: start,
        endTime: end,
        day: day
    )
}

func minutesSinceMidnight(_ text: String) -> Int? {
    let cleaned = text
        .lowercased()
        .replacingOccurrences(of: " ", with: "")

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")

    for format in ["ha", "h:mma"] {
        formatter.dateFormat = format

        if let date = formatter.date(from: cleaned) {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    return nil
}

func parseRSSPubDate(_ text: String) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
    return formatter.date(from: text)
}
