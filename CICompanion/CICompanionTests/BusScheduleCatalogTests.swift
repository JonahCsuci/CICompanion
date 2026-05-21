//
//  BusScheduleCatalogTests.swift
//  CICompanionTests
//

import XCTest
@testable import CICompanion

final class BusScheduleCatalogTests: XCTestCase {
    func testCatalogContainsPlannedRoutes() {
        let routes = BusScheduleCatalog.routes

        XCTAssertEqual(routes.map(\.title), ["HWY 101", "HWY 126", "East County"])
    }

    func testEveryRouteHasSourceAndPDFURLs() throws {
        for route in BusScheduleCatalog.routes {
            XCTAssertNotNil(URL(string: route.sourceURL), "Missing source URL for \(route.title)")
            XCTAssertNotNil(URL(string: route.pdfURL), "Missing PDF URL for \(route.title)")
            XCTAssertFalse(route.sourceURL.isEmpty)
            XCTAssertFalse(route.pdfURL.isEmpty)
        }
    }

    func testEveryDirectionHasSchedulesWithStopsAndTrips() {
        for route in BusScheduleCatalog.routes {
            XCTAssertFalse(route.directions.isEmpty, "Missing directions for \(route.title)")

            for direction in route.directions {
                XCTAssertFalse(direction.schedules.isEmpty, "Missing schedules for \(route.title) \(direction.title)")

                for schedule in direction.schedules {
                    XCTAssertFalse(schedule.stops.isEmpty, "Missing stops for \(schedule.id)")
                    XCTAssertFalse(schedule.trips.isEmpty, "Missing trips for \(schedule.id)")
                }
            }
        }
    }

    func testTripTimesAlignWithStops() {
        for route in BusScheduleCatalog.routes {
            for direction in route.directions {
                for schedule in direction.schedules {
                    for trip in schedule.trips {
                        XCTAssertEqual(
                            trip.times.count,
                            schedule.stops.count,
                            "\(route.title) \(direction.title) \(schedule.serviceDays) route \(trip.routeNumber) has \(trip.times.count) times for \(schedule.stops.count) stops"
                        )
                    }
                }
            }
        }
    }

    func testOfficialSpecialValuesArePreserved() {
        let allTimes = BusScheduleCatalog.routes
            .flatMap(\.directions)
            .flatMap(\.schedules)
            .flatMap(\.trips)
            .flatMap(\.times)

        XCTAssertTrue(allTimes.contains("FLAG"))
        XCTAssertTrue(allTimes.contains("-"))
        XCTAssertTrue(allTimes.contains("DROP"))
    }
}
