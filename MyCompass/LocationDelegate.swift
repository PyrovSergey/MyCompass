//
//  LocationDelegate.swift
//  MyCompass
//
//  Created by Sergey on 12/04/2019.
//  Copyright © 2019 PyrovSergey. All rights reserved.
//

import Foundation
import CoreLocation

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var locationCallback: ((CLLocation) -> ())? = nil
    var coordinatesCallback: ((CLLocationCoordinate2D) -> ())? = nil
    var headingCallback: ((CLLocationDirection) -> ())? = nil
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else {
            return
        }
        locationCallback?(currentLocation)
        guard let currentCoordinates = manager.location?.coordinate else { return }
        coordinatesCallback?(currentCoordinates)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingCallback?(newHeading.magneticHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Error while updating location " + error.localizedDescription)
    }
}
