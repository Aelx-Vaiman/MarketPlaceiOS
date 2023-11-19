import Foundation
import MapKit

struct AddressResult: Identifiable {
    let id = UUID()
    let locationTitle: String
    let city: String
}

class AddressAutoCompleteViewModel: NSObject, ObservableObject {
    
    @Published private(set) var results: Array<AddressResult> = []
    @Published var searchableText = ""
    
    private lazy var localSearchCompleter: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.delegate = self
        completer.resultTypes = .address
        return completer
    }()
    
    func searchAddress(_ searchableText: String) {
        guard searchableText.isEmpty == false else { return }
        localSearchCompleter.queryFragment = searchableText
    }
    
    func searchAddressForLocation(location: CLLocation) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                // Handle the error if needed
                return
            }
            
            if let placemark = placemarks?.first {
                // Update results with the new address
                self.results = [AddressResult(locationTitle: placemark.name ?? "", city: placemark.locality ?? "")]
            }
        }
    }
}

extension AddressAutoCompleteViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            results = completer.results.filter{ !$0.subtitle.isEmpty }.map {
                AddressResult(locationTitle: $0.title, city: $0.subtitle)
            }
        }
    }
    
//    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
//        Task { @MainActor in
//            results = completer.results
//                .filter { result in
//                    // Check if the result has meaningful address components
//                    let hasAddress = !result.title.isEmpty && !result.subtitle.isEmpty
//                    return hasAddress
//                }
//                .map {
//                    AddressResult(title: $0.title, subtitle: $0.subtitle)
//                }
//        }
//    }
//    
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error)
    }
    
    func clearResults() {
        results.removeAll()
    }
}
