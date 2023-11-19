import SwiftUI
import CoreLocation
import MapKit
import ToastSwiftUI

struct ItemDetail: View {
    @State var item: ListItem
    @State private var coordinates: CLLocationCoordinate2D?
    var currentUser: GoogleUser?
    
    @State private var isShowingToast = false
    @State private var toastMsg = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Item published at \(formatDate(item.date))")

                    Text("Item owner \(item.userName)")

                    Text("Contact number \(item.phoneNumber)")

                    Rectangle()
                        .frame(height: 10).foregroundColor(.clear)

                    Text(item.title)
                        .font(.headline)

                    Text(" \(item.description)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("Location: \(item.location)")
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    Rectangle()
                        .frame(height: 20).foregroundColor(.clear)

                    // Display Map if coordinates are available
                    if let coordinates = coordinates {
                        Map(coordinateRegion: .constant(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))))
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                    
                    Rectangle()
                        .frame(height: 10).foregroundColor(.clear)
                    
                    // Share button
                    Button("Share") {
                        shareItem()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Spacer()
                }
                .padding(16) // Add vertical padding
                .onAppear {
                    geocodeAddress(item.location) { coords in
                        coordinates = coords
                    }
                }.toast(isPresenting: $isShowingToast, message: toastMsg, icon: .info)
            }

            // Remove and Edit buttons
            if let currentUserEmail = currentUser?.email, currentUserEmail == item.userId {
                HStack(spacing: 24) {
                    Button("Remove") {
                        // Implement remove functionality
                        removeItem()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    NavigationLink(destination: EditItemView(item: $item, currentUser: currentUser)) {
                        Text("Edit")
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding([.leading, .trailing, .top], 24) // Add horizontal padding
                .background(Color.gray.opacity(0.2))
            }
        }
    }
    
    private func removeItem() {
        AddsApi.sharedInstance.removeItem(id: item.id) { err in
            if err != nil {
                toastMsg = "Oops something wrong, please try again later"
                isShowingToast = true
            } else {
                // Dismiss the AddItemView
                DispatchQueue.main.async() {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func formatDate(_ date: String) -> String {
        let dateFormatter = AddsApi.sharedInstance.serverDateDateFormatter()

        if let serverDate = dateFormatter.date(from: date) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd/MM/yyyy"  // Adjust the format as needed

            return outputFormatter.string(from: serverDate)
        }

        return date
    }

    private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Error geocoding address: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            completion(location.coordinate)
        }
    }
    
    private func shareItem() {
         let itemInfo = """
                 Item Details:
                 Item published at: \(formatDate(item.date))
                 Owner Name: \(item.userName)
                 Phone: \(item.phoneNumber)
                 Title: \(item.title)
                 Description: \(item.description)
                 Location: \(item.location)
                 """
         
         let activityViewController = UIActivityViewController(activityItems: [itemInfo], applicationActivities: nil)
         
         UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
     }
}
