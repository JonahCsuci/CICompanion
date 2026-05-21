//
//  CampusBuilding.swift
//  CICompanion
//
//  Bounding box for the CSU Channel Islands campus. Used by `MapView`
//  to geo-lock the camera and to filter Apple POI search results to
//  the campus footprint.
//

import Foundation
import CoreLocation

/// Bounding box used to geo-lock the map camera to the CSUCI campus.
enum CampusMapBounds {
    static let center = CLLocationCoordinate2D(latitude: 34.1624, longitude: -119.0437)
    static let northLatitude: CLLocationDegrees = 34.1665
    static let southLatitude: CLLocationDegrees = 34.1580
    static let westLongitude: CLLocationDegrees = -119.0485
    static let eastLongitude: CLLocationDegrees = -119.0390
}
