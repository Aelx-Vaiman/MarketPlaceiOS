import SwiftUI
import MapKit
import CoreLocation
import ToastSwiftUI

struct AddressAutoComplete: View {
    var backgroundColor: Color = Color(.systemGray6)
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var autoCompleteModel: AddressAutoCompleteViewModel
    @Binding var address: String
    @Binding var city: String
    
    @State private var isShowingToast = false
    
    init(address: Binding<String>, city: Binding<String>) {
        autoCompleteModel = AddressAutoCompleteViewModel()
        _address = address
        _city = city
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    TextField("Type address", text: $autoCompleteModel.searchableText)
                        .padding()
                        .autocorrectionDisabled()
                        .font(.title)
                        .onReceive(
                            autoCompleteModel.$searchableText.debounce(
                                for: .seconds(1),
                                scheduler: DispatchQueue.main
                            )
                        ) {
                            autoCompleteModel.searchAddress($0)
                        }
                        .background(Color(.systemBackground))
                    ClearButton(text: $autoCompleteModel.searchableText, autoCompleteModel: autoCompleteModel)
                        .padding(.trailing)
                        .padding(.top, 8)
                    Button(action: {
                        // Fetch the current location
                        getCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                            .padding(.trailing, 8)
                    } .offset(y: 6) // Adjust the offset value as needed
                }.background(Color.white)
                
                List(autoCompleteModel.results) { address in
                    AddressRow(address: address)
                        .listRowBackground(backgroundColor)
                        .onTapGesture {
                            // Handle the selection here
                            handleSelection(address)
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(backgroundColor)
            .edgesIgnoringSafeArea(.bottom)
            .toast(isPresenting: $isShowingToast, message: "Please allow location permission for current location ", icon: .info)
        }
    }
    
    
    func handleSelection(_ address: AddressResult) {
        // Handle the address selection here
        self.address = "\(address.locationTitle), \(address.city)"
        self.city = address.city
        presentationMode.wrappedValue.dismiss()
    }
    
    let locManager = CLLocationManager()
    func getCurrentLocation() {
        if LocationManager.sharedInstance.isPermissionDeniedByUse {
            isShowingToast = true
        }
        
        if let currentLocation = LocationManager.sharedInstance.getCurrentLocation() {
            // Fetch the address for the current location
             autoCompleteModel.searchAddressForLocation(location: currentLocation)
            print(currentLocation)
        }
    }
}

struct ClearButton: View {
    @Binding var text: String
    var autoCompleteModel: AddressAutoCompleteViewModel
    
    var body: some View {
        Button(action: {
            autoCompleteModel.clearResults()
            text = ""
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .imageScale(.medium)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct AddressRow: View {
    var address: AddressResult
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(address.locationTitle)
                .font(.headline)
            Text(address.city)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}


struct AddressAutoComplete_Previews: PreviewProvider {
    static var previews: some View {
        AddressAutoComplete(address: .constant(""), city: .constant(""))
    }
}
