//
//  LocalCourseCatalog.swift
//  CICompanion
//

import Foundation

enum LocalCourseCatalog {
    static let resourceName = "spring_2026_courses"

    static func loadCourses(bundle: Bundle = .main) throws -> [Course] {
        let url = try catalogURL(bundle: bundle)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Course].self, from: data)
    }

    private static func catalogURL(bundle: Bundle) throws -> URL {
        if let url = bundle.url(forResource: resourceName, withExtension: "json") {
            return url
        }

        if let url = Bundle(for: BundleToken.self).url(forResource: resourceName, withExtension: "json") {
            return url
        }

        let workspaceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("CICompanion/CICompanion/\(resourceName).json")
        if FileManager.default.fileExists(atPath: workspaceURL.path) {
            return workspaceURL
        }

        throw URLError(.fileDoesNotExist)
    }
}

private final class BundleToken: NSObject {}
