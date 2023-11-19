import SwiftUI

struct EditItemView: View {
    //@Binding var items: [ListItem]
    @Binding var item: ListItem
    var currentUser: GoogleUser?
    @State private var isShowingToast: Bool = false
    @State private var toastMsg = ""
    @State private var phoneNumber = ""
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var city = ""
    @State private var locationText = "Pick your address"
    @Environment(\.presentationMode) var presentationMode

    // Maximum characters for description
    let maxDescriptionLength = 200

    var body: some View {
        Form {
            Section(header: Text("Item Details")) {
                TextField("Phone number", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .onAppear {
                        phoneNumber = item.phoneNumber
                    }
                
                TextField("Title", text: $title)
                    .onAppear {
                        title = item.title
                    }
                
                // TextEditor for description with character limit
                TextEditor(text: $description)
                    .frame(minHeight: 100) // Set a minimum height
                    .onAppear {
                        description = item.description
                    }
                    .onChange(of: description) { newDescription in
                        // Limit the number of characters
                        if newDescription.count > maxDescriptionLength {
                            description = String(newDescription.prefix(maxDescriptionLength))
                        }
                    }
            }

            Section {
                // "Location" row with NavigationLink
                NavigationLink(destination: AddressAutoComplete(address: $location, city: $city)) {
                    Text(locationText)
                }
                .onChange(of: location) {
                    locationText =  $0
                }
                .onFirstAppear {
                    location = item.location
                    city = item.city
                    locationText = item.location
                }
            }

            Section {
                Button("Update Item") {
                    updateItem()
                }
            }
        }.toast(isPresenting: $isShowingToast, message: toastMsg, icon: .info)
    }

    private func updateItem() {
        guard let currentUser = currentUser else {
            presentationMode.wrappedValue.dismiss()
            return
        }

        if title.isEmpty || description.isEmpty || phoneNumber.isEmpty || city.isEmpty {
            toastMsg = "Please fill all data"
            isShowingToast = true
            return
        }

        item = ListItem(
            date: item.date,
            id: item.id,
            title: title,
            description: description,
            location: location,
            city: city,
            phoneNumber: phoneNumber,
            userName: currentUser.fullName ?? "John Dow",
            userId: currentUser.email!
        )
        
        AddsApi.sharedInstance.updateItem(id: item.id, updatedItem: item) { err in
            if err != nil {
                toastMsg = "Could not update the item at this time, please try again later"
                isShowingToast = true
            } else {
                // Dismiss the EditItemView
                DispatchQueue.main.async() {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
