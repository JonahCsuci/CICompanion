//
//  RSSFeedService.swift
//  CICompanion
//
//  Created by Wummiez on 5/5/26.
//

import Foundation

func fetchRSSFeed(from urlString: String) async throws -> [EventDI] {
    guard let url = URL(string: urlString) else {
        return []
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    guard let xml = String(data: data, encoding: .utf8) else {
        return []
    }

    let blocks = xml.components(separatedBy: "<item>").dropFirst()

    return blocks.map { block in
        EventDI(
            title: cleanRSS(
                extractTag("title", from: block)),
            subtitle: cleanRSS(
                extractTag("category", from: block)),
            metaInfoLn1: cleanRSS(
                extractTag("content:encoded", from: block)),
            metaInfoLn2: cleanRSS(
                extractTag("pubDate", from: block))
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

func cleanRSS(_ text: String) -> String {
    text
        .replacingOccurrences(of: "<![CDATA[", with: "")
        .replacingOccurrences(of: "]]>", with: "")
        .replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
