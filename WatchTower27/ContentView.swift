//
//  ContentView.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/3/24.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore


// Enum to define different alert types
enum AlertType: Identifiable {
    case general(String)
    case outOfBounds(String)
    
    var id: String {
        switch self {
        case .general(let message):
            return message
        case .outOfBounds(let message):
            return message
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var parkingLots: [ParkingLot]
    @EnvironmentObject var sharedState: SharedState
    // Campus center coordinates: latitude: 37.574865849768955, longitude: -77.5397224693662)
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        let annotations = parkingLots.map { lot -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = lot.coordinate
            annotation.title = lot.name
            return annotation
        }
        uiView.addAnnotations(annotations)
        uiView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        let campusLatitudeRange = 37.56967094514907...37.58208122121385
        let campusLongitudeRange = -77.54736958443043...(-77.53533183110247)
        let locationManager = CLLocationManager()
        
        init(_ parent: MapView) {
            self.parent = parent
            super.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            let userCoordinate = location.coordinate
            
            if !campusLatitudeRange.contains(userCoordinate.latitude) || !campusLongitudeRange.contains(userCoordinate.longitude) {
                parent.sharedState.alertType = .outOfBounds("Your location is out of bounds")
                parent.sharedState.showOutOfBoundsAlert = true
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            var center = mapView.region.center
            
            if !campusLatitudeRange.contains(center.latitude) {
                center.latitude = 37.574865849768955
            }
            
            if !campusLongitudeRange.contains(center.longitude) {
                center.longitude = -77.5397224693662
            }
            
            let constrainedRegion = MKCoordinateRegion(
                center: center,
                span: mapView.region.span
            )
            
            mapView.setRegion(constrainedRegion, animated: true)
            parent.region = constrainedRegion
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let userLocation = annotation as? MKUserLocation {
                let identifier = "UserLocation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.markerTintColor = .systemPurple
                } else {
                    annotationView?.annotation = annotation
                }
                return annotationView
            }
            
            let identifier = "ParkingLot"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }
            
            if let title = annotation.title ?? "", let lot = parent.parkingLots.first(where: { $0.name == title }) {
                switch lot.reportCount {
                case 0:
                    annotationView?.markerTintColor = .green
                case 1...3:
                    annotationView?.markerTintColor = .yellow
                case 4...6:
                    annotationView?.markerTintColor = .orange
                default:
                    annotationView?.markerTintColor = .red
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation,
                  let title = annotation.title ?? "",
                  let index = parent.parkingLots.firstIndex(where: { $0.name == title }) else { return }
            
            if parent.sharedState.isCooldownActive {
                parent.sharedState.alertType = .general("Each user can report once every 5 minutes")
                parent.sharedState.showAlert = true
                return
            }
            
            if parent.sharedState.isReportingDisabled {
                parent.sharedState.alertType = .general("You can't ping a sighting if off campus")
                parent.sharedState.showAlert = true
                return
            }
            
            var lot = parent.parkingLots[index]
            let timestamp = Date()
            
            lot.reportCount += 1
            lot.recentReports.append(timestamp)

            parent.parkingLots[index] = lot
            
            parent.sharedState.isCooldownActive = true
            
            let db = Firestore.firestore()
            let lotRef = db.collection("parkingLots").document(lot.id)
            lotRef.updateData([
                "reportCount": lot.reportCount,
                "recentReports": FieldValue.arrayUnion([timestamp])
            ]) { error in
                if let error = error {
                    print("Error updating report count: \(error)")
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5 * 60) {
                guard let lotIndex = self.parent.parkingLots.firstIndex(where: { $0.id == lot.id }) else { return }
                self.parent.parkingLots[lotIndex].reportCount -= 1
                self.parent.parkingLots[lotIndex].recentReports.removeAll(where: { $0 <= Date().addingTimeInterval(-5 * 60) })
                
                db.collection("parkingLots").document(lot.id).updateData([
                    "reportCount": self.parent.parkingLots[lotIndex].reportCount
                ]) { error in
                    if let error = error {
                        print("Error updating report count: \(error)")
                    }
                }
                
                self.parent.sharedState.isCooldownActive = false
            }
        }
    }
}

// Main ContentView
struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.574865849768955, longitude: -77.5397224693662),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var parkingLots: [ParkingLot] = []
    @StateObject private var sharedState = SharedState()

    var body: some View {
        MapView(region: $region, parkingLots: $parkingLots)
            .environmentObject(sharedState)
            .edgesIgnoringSafeArea(.all)
            .alert(item: $sharedState.alertType) { alertType in
                switch alertType {
                case .general(let message):
                    return Alert(title: Text("Alert"), message: Text(message), dismissButton: .default(Text("OK")))
                case .outOfBounds(let message):
                    return Alert(
                        title: Text("Out of Bounds"),
                        message: Text(message),
                        primaryButton: .default(Text("Ok")) {
                            sharedState.isReportingDisabled = true
                        },
                        secondaryButton: .default(Text("Reporting on behalf of a friend")) {
                            sharedState.isReportingOnBehalf = true
                        }
                    )
                }
            }
            .onAppear {
                fetchParkingLots()
            }
    }

    private func fetchParkingLots() {
        let db = Firestore.firestore()
        db.collection("parkingLots").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching parking lots: \(error)")
                return
            }

            parkingLots = snapshot?.documents.map { ParkingLot(document: $0) } ?? []
        }
    }
}

//
//#Preview {
//    ContentView()
//}
