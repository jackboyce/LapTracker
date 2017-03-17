//
//  PlayTrackViewController.swift
//  LapTracker
//
//  Created by Jack Boyce on 3/14/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class PlayTrackViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var instructionBox: UILabel!
    weak var track: Track!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    var timer = Timer()
    var recording = false
    var step = 0
    var time = 0.0
    var timerInterval = 0.1
    var currentTargetLocation = 0
    var startingPositon = false //false if the person starts on the origional side and true if they are going in reverse
    
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = .other
        
        // Movement threshold for new events
        _locationManager.distanceFilter = 10.0
        return _locationManager
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load the track overlay
        map.delegate = self
        instructionBox.text = ""
        timeLabel.text = ""
        loadMap()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Leaderboard", style: .plain, target: self, action: #selector(leaderboardPressed))
        
        /*
        var tempCount = 0
        
        
        for location in track.locations {
            map.add(MKCircle(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), radius: CLLocationDistance(Int(10 + tempCount))))
            //tempCount += 2
        }*/
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionButton(_ sender: Any) {
        button.setTitle(recording ? "Start" : "Stop", for: .normal)
        recording = !recording
        
        recording ? start() : stop()
    }
    
    func leaderboardPressed() {
        print("press")
        let leaderboardTrackViewController = self.storyboard?.instantiateViewController(withIdentifier: "Leaderboard") as! LeaderboardTableViewController
        leaderboardTrackViewController.track = track
        self.navigationController?.pushViewController(leaderboardTrackViewController, animated: true)
    }
    
    func start() {
        print("Start")
        step = 0
        time = 0.0
        currentTargetLocation = 0
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        print("Stop")
        timer.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
                
                //Before the phone gets to the beggining to the track
                if step == 0 {
                    instructionBox.text = "Proceed to the starting location"
                    
                    //If the phone gets to the first location of the track locations array
                    if track.locations[0].distance(from: location) < 10 {
                        step += 1
                        startTimer()
                        startingPositon = false
                        currentTargetLocation = 1
                    }
                    //If the phone gets to the last location of the track location array
                    if track.locations[track.locations.count - 1].distance(from: location) < 10 {
                        step += 1
                        startTimer()
                        startingPositon = true
                        currentTargetLocation = track.locations.count - 1
                    }
                }
                
                //After the phone gets to the first location and the timer has started
                if step == 1 {
                    instructionBox.text = "Follow the line \(currentTargetLocation)"
                    
                    //Add something for if the phone gets off track
                    
                    
                    //If the phone gets to the last location of the track relative to array positions
                    if Double((track.locations.last?.distance(from: location))!) < 10 && currentTargetLocation == track.locations.count - 1 && !startingPositon {
                        step += 1
                        ServerCommands.addTime(time: time, tracknumber: track.id) { resp in
                            print("send info")
                            print(resp)
                        }
                    }
                    
                    //If the phone gets to the first location according to array positions
                    if Double(track.locations[0].distance(from: location)) < 10 && currentTargetLocation == 0 && startingPositon {
                        step += 1
                        ServerCommands.addTime(time: time, tracknumber: track.id) { resp in
                            print("send info")
                            print(resp)
                        }
                    }
                }
                
                //After the phone has gotten to the last location of the track
                if step == 2 {
                    instructionBox.text = "Done"
                    actionButton(self)
                }
                
                //After the phone has gotten off of the track
                if step == 3 {
                    
                }
            }
            //print(track.locations.count - 1)
            //print(currentTargetLocation)
            
            if Double(track.locations[currentTargetLocation].distance(from: location)) < 10 && currentTargetLocation < track.locations.count - 1 && currentTargetLocation > 0 {
                //map.add(MKCircle(center: CLLocationCoordinate2D(latitude: track.locations[currentTargetLocation + 1].coordinate.latitude, longitude: track.locations[currentTargetLocation + 1].coordinate.longitude), radius: 10))
                currentTargetLocation += startingPositon ? -1 : 1
            }
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
    }
    
    func timerUpdate() {
        time += timerInterval
        timeLabel.text = "Time: \(time)"
    }
    
    func radiansToDegrees (radians: Double)->Double {
        return radians * 180 / M_PI
    }
    
    func degreesToRadians(degrees: Double) -> Double {
        return degrees * M_PI / 180
    }
    
    func distFromLineSegment(first: CLLocation, second: CLLocation, current: CLLocation) -> Double {
        var x1 = first.coordinate.latitude
        var y1 = first.coordinate.longitude
        var x2 = second.coordinate.latitude
        var y2 = second.coordinate.longitude
        var x0 = current.coordinate.latitude
        var y0 = current.coordinate.longitude
        
        return 0
    }
    
    func mapRegion() -> MKCoordinateRegion {
        
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
    
    func polyline() -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in track.locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: track.locations.count)
    }
    
    func circleOnLocations() -> [MKCircle] {
        var coords = [CLLocationCoordinate2D]()
        var ret: [MKCircle] = [MKCircle]()
        
        for location in track.locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            ret.append(MKCircle(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), radius: 10))
        }
        return ret
    }
    
    func loadMap() {
        if track.locations.count > 0 {
            map.isHidden = false
            // Set the map bounds
            map.region = mapRegion()
            
            /*
            for element in circleOnLocations() {
                map.add(element)
            }*/
            
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
extension PlayTrackViewController: MKMapViewDelegate {
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
