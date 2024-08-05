//
//  ParkingLot.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/3/24.
//

import Foundation
import CoreLocation
import Firebase
import FirebaseFirestore

struct ParkingLot: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    var reportCount: Int
    var recentReports: [Date]

    init(id: String, name: String, latitude: Double, longitude: Double, reportCount: Int = 0) {
        self.id = id
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.reportCount = reportCount
        self.recentReports = []
    }

    init(document: DocumentSnapshot) {
        self.id = document.documentID
        let data = document.data() ?? [:]
        self.name = data["name"] as? String ?? "Unknown"
        let latitude = data["latitude"] as? Double ?? 0.0
        let longitude = data["longitude"] as? Double ?? 0.0
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.reportCount = data["reportCount"] as? Int ?? 0
        if let timestamps = data["recentReports"] as? [Timestamp] {
            self.recentReports = timestamps.map { $0.dateValue() }
        } else {
            self.recentReports = []
        }
    }
    
}
