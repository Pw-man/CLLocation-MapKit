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
    var userPins = [MKPointAnnotation]()
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
    
    func setupMap() {
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
    
    @objc func deletePinsTapped() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        userPins.removeAll()
        
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
    }
    
    @objc func makeRouteTapped() {
        makeComplexRoute()
    }
    
    func makeTwoPinsRoute(startPoint: MKPointAnnotation, destinationPoint: MKPointAnnotation) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark:
                                    MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: startPoint.coordinate.latitude, longitude: startPoint.coordinate.longitude))
        )
        request.destination = MKMapItem(placemark:
                                            MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinationPoint.coordinate.latitude, longitude: destinationPoint.coordinate.longitude))
        )
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            guard let response = response else {
                self.presentSimpleAlertController(title: "Не удаётся построить маршрут", message: "", actionMessage: "Попробуйте ещё раз")
                return
            }
            var shortestRoute = response.routes[0]
            for route in response.routes {
                shortestRoute = (route.distance < shortestRoute.distance) ? route : shortestRoute
            }
            self.mapView.addOverlay(shortestRoute.polyline, level: .aboveRoads)
            let rectangle = shortestRoute.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rectangle), animated: true)
        }
    }
    
    func makeComplexRoute() {
        guard userPins.count > 1 else { presentSimpleAlertController(title: "Установите хотя бы две точки маршрута", message: "", actionMessage: "Окей")
            return
        }
        for pin in 0...userPins.count - 1 {
            if pin < userPins.count - 1 {
                makeTwoPinsRoute(startPoint: userPins[pin], destinationPoint: userPins[pin + 1])
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
            
            userPins.append(annotation)
            mapView.addAnnotation(annotation)
            print("pinned: \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        setupMap()
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
        locationManager.stopUpdatingLocation()
        guard let latitude = locations.last?.coordinate.latitude, let longitude = locations.last?.coordinate.longitude else { presentSimpleAlertController(title: "Не удаётся определить локацию", message: "Пожалуйста, перезапустите приложение", actionMessage: "Ок")
            return }
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        currentLocations = locations
        mapView.setRegion(region, animated: true)
    }
}
