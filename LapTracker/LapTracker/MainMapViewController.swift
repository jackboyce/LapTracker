//
//  MainMapViewController.swift
//  LapTracker
//
//  Created by Jack Boyce on 3/27/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MainMapViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var tracks = [Track]()
    
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = .other
        
        // Movement threshold for new events
        _locationManager.distanceFilter = 5.0
        return _locationManager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestAlwaysAuthorization()
        self.map.delegate = self
        locationManager.startUpdatingLocation()
        // Do any additional setup after loading the view.
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addPressed))
    }

    func addPressed() {
        clearPolylines()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("update location")
        for location in locations {
            centerMapOnLocation(location: location)
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        var regionRadius = 1000.0
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        map.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("moved")
        let northEast = map.convert(CGPoint(x: mapView.bounds.width, y: 0), toCoordinateFrom: mapView)
        let southWest = map.convert(CGPoint(x: 0, y: mapView.bounds.height), toCoordinateFrom: mapView)
        
        formLines(southWest: southWest, northEast: northEast)
    }
    
    func formLines(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        
        manageTracks(southWest: southWest, northEast: northEast)
        
        clearPolylinesOutside(southWest: southWest, northEast: northEast)
        
        addPolylinesInside(southWest: southWest, northEast: northEast)
    }
    
    func manageTracks(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let tupleTracks = ServerCommands.getTracksWithin(southWestLat: southWest.latitude, southWestLong: southWest.longitude, northEastLat: northEast.latitude, northEastLong: northEast.longitude)
        //print(tracks)
        
        for track in tupleTracks {
            if !tracks.contains(where: {$0.id == track.id}) {
                tracks.append(Track(id: track.id, name: track.name, creator: track.creator))
                map.add((tracks.last?.polyline)!)
                print("new")
            }
        }
    }
    
    func clearPolylines() {
        //let lines = tracks.map{$0.polyline} as [MKPolyline]
        //map.removeOverlays(lines)
        map.removeOverlays(map.overlays)
    }
    
    func clearPolylinesOutside(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let lines = tracks.filter{$0.locations.first!.coordinate.latitude < southWest.latitude || $0.locations.first!.coordinate.latitude > northEast.latitude || $0.locations.first!.coordinate.longitude < southWest.longitude || $0.locations.first!.coordinate.longitude > northEast.longitude}
        map.removeOverlays(lines.map{$0.polyline})
        //map.o
    }
    
    func addPolylinesInside(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let lines = tracks.filter{$0.locations.first!.coordinate.latitude > southWest.latitude && $0.locations.first!.coordinate.latitude < northEast.latitude && $0.locations.first!.coordinate.longitude > southWest.longitude && $0.locations.first!.coordinate.longitude < northEast.longitude}
        map.addOverlays(lines.map{$0.polyline})
    }
    
    /*
    func polyline(locations: [CLLocation]) -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: locations.count)
    }*/
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension MainMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView!, rendererFor overlay: MKOverlay!) -> MKOverlayRenderer! {
        /*if !overlay.isKind(of: MKPolyline.self) {
         return nil
         }*/
        
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.red
            return circleRenderer
        }
        
        if let overlay = overlay as? MKPolyline {
            let polyline = overlay as! MKPolyline
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
        
        return nil
    }
}
