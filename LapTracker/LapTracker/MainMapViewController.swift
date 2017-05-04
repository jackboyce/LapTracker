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
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var map: MKMapView!
    var tracks = [Track]()
    var timer = Timer()
    var recording = false
    var step = 0
    var time = 0.0
    var timerInterval = 0.1
    var currentTargetLocation = 0
    var startingPositon = false //false if the person starts on the origional side and true if they are going in reverse
    var timerStarted = false
    var currentLocation: CLLocation!
    var selected: Track? = nil
    var intentionalMove = false
    var playing = false
    var adding = false
    var addingStopped = false
    var toleranceMultiple = 4.0
    var locations = [CLLocation]()
    
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

        intentionalMove = true
        
        locationManager.requestAlwaysAuthorization()//fix this
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
        print("Add pressed")
        //adding = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startRecordPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAddPressed))
    }
    
    func startRecordPressed() {
        print("Start record pressed")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(stopRecordPressed))
        adding = true
        time = 0.0
        //distance = 0.0
        locations.removeAll(keepingCapacity: false)
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
        //startLocationUpdates()
        
        //navigationItem.leftBarButtonItem = nil
    }
    
    func cancelAddPressed() {
        print("Cancel add pressed")
        adding = false
        addingStopped = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addPressed))
        navigationItem.leftBarButtonItem = nil
    }
    
    func stopRecordPressed() {
        print("stop record pressed")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveRecordPressed))
        //adding = false
        addingStopped = true
        timer.invalidate()
        setMapRegionWithoutTrigger(region: mapRegion(locations: locations))
    }
    
    func saveRecordPressed() {
        /*
        for a in locations {
            print("\(a.coordinate.latitude) \(a.coordinate.longitude)")
        }*/
        
        print("Save record pressed")
        promptFor(title: "Name", message: "Enter name for track", placeholder: "Track Name") { resp in
            ServerCommands.addTrackWithLocations(name: resp!, locations: self.locations) { resp in
                print("sent all locations")
                //print(resp!)
                ServerCommands.addTime(time: self.time, tracknumber: Int(resp!)!) { resp in
                    //print(resp)
                    self.label.text = ""
                    self.time = 0
                    self.cancelAddPressed()
                }
            }
        }
    }
    
    func leaderboardPressed() {
        print("leaderboard pressed")
        let leaderboardTrackViewController = self.storyboard?.instantiateViewController(withIdentifier: "Leaderboard") as! LeaderboardTableViewController
        leaderboardTrackViewController.track = selected
        self.navigationController?.pushViewController(leaderboardTrackViewController, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("update location")
        for location in locations {
            currentLocation = location
            if !playing && selected == nil && !adding {
                centerMapOnLocation(location: location)
            }
            
            if playing {
                playWith(location: currentLocation)
            }
            
            if adding && !addingStopped {
                addWith(location: currentLocation)
            }
        }
    }
    
    func playWith(location: CLLocation) {
        var track = selected!
        let howRecent = location.timestamp.timeIntervalSinceNow
        print("Playing \(track.name)")
        print("Step \(step)")
        
        //if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
            
            //Before the phone gets to the beggining to the track
            if step == 0 {
                label.text = "Proceed to a starting location"
                //Used to find the first points on either end of the array that are no closer than 40 meters
                var first = 0
                var last = track.locations.count - 1
                
                while track.locations[first].distance(from: track.locations[last]) < 40 {
                    first += 1
                    last -= 1
                }
                
                //Starts the timer at either the last point or first point of a track
                if track.locations[0].distance(from: location) < 10 || track.locations[track.locations.count - 1].distance(from: location) < 10 {
                    startTimer()
                }
                
                //If the phone gets to the first location of the track locations array that is not closer than 40 meters
                if track.locations[first].distance(from: location) < 10 {
                    step += 1
                    //startTimer()
                    startingPositon = false
                    currentTargetLocation = first + 1
                }
                //If the phone gets to the last location of the track location array that is not closer than 40 meters
                if track.locations[last].distance(from: location) < 10 {
                    step += 1
                    //startTimer()
                    startingPositon = true
                    currentTargetLocation = last - 1
                }
            }
            
            //After the phone gets to the first location and the timer has started
            if step == 1 {
                //instructionBox.text = "Follow the line \(currentTargetLocation)"
                
                //Add something for if the phone gets off track
                if currentTargetLocation > 0 && currentTargetLocation <  track.locations.count - 1 && (location.distance(from: track.locations[currentTargetLocation]) > track.locations[currentTargetLocation - 1].distance(from: track.locations[currentTargetLocation]) * toleranceMultiple ) {
                    stopPlaying()
                    label.text = "Got off track, please try again"
                    step = 3
                    print("Off Track between \(currentTargetLocation - 1) and \(currentTargetLocation)")
                    print("(Distance from target location > Distance between last and current target * \(toleranceMultiple)): \(location.distance(from: track.locations[currentTargetLocation])) > \(track.locations[currentTargetLocation - 1].distance(from: track.locations[currentTargetLocation]) * toleranceMultiple)")
                }
                
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
                label.text = "Done"
                stopPlaying()
            }
            
            //After the phone has gotten off of the track
            if step == 3 {
                
            }
        //}
        //print(track.locations.count - 1)
        //print(currentTargetLocation)
        
        if currentTargetLocation > 0 && currentTargetLocation <  track.locations.count - 1 && Double(track.locations[currentTargetLocation].distance(from: location)) < 20 && currentTargetLocation < track.locations.count && currentTargetLocation > 0 {
            //map.add(MKCircle(center: CLLocationCoordinate2D(latitude: track.locations[currentTargetLocation + 1].coordinate.latitude, longitude: track.locations[currentTargetLocation + 1].coordinate.longitude), radius: 10))
            currentTargetLocation += startingPositon ? -1 : 1
        }
    }
    
    func addWith(location: CLLocation) {
        if self.locations.count > 0 {
            //distance += location.distance(from: self.locations.last!)
            
            var coords = [CLLocationCoordinate2D]()
            coords.append(self.locations.last!.coordinate)
            coords.append(location.coordinate)
            
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
            map.setRegion(region, animated: true)
            //map.setRegion(mapRegion(locations: locations), animated: true)
            
            map.add(MKPolyline(coordinates: &coords, count: coords.count))
        }
        //save location
        self.locations.append(location)

    }
    
    func startTimer() {
        if !timerStarted {
            timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
            timerStarted = true
        }
    }
    
    func stopTimer() {
        if timerStarted {
            timer.invalidate()
            timerStarted = false
        }
    }
    
    func startPlaying() {
        print("Start")
        step = 0
        time = 0.0
        currentTargetLocation = 0
        //locationManager.startUpdatingLocation()
    }
    
    func stopPlaying() {
        print("Stop")
        stopTimer()
        //step = 0
        //time = 0.0
        //currentTargetLocation = 0
        //locationManager.stopUpdatingLocation()
    }
    
    func timerUpdate() {
        time += timerInterval
        //timeLabel.text = "Time: \(time)"
        //instructionBox.text = "Follow the line \(currentTargetLocation)"
        label.text = "Follow the line \(time)"
    }
    
    func centerMapOnLocation(location: CLLocation) {
        var regionRadius = 1000.0
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        //setMapRegionWithoutTrigger(region: coordinateRegion)
        map.setRegion(coordinateRegion, animated: true)
    }
    
    func setMapRegionWithoutTrigger(region: MKCoordinateRegion) {
        intentionalMove = true
        map.setRegion(region, animated: true)
        //intentionalMove = false
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if !intentionalMove {
            print("moved")
            let northEast = map.convert(CGPoint(x: mapView.bounds.width, y: 0), toCoordinateFrom: mapView)
            let southWest = map.convert(CGPoint(x: 0, y: mapView.bounds.height), toCoordinateFrom: mapView)
            
            formLines(southWest: southWest, northEast: northEast)
        }
        intentionalMove = false
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
    
    func addCirclesOnEndsTo(track: Track) {
        map.add(MKCircle(center: CLLocationCoordinate2D(latitude: track.locations[0].coordinate.latitude, longitude: track.locations[0].coordinate.longitude), radius: CLLocationDistance(Int(10))))
        map.add(MKCircle(center: CLLocationCoordinate2D(latitude: track.locations[track.locations.count - 1].coordinate.latitude, longitude: track.locations[track.locations.count - 1].coordinate.longitude), radius: CLLocationDistance(Int(10))))
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
        if /*tracks.isEmpty ||*/ selected != nil {
            deselect()
        } else if tracks.count == 1 {
            if selected == nil {
                //map.setRegion(mapRegion(track: tracks[0]), animated: true)
                setMapRegionWithoutTrigger(region: mapRegion(track: tracks[0]))
                playing = true
                selected = tracks[0]
                //label.text = "TESSTING"
                startPlaying()
                playWith(location: currentLocation)
                //map.region = mapRegion(track: tracks[0])
                clearAllExcept(track: selected!)
                addCirclesOnEndsTo(track: selected!)
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Leaderboard", style: .plain, target: self, action: #selector(leaderboardPressed))
                
            }
        } else if tracks.count > 1 {
            
        }
    }
    
    func deselect() {
        if selected != nil {
            centerMapOnLocation(location: currentLocation)
            mapView(map, regionDidChangeAnimated: true)
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addPressed))
            stopPlaying()
            selected = nil
            playing = false
            label.text = ""
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
    
    func mapRegion(locations: [CLLocation]) -> MKCoordinateRegion {
        
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
    
    func promptFor(title: String, message: String, placeholder: String, completionHandler: @escaping (String?) -> ()) -> () {
        //1. Create the alert controller.
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = placeholder
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            //print("Text field: \(textField?.text)")
            let resp = alert?.textFields![0].text
            completionHandler(resp)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak alert] (_) in
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
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
