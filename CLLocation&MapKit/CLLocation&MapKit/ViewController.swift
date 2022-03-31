//
//  ViewController.swift
//  CLLocation&MapKit
//
//  Created by Роман on 31.03.2022.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var currentLocations: [CLLocation] = []
    var currentPin: MKPointAnnotation?
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var makeRouteButton: UIButton!
    @IBOutlet var deletePinsButton: UIButton!
    
    func setupButtons() {
        makeRouteButton.backgroundColor = .white
        deletePinsButton.backgroundColor = .white
        makeRouteButton.layer.cornerRadius = 5
        makeRouteButton.layer.masksToBounds = true
        deletePinsButton.layer.cornerRadius = 5
        deletePinsButton.layer.masksToBounds = true
        deletePinsButton.addTarget(self, action: #selector(deletePinsTapped), for: .touchUpInside)
        makeRouteButton.addTarget(self, action: #selector(makeRouteTapped), for: .touchUpInside)
    }
    
    @objc func deletePinsTapped() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    @objc func makeRouteTapped() {
        makeRoute()
    }
    
    func makeRoute() {
        guard let currentPin = currentPin else { print("No pins added")
            return
        }
        guard let latitude = currentLocations.last?.coordinate.latitude, let longitude = currentLocations.last?.coordinate.longitude else { print("No locations determined")
            return
        }
        if !currentLocations.isEmpty {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark:
                                        MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            )
            request.destination = MKMapItem(placemark:
                                                MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentPin.coordinate.latitude, longitude: currentPin.coordinate.longitude))
            )
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let response = response else {
                    print(error?.localizedDescription, error.debugDescription)
                    return
                }
                let route = response.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                let rectangle = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rectangle), animated: true)
            }
        }
    }
    
    @objc func pinLocation(gestureRecogniser: UILongPressGestureRecognizer) {
        if gestureRecogniser.state == .began {
            let touchPoint = gestureRecogniser.location(in: mapView)
            let touchCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinates
            annotation.title = "Сюда"
            annotation.subtitle = "Новая точка на карте"
            
            currentPin = annotation
            mapView.addAnnotation(annotation)
            print("pinned: \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        locationManager.delegate = self
        mapView.delegate = self
        mapView.showsCompass = true
        mapView.showsTraffic = true
        mapView.showsBuildings = true
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinLocation(gestureRecogniser:)))
        gestureRecognizer.minimumPressDuration = 1.2
        mapView.addGestureRecognizer(gestureRecognizer)
    }
}

//MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 4
        renderer.strokeColor = .systemBlue
        return renderer
    }
}

//MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latitude = locations.last?.coordinate.latitude, let longitude = locations.last?.coordinate.longitude else { print("No locations determined")
            return }
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        currentLocations = locations
        mapView.setRegion(region, animated: true)
    }
}
