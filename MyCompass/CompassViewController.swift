//
//  ViewController.swift
//  MyCompass
//
//  Created by Sergey on 12/04/2019.
//  Copyright © 2019 PyrovSergey. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation
import AVFoundation

class CompassViewController: UIViewController {
    
    @IBOutlet weak var compass: UIImageView!
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var geographicalDirectionLabel: UILabel!
    @IBOutlet weak var arrowNortImage: UIImageView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longtitudeLabel: UILabel!

    private var switchButton: CustomSwitch?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if switchButton?.isOn ?? false {
            return .lightContent
        }
        return .default
    }
    
    
    let locationDelegate = LocationDelegate()
    var latestLocation: CLLocation? = nil
    var yourLocationBearing: CGFloat { return latestLocation?.bearingToLocationRadian(self.yourLocation) ?? 0 }
    var yourLocation: CLLocation {
        get { return UserDefaults.standard.currentLocation }
        set { UserDefaults.standard.currentLocation = newValue }
    }
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    private func orientationAdjustment() -> CGFloat {
        let isFaceDown: Bool = {
            switch UIDevice.current.orientation {
            case .faceDown: return true
            default: return false
            }
        }()
        
        let adjAngle: CGFloat = {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:  return 90
            case .landscapeRight: return -90
            case .portrait, .unknown: return 0
            case .portraitUpsideDown: return isFaceDown ? 180 : -180
            @unknown default:
                return 0
            }
        }()
        return adjAngle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = locationDelegate
        var currentHeight = UIScreen.main.bounds.height
        var coefficient: Int
        var switchButtonWidth: CGFloat = 120.0
        var switchButtonHeight: CGFloat = 80.0
        
        switch currentHeight {
        case 568:
            coefficient = 5
            switchButtonWidth = 100
            switchButtonHeight = 65
        case 896:
            coefficient = 3
        default:
            coefficient = 4
        }
        
        let x = (UIScreen.main.bounds.width / 2) - (switchButtonWidth / 2)
        let y = UIScreen.main.bounds.height - UIScreen.main.bounds.height / CGFloat(coefficient)
        switchButton = CustomSwitch(frame: CGRect(x: x, y: y, width: switchButtonWidth, height: switchButtonHeight))
        switchButton!.areLabelsShown = true
        switchButton!.isOn = false
        switchButton!.addTarget(self, action: #selector(CompassViewController.switchStateDidChange(_:)), for: .valueChanged)
        self.view.addSubview(switchButton!)
        
        locationDelegate.locationCallback = { location in
            self.latestLocation = location
        }
        
        locationDelegate.coordinatesCallback = { coordinates in
            let lat = String(coordinates.latitude).prefix(9)
            let long = String(coordinates.longitude).prefix(9)
            
            self.latitudeLabel.text = "\(String(lat))º N"
            self.longtitudeLabel.text = "\(String(long))º E"
        }
        
        locationDelegate.headingCallback = { newHeading in
            
            func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
                let heading: CGFloat = {
                    let originalHeading = self.yourLocationBearing - newAngle.degreesToRadians
                    switch UIDevice.current.orientation {
                    case .faceDown: return -originalHeading
                    default: return originalHeading
                    }
                }()
                
                return CGFloat(self.orientationAdjustment().degreesToRadians + heading)
            }
            
            UIView.animate(withDuration: 0.5) {
                let angle = computeNewAngle(with: CGFloat(newHeading))
                self.compass.transform = CGAffineTransform(rotationAngle: angle)
            }
            
            self.angleLabel.text = "\(Int(newHeading))º"
            var strDirection = String()
            if(newHeading > 23 && newHeading <= 67){
                strDirection = "NE";
            } else if(newHeading > 67 && newHeading <= 113){
                strDirection = "E";
            } else if(newHeading > 113 && newHeading <= 167){
                strDirection = "SE";
            } else if(newHeading > 167 && newHeading <= 203){
                strDirection = "S";
            } else if(newHeading > 203 && newHeading <= 247){
                strDirection = "SW";
            } else if(newHeading > 247 && newHeading <= 293){
                strDirection = "W";
            } else if(newHeading > 293 && newHeading <= 337){
                strDirection = "NW";
            } else if(newHeading > 337 || newHeading <= 23){
                strDirection = "N";
            }
            self.geographicalDirectionLabel.text = strDirection
        }
    }
    
    @objc private func switchStateDidChange(_ sender:UISwitch) {
        toggleTorch(on: sender.isOn)
        updateUIColor(on: sender.isOn)
        if sender.isOn {
            switchButton!.thumbTintColor = .gray
        } else {
            switchButton!.thumbTintColor = .white
        }
    }
    
}

extension UserDefaults {
    var currentLocation: CLLocation {
        get { return CLLocation(latitude: latitude ?? 90, longitude: longitude ?? 0) } // default value is North Pole (lat: 90, long: 0)
        set { latitude = newValue.coordinate.latitude
            longitude = newValue.coordinate.longitude }
    }
    
    private var latitude: Double? {
        get {
            if let _ = object(forKey: #function) {
                return double(forKey: #function)
            }
            return nil
        }
        set { set(newValue, forKey: #function) }
    }
    
    private var longitude: Double? {
        get {
            if let _ = object(forKey: #function) {
                return double(forKey: #function)
            }
            return nil
        }
        set { set(newValue, forKey: #function) }
    }
}

extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {
        
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        
        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return CGFloat(radiansBearing)
    }
    
    func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

//MARK: Flashlight
extension CompassViewController {
    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    private func updateUIColor(on: Bool) {
        if on {
            setNeedsStatusBarAppearanceUpdate()
            compass.image = UIImage(named: "black_compass")
            arrowNortImage.image = UIImage(named: "arrow_north_black")
            angleLabel.textColor = .white
            geographicalDirectionLabel.textColor = .white
            self.view.backgroundColor = UIColor(named: "black_background")
        } else {
            setNeedsStatusBarAppearanceUpdate()
            compass.image = UIImage(named: "white_compass")
            arrowNortImage.image = UIImage(named: "arrow_north_white")
            angleLabel.textColor = .black
            geographicalDirectionLabel.textColor = .black
            self.view.backgroundColor = UIColor(named: "white_background")
        }
    }
}

private extension Double {
    var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
    var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }
}

