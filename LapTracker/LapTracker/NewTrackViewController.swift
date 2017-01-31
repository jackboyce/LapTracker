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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    func eachSecond(timer: Timer) {
        seconds += 1
        let secondsQuantity = HKQuantity(unit: HKUnit.second(), doubleValue: seconds)
        tempLabel.text = "Time: " + secondsQuantity.description
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
        tempLabel.text = tempLabel.text! + "\nDistance: " + distanceQuantity.description
        
        let paceUnit = HKUnit.second().unitDivided(by: HKUnit.meter())
        let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: seconds / distance)
        tempLabel.text = tempLabel.text! + "\nPace: " + paceQuantity.description
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        map.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            centerMapOnLocation(location: location)
            //centerMapOnLocation(location: location)
            //print(location.coordinate.latitude)
            //print(location.coordinate.longitude)
            if location.horizontalAccuracy < 20 {
                //update distance
                if self.locations.count > 0 {
                    distance += location.distance(from: self.locations.last!)
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
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(eachSecond), userInfo: nil, repeats: true)
        startLocationUpdates()
    }
    
    @IBAction func stop(_ sender: Any) {
        for location in locations {
            print(location.coordinate.latitude)
            print(location.coordinate.longitude)
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
