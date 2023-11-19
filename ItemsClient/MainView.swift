import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import CoreLocation

struct MainView: View {
    let locManager = CLLocationManager()
    @State private var items: [ListItem] = []
    @State private var filteredItemsBySearch: [ListItem] = []
    @State private var filteredItemsByLocation: [ListItem] = []

    @ObservedObject var authManager: GoogleSignInManager
    @State private var isShowingToast = false
    @State private var searchText = ""
    @State private var shouldFilterByCurrentCity = false

    init() {
        let clientId = FirebaseApp.app()?.options.clientID
        authManager = GoogleSignInManager(GIDClientID: clientId ?? "")
    }

    var body: some View {
        VStack {
            HStack {
                SearchBar(text: $searchText, placeholder: "Search item for sale")
                    .onChange(of: searchText) {
                        filterItemsBySearch()
                    }

                Button(action: {
                    shouldFilterByCurrentCity.toggle()
                    filterItemsByLocationIfNeeded()
                }) {
                    Image("locationFilter")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
            .padding()
            List(filteredItemsBySearch) { item in
                NavigationLink(destination: ItemDetail(item: item, currentUser: authManager.currentUser)) {
                    HStack {
                        if isCurrentUserItem(item) {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(Color.green.opacity(0.5))
                        } else {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(.gray)
                        }
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Location: \(item.location)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .refreshable {
                fetchItems()
            }
            .onAppear {
                fetchItems()
            }

            Spacer()

            HStack {
                Button(action: {
                    if !authManager.isSingedIn {
                        Task {
                            do {
                                try await authManager.signIn()
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    } else {
                        authManager.signOut()
                    }
                }) {
                    Image(systemName: !authManager.isSingedIn ? "person.circle" : "arrow.down.left.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(!authManager.isSingedIn ? .blue : .red)
                }
                .padding()

                Spacer()

                if authManager.isSingedIn {
                    NavigationLink(destination: AddItemView(currentUser: authManager.currentUser)) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }.padding()
                } else {
                    Button(action: {
                        isShowingToast = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
            }
        }
        .toast(isPresenting: $isShowingToast, message: "Please log in before adding new items", icon: .info)
        .background(Color(.secondarySystemBackground))
    }

    private func fetchItems() {
        AddsApi.sharedInstance.fetchAllItems { items, error in
            if let items = items {
                // Sort items by date in descending order
                let sortedItems = items.sorted { $0.date > $1.date }
                DispatchQueue.main.async {
                    // Update UI on the main thread
                    self.items = sortedItems
                    self.filteredItemsBySearch = sortedItems
                    self.filteredItemsByLocation = sortedItems

                    // Apply other filters
                    self.filterItemsByLocationIfNeeded()
                }
            } else {
                // Handle error
                print("Error fetching items: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func filterItemsByLocationIfNeeded()  {
        defer {
            filterItemsBySearch()
        }

        if !shouldFilterByCurrentCity {
            filteredItemsByLocation = items
            return
        }

        guard let currentCity = LocationManager.sharedInstance.currentCity else {
            return
        }

        filteredItemsByLocation = items.filter { $0.city.localizedCaseInsensitiveContains(currentCity) }

    }

    func filterItemsBySearch() {
        filteredItemsBySearch = searchText.isEmpty ? filteredItemsByLocation :  filteredItemsByLocation.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func isCurrentUserItem(_ item: ListItem) -> Bool {
        // Check if the item belongs to the current user (based on email or any other unique identifier)
        return item.userId == authManager.currentUser?.email
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(.white)
        .cornerRadius(8)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
