//
//  FindClassroomView.swift
//  CICompanion
//
//  Created by Emma Schwartz on 5/20/26.
//

import SwiftUI
import CoreLocation
import Combine

struct FindClassroomView: View {
    @StateObject private var locationManager = ClassroomLocationManager()
    
    let classroom: ClassroomLocation
    
    init(lat: Double, long: Double)
    {
        classroom = ClassroomLocation(
            name: "Bell Tower 2505",
            latitude: lat,
            longitude: long
        )
    }
    
    var body: some View {
        CIView {
            CIHeader {
                CIPageTitle("Find Classroom")
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(ViewHelper.fieldBgColor)
                        .frame(width: 260, height: 260)
                    
                    Circle()
                        .stroke(ViewHelper.accentBlue.opacity(0.25), lineWidth: 12)
                        .frame(width: 260, height: 260)
                    
                    Circle()
                        .stroke(ViewHelper.accentBlue.opacity(0.5), lineWidth: 6)
                        .frame(width: 210, height: 210)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(ViewHelper.accentBlue)
                        .rotationEffect(
                            .degrees(
                                locationManager.rotationAngle(
                                    to: classroom.location
                                )
                            )
                        )
                        .animation(.linear(duration: 0.1), value: locationManager.heading)
                }
                
                VStack(spacing: 6) {
                    CIText(
                        classroom.buildingName,
                        color: .white,
                        fontSize: 30,
                        fontWeight: .bold
                    )
                    
                    CIText(
                        classroom.roomNumber,
                        color: ViewHelper.accentBlue,
                        fontSize: 22,
                        fontWeight: .semibold
                    )
                    
                    CIText(
                        classroom.floorText,
                        color: ViewHelper.text,
                        fontSize: 16
                    )
                }
                
                VStack(spacing: 12) {
                    if locationManager.distance(to: classroom.location) < 1 {
                        CIText(
                            "You’re here!",
                            color: ViewHelper.accentBlue,
                            fontSize: 18,
                            fontWeight: .semibold
                        )
                    } else if locationManager.distance(to: classroom.location) < 10 {
                        CIText(
                            "You’re very close!",
                            color: ViewHelper.accentBigGreen,
                            fontSize: 18,
                            fontWeight: .semibold
                        )
                    } else if locationManager.distance(to: classroom.location) < 30 {
                        CIText(
                            "You're close...",
                            color: ViewHelper.accentMeeting,
                            fontSize: 18,
                            fontWeight: .semibold
                        )
                    } else {
                        CIText("Head toward the arrow.", color: ViewHelper.text,
                            fontSize: 18
                        )
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ClassroomLocation {
    let name: String
    let latitude: Double
    let longitude: Double
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private var parts: [String] {
        name.split(separator: " ").map(String.init)
    }
    
    var roomNumber: String {
        parts.last ?? ""
    }
    
    var buildingName: String {
        parts.dropLast().joined(separator: " ")
    }
    
    var floorNumber: Int {
        Int(String(roomNumber.first ?? "1")) ?? 1
    }
    
    var floorText: String {
        switch floorNumber {
        case 1: return "First Floor"
        case 2: return "Second Floor"
        case 3: return "Third Floor"
        case 4: return "Fourth Floor"
        case 5: return "Fifth Floor"
        default: return "\(floorNumber)th Floor"
        }
    }
}

final class ClassroomLocationManager:
    NSObject,
    ObservableObject,
    CLLocationManagerDelegate
{
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var heading: Double = 0
    
    override init() {
        super.init()
        
        manager.delegate = self
        
        manager.desiredAccuracy =
            kCLLocationAccuracyBest
        
        manager.distanceFilter = kCLDistanceFilterNone
        manager.headingFilter = kCLHeadingFilterNone
        
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            
            manager.requestTemporaryFullAccuracyAuthorization(
                withPurposeKey: "ClassroomNavigation"
            )
            
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        location = locations.last
        
        if let loc = locations.last {
            print("LAT: \(loc.coordinate.latitude), LON: \(loc.coordinate.longitude), ACC: ±\(Int(loc.horizontalAccuracy))m")
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading
    ) {
        heading = newHeading.trueHeading
    }
    
    
    func distance(to target: CLLocation) -> CLLocationDistance {
        guard let location else { return .infinity }
        return location.distance(from: target)
    }
    
    func rotationAngle(to target: CLLocation) -> Double {
        guard let location else { return 0 }
        
        let lat1 = location.coordinate.latitude.radians
        let lon1 = location.coordinate.longitude.radians
        
        let lat2 = target.coordinate.latitude.radians
        let lon2 = target.coordinate.longitude.radians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        
        let x =
            cos(lat1) * sin(lat2)
            - sin(lat1)
            * cos(lat2)
            * cos(dLon)
        
        let bearing = atan2(y, x).degrees
        
        return bearing - heading + 90
    }
}

extension Double {
    var radians: Double {
        self * .pi / 180
    }
    
    var degrees: Double {
        self * 180 / .pi
    }
}
