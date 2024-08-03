//
//  ParkingLot.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/3/24.
//

import Foundation
import CoreLocation

struct ParkingLot: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    var reportCount: Int
    var recentReports: [Date] 

    init(name: String, latitude: Double, longitude: Double, reportCount: Int = 0) {
        self.id = UUID()
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.reportCount = reportCount
        self.recentReports = []
    }
}
