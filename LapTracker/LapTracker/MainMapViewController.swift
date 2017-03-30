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

class MainMapViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var tracks = [Track]()
    var currentLocation: CLLocation!
    var selected = false
    
    //let addButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addPressed))
    //let leaderboardButtonItem = UIBarButtonItem(title: "Leaderboard", style: .plain, target: self, action: #selector(leaderboardPressed))
    
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
        let tgr = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tgr.numberOfTapsRequired = 1
        tgr.delaysTouchesBegan = true
        tgr.delegate = self
        self.map.addGestureRecognizer(tgr)
    }

    func addPressed() {
        print("add pressed")
    }
    
    func leaderboardPressed() {
        print("leaderboard pressed")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("update location")
        for location in locations {
            currentLocation = location
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
    
    /*
    func clearPolylinesOutside(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let lines = tracks.filter{$0.locations.first!.coordinate.latitude < southWest.latitude || $0.locations.first!.coordinate.latitude > northEast.latitude || $0.locations.first!.coordinate.longitude < southWest.longitude || $0.locations.first!.coordinate.longitude > northEast.longitude}
        map.removeOverlays(lines.map{$0.polyline})
        //map.o
    }*/
    
    func clearPolylinesOutside(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let lines = tracks.filter{!trackWithin(track: $0, southWest: southWest, northEast: northEast)}
        map.removeOverlays(lines.map{$0.polyline})
    }
    
    func trackWithin(track: Track, southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) -> Bool {
        let hbNorthEast = track.hitbox.northEast
        let hbSouthWest = track.hitbox.southWest
        let hbNorthWest = CLLocationCoordinate2D(latitude: hbSouthWest.latitude, longitude: hbNorthEast.longitude)
        let hbSouthEast = CLLocationCoordinate2D(latitude: hbNorthEast.latitude, longitude: hbSouthWest.longitude)
        
        let northWestIsIn = hbNorthWest.latitude > southWest.latitude && hbNorthWest.latitude < northEast.latitude && hbNorthWest.longitude > southWest.longitude && hbNorthWest.longitude < northEast.longitude
        
        let northEastIsIn = hbNorthEast.latitude > southWest.latitude && hbNorthEast.latitude < northEast.latitude && hbNorthEast.longitude > southWest.longitude && hbNorthEast.longitude < northEast.longitude
        
        let southWestIsIn = hbSouthWest.latitude > southWest.latitude && hbSouthWest.latitude < northEast.latitude && hbSouthWest.longitude > southWest.longitude && hbSouthWest.longitude < northEast.longitude
        
        let southEastIsIn = hbSouthEast.latitude > southWest.latitude && hbSouthEast.latitude < northEast.latitude && hbSouthEast.longitude > southWest.longitude && hbSouthEast.longitude < northEast.longitude
        
        return northWestIsIn || northEastIsIn || southWestIsIn || southEastIsIn
    }
    
    func pointInHitbox(point: CLLocationCoordinate2D) -> [Track] {
        var retTracks = [Track]()
        for track in tracks {
            if point.latitude > track.hitbox.southWest.latitude && point.latitude < track.hitbox.northEast.latitude && point.longitude > track.hitbox.southWest.longitude && point.longitude < track.hitbox.northEast.longitude {
                retTracks.append(track)
            }
        }
        return retTracks
    }
    
    /*
    func addPolylinesInside(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let lines = tracks.filter{$0.locations.first!.coordinate.latitude > southWest.latitude && $0.locations.first!.coordinate.latitude < northEast.latitude && $0.locations.first!.coordinate.longitude > southWest.longitude && $0.locations.first!.coordinate.longitude < northEast.longitude}
        map.addOverlays(lines.map{$0.polyline})
    }*/
    
    func addPolylinesInside(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        let lines = tracks.filter{trackWithin(track: $0, southWest: southWest, northEast: northEast)}
        map.addOverlays(lines.map{$0.polyline})
    }
    
    func handleTap(gestureReconizer: UITapGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.began {
            let touchLocation = gestureReconizer.location(in: map)
            let locationCoordinate = map.convert(touchLocation,toCoordinateFrom: map)
            //print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            tapped(locationCoordinate: locationCoordinate)
            
            return
        }
    }
    
    func tapped(locationCoordinate: CLLocationCoordinate2D) {
        selectTrack(tracks: pointInHitbox(point: locationCoordinate))
    }
    
    func selectTrack(tracks: [Track]) {
        if /*tracks.isEmpty ||*/ selected {
            deselect()
        } else if tracks.count == 1 {
            if !selected {
                map.setRegion(mapRegion(track: tracks[0]), animated: true)
                //map.region = mapRegion(track: tracks[0])
                clearAllExcept(track: tracks[0])
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Leaderboard", style: .plain, target: self, action: #selector(leaderboardPressed))
                selected = true
            }
        } else if tracks.count > 1 {
            
        }
    }
    
    func deselect() {
        if selected {
            centerMapOnLocation(location: currentLocation)
            mapView(map, regionDidChangeAnimated: true)
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addPressed))
            selected = false
        }
    }
    
    func clearAllExcept(track: Track) {
        var tempPolyline = track.polyline
        clearPolylines()
        map.add(tempPolyline!)
    }
    
    func mapRegion(track: Track) -> MKCoordinateRegion {
        
        var minLat = track.locations[0].coordinate.latitude
        var minLng = track.locations[0].coordinate.longitude
        var maxLat = minLat
        var maxLng = minLng
        
        for location in track.locations {
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
