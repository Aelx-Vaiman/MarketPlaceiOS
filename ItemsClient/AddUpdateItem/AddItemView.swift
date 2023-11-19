import SwiftUI

struct AddItemView: View {
    @State var isShowingToast: Bool = false
    //@Binding var items: [ListItem]
    var currentUser:GoogleUser?
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
                TextField("Title", text: $title)
                
                // TextEditor for description with character limit
                TextEditor(text: $description)
                    .frame(minHeight: 100) // Set a minimum height
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
                    locationText = location.count == 0 ? "Pick your address" : location
                }
            }

            Section {
                Button("Add Item") {
                    addItem()
                }
            }
        }.toast(isPresenting: $isShowingToast, message: toastMsg, icon: .info)
    }

    static var inProgress = false
    private func addItem() {
        if AddItemView.inProgress {
            return
        }
        
        AddItemView.inProgress  = true
        
        guard let currentUser = currentUser else {
            AddItemView.inProgress  = false
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        if title.isEmpty || description.isEmpty || phoneNumber.isEmpty || city.isEmpty  {
            AddItemView.inProgress  = false
            toastMsg = "Please fill all data"
            isShowingToast = true
            return
        }
        let newItem = ListItem(title: title, description: description, location: location, city: city, phoneNumber: phoneNumber, userName: currentUser.fullName ?? "John Dow", userId: currentUser.email!)
        
        AddsApi.sharedInstance.addItem(item: newItem) { err in
            AddItemView.inProgress  = false
            if err != nil {
                toastMsg = "Could not add new item at this time, please try again later"
                isShowingToast = true
            } else {
                // Dismiss the AddItemView
                DispatchQueue.main.async() {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
