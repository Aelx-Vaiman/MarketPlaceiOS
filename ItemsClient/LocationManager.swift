import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    var currentCity: String?
    static let sharedInstance = LocationManager()

    override private init() {
        super.init()
        self.locationManager.delegate = self
        if CLLocationManager().authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    
        self.locationManager.startUpdatingLocation()
        findCity()
    }
    
    var isPermissionDeniedByUse: Bool {
        if CLLocationManager().authorizationStatus == .denied || CLLocationManager().authorizationStatus == .restricted  {
            return true
        }
        
        return false
    }

    private func findCity() {
        let geocoder = CLGeocoder()
        guard let location = locationManager.location else {
            return
        }
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                return
            }

            if let placemark = placemarks?.first {
                if let city = placemark.locality {
                    self.currentCity = city
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                return
            }

            if let placemark = placemarks?.first {
                if let city = placemark.locality {
                    self.currentCity = city
                }
            }
        }
    }
    
    func getCurrentLocation() -> CLLocation? {
        return locationManager.location
    }
}

