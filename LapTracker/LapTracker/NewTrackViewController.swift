//
//  NewTrackViewController.swift
//  LapTracker
//
//  Created by Jack Boyce on 1/30/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import HealthKit

class NewTrackViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var map: MKMapView!
    var seconds = 0.0
    var distance = 0.0
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = .other
        
        // Movement threshold for new events
        _locationManager.distanceFilter = 10.0
        return _locationManager
    }()
    
    lazy var locations = [CLLocation]()
    lazy var timer = Timer()
    let regionRadius: CLLocationDistance = 1000
    let pollRate = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    func timeUpdate(timer: Timer) {
        seconds += pollRate
        let secondsQuantity = HKQuantity(unit: HKUnit.second(), doubleValue: seconds)
        tempLabel.text = "Time: " + secondsQuantity.description
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
        tempLabel.text = tempLabel.text! + "\nDistance: " + distanceQuantity.description
        
        let paceUnit = HKUnit.second().unitDivided(by: HKUnit.meter())
        let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: seconds / distance)
        tempLabel.text = tempLabel.text! + "\nPace: " + paceQuantity.description
        
        //loadMap()
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        map.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
                //update distance
                if self.locations.count > 0 {
                    distance += location.distance(from: self.locations.last!)
                    
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(self.locations.last!.coordinate)
                    coords.append(location.coordinate)
                    
                    let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
                    map.setRegion(region, animated: true)
                    
                    map.add(MKPolyline(coordinates: &coords, count: coords.count))
                }
                
                //save location
                self.locations.append(location)
            }
        }
    }
    
    func startLocationUpdates() {
        // Here, the location manager will be lazily instantiated
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func record(_ sender: Any) {
        seconds = 0.0
        distance = 0.0
        locations.removeAll(keepingCapacity: false)
        timer = Timer.scheduledTimer(timeInterval: pollRate, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
        startLocationUpdates()
    }
    
    @IBAction func stop(_ sender: Any) {
        timer.invalidate()
        tempLabel.text = ""
        loadMap()
        /*for location in locations {
            print(location.coordinate.latitude)
            print(location.coordinate.longitude)
        }*/
        /*
        ServerCommands.addTrackWithLocations(name: "apptest5", locations: locations) { resp in
            print("sent all locations")
        }*/
    }
    
    func mapRegion() -> MKCoordinateRegion {
        
        var minLat = locations[0].coordinate.latitude
        var minLng = locations[0].coordinate.longitude
        var maxLat = minLat
        var maxLng = minLng
        
        for location in locations {
            minLat = min(minLat, location.coordinate.latitude)
            minLng = min(minLng, location.coordinate.longitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            maxLng = max(maxLng, location.coordinate.longitude)
        }
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat)/2, longitude: (minLng + maxLng)/2),
            span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat)*1.1, longitudeDelta: (maxLng - minLng)*1.1))
    }
    /*
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if !overlay.isKind(of: MKPolyline.self) {
            return nil
        }
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.black
        renderer.lineWidth = 5
        return renderer
    }*/
    
    func polyline() -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: locations.count)
    }
    
    func loadMap() {
        if locations.count > 0 {
            map.isHidden = false
            
            // Set the map bounds
            map.region = mapRegion()
            
            // Make the line(s!) on the map
            map.add(polyline())
        } else {
            // No locations were found!
            map.isHidden = true
            
            UIAlertView(title: "Error",
                        message: "Sorry, this run has no locations saved",
                        delegate:nil,
                        cancelButtonTitle: "OK").show()
        }
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
extension NewTrackViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if !overlay.isKind(of: MKPolyline.self) {
            return nil
        }
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 3
        return renderer
    }
}
