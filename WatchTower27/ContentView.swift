//
//  ContentView.swift
//  WatchTower27
//
//  Created by Nikoloz Gvelesiani on 8/3/24.
//

import SwiftUI
import MapKit

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

            // Check if the user's location is out of bounds
            if !campusLatitudeRange.contains(userCoordinate.latitude) || !campusLongitudeRange.contains(userCoordinate.longitude) {
                parent.sharedState.alertMessage = "Your location is out of bounds."
                parent.sharedState.showOutOfBoundsAlert = true
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            var center = mapView.region.center

            // Constrain latitude
            if !campusLatitudeRange.contains(center.latitude) {
                center.latitude = 37.574865849768955
            }

            // Constrain longitude
            if !campusLongitudeRange.contains(center.longitude) {
                center.longitude = -77.5397224693662
            }

            // Update the region with constrained center
            let constrainedRegion = MKCoordinateRegion(
                center: center,
                span: mapView.region.span
            )

            mapView.setRegion(constrainedRegion, animated: true)
            parent.region = constrainedRegion
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            // This whole chunck literally just changes the user pin color
            if let userLocation = annotation as? MKUserLocation {
                let identifier = "UserLocation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    
                    // Customize the user location pin color
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
            
            // Check if reporting is allowed
            if parent.sharedState.isCooldownActive {
                parent.sharedState.alertMessage = "You can't report again for another 5 minutes."
                parent.sharedState.showAlert = true
                return
            }

            if parent.sharedState.isReportingDisabled {
                parent.sharedState.alertMessage = "Reporting is disabled due to out of bounds location."
                parent.sharedState.showAlert = true
                return
            }
           

            var lot = parent.parkingLots[index]
            
            // Increment the report count and add a timestamp
            lot.reportCount += 1
            lot.recentReports.append(Date())
            
            // Update the parking lot in the array
            parent.parkingLots[index] = lot
            
            // Activate cooldown
            parent.sharedState.isCooldownActive = true

            // Schedule a decrement after 5 minutes
            DispatchQueue.main.asyncAfter(deadline: .now() + 5 * 60) {
                guard let lotIndex = self.parent.parkingLots.firstIndex(where: { $0.id == lot.id }) else { return }
                self.parent.parkingLots[lotIndex].reportCount -= 1
                self.parent.parkingLots[lotIndex].recentReports.removeAll(where: { $0 <= Date().addingTimeInterval(-5 * 60) })
                
                // Deactivate cooldown
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
    
    @State private var parkingLots = [
        ParkingLot(name: "W86 - College Road Entrance", latitude: 37.575218732401666, longitude: -77.54606857558734),
        ParkingLot(name: "W85 - Behind Crenshaw Field", latitude: 37.57364987987578, longitude: -77.54502251411432),
        ParkingLot(name: "W84 - Behind Westhampton Hall", latitude: 37.57552909768003, longitude: -77.5443573263594),
        ParkingLot(name: "W93 - Behind Lora Robins", latitude: 37.5727559749692, longitude: -77.54098605686313),
        ParkingLot(name: "W73 - Between LoRo and Modlin", latitude: 37.57383165454905, longitude: -77.54173171096286),
        ParkingLot(name: "W76 - Dining Hall", latitude: 37.57450341495302, longitude: -77.54079830224387),
        ParkingLot(name: "U21 - In front of Queally Center", latitude: 37.57295155422638, longitude: -77.53943574007764),
        ParkingLot(name: "R58 - Behind THC", latitude: 37.575732125582775, longitude: -77.53811072881572),
        ParkingLot(name: "U8 - Behind Richmond Hall", latitude: 37.576293329227255, longitude: -77.53668513481405),
        ParkingLot(name: "U6 - Behind Humanities", latitude: 37.57730518571923, longitude: -77.53644373595453),
        ParkingLot(name: "The Gym", latitude: 37.58017487197686, longitude: -77.5397589462028),
        ParkingLot(name: "R43 - North of International Center", latitude: 37.5796912986631, longitude: -77.53640617660773),
        ParkingLot(name: "U3 - Behind BSchool", latitude: 37.57865396626121, longitude: -77.53468956290294),
    ]
    @StateObject private var sharedState = SharedState() // Initialize SharedState

    var body: some View {
        MapView(region: $region, parkingLots: $parkingLots)
            .environmentObject(sharedState) // Pass the environment object
            .edgesIgnoringSafeArea(.all)
            .alert(isPresented: $sharedState.showAlert) {
                Alert(title: Text("Alert"), message: Text(sharedState.alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $sharedState.showOutOfBoundsAlert) {
                Alert(
                    title: Text("Out of Bounds"),
                    message: Text(sharedState.alertMessage),
                    primaryButton: .default(Text("Ok")) {
                        // Disable reporting if user clicks "OK"
                        sharedState.isReportingDisabled = true
                    },
                    secondaryButton: .default(Text("Reporting on behalf of a friend")) {
                        sharedState.isReportingOnBehalf = true
                    }
                )
            }
    }
}

#Preview {
    ContentView()
}
