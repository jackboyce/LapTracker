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
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("update location")
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("moved")
        let northEast = map.convert(CGPoint(x: mapView.bounds.width, y: 0), toCoordinateFrom: mapView)
        let southWest = map.convert(CGPoint(x: 0, y: mapView.bounds.height), toCoordinateFrom: mapView)
        
        //print(northEast)
        //print(ServerCommands.getTracksWithin(southWestLat: southWest.latitude, southWestLong: southWest.longitude, northEastLat: northEast.latitude, northEastLong: northEast.longitude))
        formLines(southWestLat: southWest.latitude, southWestLong: southWest.longitude, northEastLat: northEast.latitude, northEastLong: northEast.longitude)
    }
    
    var polylines = [MKPolyline]()
    
    func formLines(southWestLat: Double, southWestLong: Double, northEastLat: Double, northEastLong: Double) {
        var tracks = ServerCommands.getTracksWithin(southWestLat: southWestLat, southWestLong: southWestLong, northEastLat: northEastLat, northEastLong: northEastLong)
        //print(tracks)
        
        for track in tracks {
            var temp = polyline(locations: ServerCommands.getLocationsForTrack(id: track.id))
            if !polylines.contains(temp) {
                print("new")
                map.add(temp)
                polylines.append(temp)
            }
        }
    }
    
    func polyline(locations: [CLLocation]) -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: locations.count)
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
