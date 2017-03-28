//
//  Track.swift
//  LapTracker
//
//  Created by Jack Boyce on 3/13/17.
//  Copyright © 2017 Jack Boyce. All rights reserved.
//

import Foundation
import MapKit

class Track {
    var id: Int = 0
    var name: String = ""
    var creator: String = ""
    var locations: [CLLocation] = [CLLocation]()
    var polyline: MKPolyline!
    /*
    var locations: [CLLocation] {
        
        return ServerCommands.getLocationsForTrack(id : id)
    }*/
    
    var times : [(time: Double, username: String)] {
        return ServerCommands.getTimesForTrack(id: id)
    }
    
    init(id: Int, name: String, creator: String) {
        self.id = id
        self.name = name
        self.creator = creator
        self.locations = ServerCommands.getLocationsForTrack(id : id)
        self.polyline = polyline(locations: self.locations)
    }
    
    func polyline(locations: [CLLocation]) -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
        }
        return MKPolyline(coordinates: &coords, count: locations.count)
    }
}
