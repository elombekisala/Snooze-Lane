import SwiftUI
import MapKit
import CoreLocation

struct Home: View {
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windowSharedModel: WindowSharedModel
    
    @State private var mapState: MapViewState = .noInput
    @State private var alarmDistance: Double = 482.81
    @State private var showSearchModal = false
    @State private var showAddDestinationModal = false
    @State private var showEditDestinationModal = false
    @State private var editingDestination: QuickDestinationItem?
    
    // Quick destinations data
    @State private var quickDestinations: [QuickDestinationItem] = []
    
        var body: some View {
        ZStack {
            // Map View
            MapView(mapState: $mapState, alarmDistance: $alarmDistance, showLocationSearch: .constant(false))
                .ignoresSafeArea()
            
            // Top Status Bar
            topStatusBar
            
            // Search Button
            searchButton
            
            // Bottom Destination Info
            bottomDestinationInfo
        }
        .onAppear {
            loadQuickDestinations()
        }
        .sheet(isPresented: $showSearchModal) {
            searchModalView
        }
        
        // Add/Edit Quick Destination Modal
        .sheet(isPresented: $showAddDestinationModal) {
            BasicQuickDestinationEditView(
                quickDestinations: $quickDestinations,
                editingDestination: editingDestination
            )
        }
        
        // Edit Quick Destination Modal
        .sheet(isPresented: $showEditDestinationModal) {
            BasicQuickDestinationEditView(
                quickDestinations: $quickDestinations,
                editingDestination: editingDestination
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var topStatusBar: some View {
        VStack {
            HStack {
                // Left side - Time and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date(), style: .time)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Snooze Lane")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Right side - Settings and profile
                HStack(spacing: 16) {
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                                            Button(action: {
                            // TODO: Implement sign out
                        }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
        }
    }
    
    private var searchButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    showSearchModal = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Search Destinations")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(25)
                    .shadow(radius: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
    }
    
    private var bottomDestinationInfo: some View {
        VStack {
            Spacer()
            
            if mapState == .locationSelected {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text("Destination Selected")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            // Set alarm action
                        }) {
                            Text("Set Alarm")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.red)
                                .cornerRadius(20)
                        }
                    }
                    
                    if let distance = locationViewModel.distance {
                        Text("Distance: \(String(format: "%.1f", distance)) km")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: mapState)
            }
        }
    }
    
    private var searchModalView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Search Destinations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    showSearchModal = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, 12)

                TextField("Search destinations...", text: $locationViewModel.queryFragment)
                    .font(.system(size: 18, weight: .medium))
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)

                if !locationViewModel.queryFragment.isEmpty {
                    Button(action: {
                        locationViewModel.queryFragment = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 12)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)

            // Quick Destinations or Search Results
            if locationViewModel.queryFragment.isEmpty {
                quickDestinationsView
            } else {
                searchResultsView
            }
        }
        .background(Color.black)
        .presentationDetents([.medium, .large])
    }
    
    private var quickDestinationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Destinations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    editingDestination = nil // Clear any editing state
                    showAddDestinationModal = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            // Quick Destinations List with Edit/Delete
            ForEach(quickDestinations, id: \.id) { destination in
                QuickDestinationButton(
                    title: destination.title,
                    subtitle: destination.subtitle,
                    icon: destination.icon,
                    color: destination.color
                ) {
                    // Set destination coordinates
                    let coordinate = CLLocationCoordinate2D(
                        latitude: destination.latitude,
                        longitude: destination.longitude
                    )
                    handleDestinationSelected(coordinate: coordinate, title: destination.title)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Edit button
                    Button(action: {
                        editingDestination = destination
                        showEditDestinationModal = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    // Delete button
                    Button(role: .destructive, action: {
                        deleteQuickDestination(destination)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(locationViewModel.results, id: \.self) { result in
                    LocationSearchResultsCell(
                        title: result.title,
                        subtitle: result.subtitle,
                        coordinate: locationViewModel.getCoordinateForResult(result) ?? CLLocationCoordinate2D()
                    )
                    .onTapGesture {
                        if let coordinate = locationViewModel.getCoordinateForResult(result) {
                            handleDestinationSelected(coordinate: coordinate, title: result.title)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleDestinationSelected(coordinate: CLLocationCoordinate2D, title: String) {
        // Close the search modal if it's open
        showSearchModal = false

        // Update the map state to show location details
        withAnimation(.easeInOut(duration: 0.3)) {
            mapState = .locationSelected
        }

        // Provide haptic feedback
        provideHapticFeedback()

        print("Destination selected: \(title) at \(coordinate)")
    }
    
    private func deleteQuickDestination(_ destination: QuickDestinationItem) {
        print("🗑️ Deleting quick destination: \(destination.title)")
        
        // Remove from the array
        quickDestinations.removeAll { $0.id == destination.id }
        
        // Provide haptic feedback
        provideHapticFeedback()
        
        // Save to UserDefaults
        saveQuickDestinationsToUserDefaults()
        
        print("✅ Quick destination deleted successfully")
    }
    
    private func loadQuickDestinations() {
        print("📱 Loading quick destinations from UserDefaults...")
        
        if let data = UserDefaults.standard.data(forKey: "savedQuickDestinations"),
           let decoded = try? JSONDecoder().decode([QuickDestinationItem].self, from: data) {
            quickDestinations = decoded
            print("✅ Loaded \(decoded.count) quick destinations from storage")
        } else {
            // Load default destinations if none saved
            quickDestinations = QuickDestinationItem.defaultDestinations
            print("📋 Using default quick destinations")
        }
    }
    
    private func saveQuickDestinationsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(quickDestinations) {
            UserDefaults.standard.set(encoded, forKey: "savedQuickDestinations")
            print("💾 Quick destinations saved to UserDefaults")
        }
    }
    
    private func provideHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Quick Destination Item
struct QuickDestinationItem: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let colorHex: String
    let latitude: Double
    let longitude: Double
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    init(title: String, subtitle: String, icon: String, color: Color, latitude: Double, longitude: Double) {
        self.id = UUID().uuidString
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.colorHex = color.toHex() ?? "#007AFF"
        self.latitude = latitude
        self.longitude = longitude
    }
    
    static let defaultDestinations: [QuickDestinationItem] = [
        QuickDestinationItem(
            title: "Home",
            subtitle: "123 Main St",
            icon: "house.fill",
            color: .blue,
            latitude: 37.7749,
            longitude: -122.4194
        ),
        QuickDestinationItem(
            title: "Work",
            subtitle: "456 Office Rd",
            icon: "briefcase.fill",
            color: .green,
            latitude: 37.7849,
            longitude: -122.4094
        ),
        QuickDestinationItem(
            title: "Gym",
            subtitle: "Fitness Center",
            icon: "dumbbell.fill",
            color: .purple,
            latitude: 37.7649,
            longitude: -122.4294
        ),
        QuickDestinationItem(
            title: "Grocery Store",
            subtitle: "Supermarket",
            icon: "cart.fill",
            color: .orange,
            latitude: 37.7549,
            longitude: -122.4394
        )
    ]
}

// MARK: - Color Extension for Hex Support
extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
    
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Basic Quick Destination Edit View
struct BasicQuickDestinationEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var quickDestinations: [QuickDestinationItem]
    
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var address: String = ""
    @State private var selectedIcon: String = "mappin.circle.fill"
    @State private var selectedColor: Color = .blue
    
    @State private var isSearching = false
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var showingLocationPicker = false
    
    // For editing existing destination
    let editingDestination: QuickDestinationItem?
    
    // Available icons and colors
    private let availableIcons = ["house.fill", "briefcase.fill", "dumbbell.fill", "cart.fill", "car.fill", "airplane", "mappin.circle.fill", "star.fill"]
    private let availableColors: [Color] = [.blue, .green, .purple, .orange, .red, .pink, .yellow, .gray]
    
    init(quickDestinations: Binding<[QuickDestinationItem]>, editingDestination: QuickDestinationItem? = nil) {
        self._quickDestinations = quickDestinations
        self.editingDestination = editingDestination
        
        // Initialize with existing data if editing
        if let destination = editingDestination {
            _title = State(initialValue: destination.title)
            _subtitle = State(initialValue: destination.subtitle)
            _address = State(initialValue: destination.subtitle) // Use subtitle as address
            _selectedIcon = State(initialValue: destination.icon)
            _selectedColor = State(initialValue: destination.color)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerView
                formView
                actionButtonsView
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingLocationPicker) {
            BasicLocationPickerView(
                searchResults: searchResults,
                selectedMapItem: $selectedMapItem,
                isPresented: $showingLocationPicker
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(editingDestination != nil ? "Edit Quick Destination" : "Add Quick Destination")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Enter the address and we'll find the coordinates")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top)
    }
    
    private var formView: some View {
        VStack(spacing: 16) {
            titleField
            addressField
            iconSelectionView
            colorSelectionView
            locationPreviewView
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("e.g., Home, Work, Gym", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.black)
        }
    }
    
    private var addressField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                TextField("Enter full address", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .foregroundColor(.black)
                
                Button(action: {
                    searchAddress()
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var iconSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: {
                        selectedIcon = icon
                    }) {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(selectedIcon == icon ? selectedColor : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var colorSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(availableColors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                            )
                    }
                }
            }
        }
    }
    
    private var locationPreviewView: some View {
        Group {
            if let selectedMapItem = selectedMapItem {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedMapItem.name ?? "Unknown Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(selectedMapItem.placemark.thoroughfare ?? "")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Lat: \(selectedMapItem.placemark.coordinate.latitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Lon: \(selectedMapItem.placemark.coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                saveQuickDestination()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(editingDestination != nil ? "Update Destination" : "Add Destination")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    selectedMapItem != nil ? Color.green : Color.gray
                )
                .cornerRadius(12)
            }
            .disabled(selectedMapItem != nil || title.isEmpty)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Private Methods
    
    private func searchAddress() {
        guard !address.isEmpty else { return }
        
        print("🔍 Searching for address: \(address)")
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        request.resultTypes = .address
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    print("❌ Address search error: \(error.localizedDescription)")
                    return
                }
                
                if let response = response {
                    searchResults = response.mapItems
                    print("✅ Found \(searchResults.count) search results")
                    
                    if !searchResults.isEmpty {
                        showingLocationPicker = true
                    }
                }
            }
        }
    }
    
    private func saveQuickDestination() {
        guard let selectedMapItem = selectedMapItem else { return }
        
        let coordinate = selectedMapItem.placemark.coordinate
        let newDestination = QuickDestinationItem(
            title: title,
            subtitle: subtitle.isEmpty ? address : subtitle,
            icon: selectedIcon,
            color: selectedColor,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        
        print("💾 Saving quick destination:")
        print("   Title: \(newDestination.title)")
        print("   Address: \(newDestination.subtitle)")
        print("   Coordinates: (\(coordinate.latitude), \(coordinate.longitude))")
        print("   Icon: \(newDestination.icon)")
        print("   Color: \(newDestination.color)")
        
        if editingDestination != nil {
            // Update existing destination
            if let index = quickDestinations.firstIndex(where: { $0.id == editingDestination!.id }) {
                quickDestinations[index] = newDestination
                print("✅ Quick destination updated successfully")
            }
        } else {
            // Add new destination
            quickDestinations.append(newDestination)
            print("✅ Quick destination added successfully")
        }
        
        // Save to UserDefaults for persistence
        saveToUserDefaults()
        
        print("💾 Saved to local storage")
        
        DispatchQueue.main.async {
            dismiss()
        }
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(quickDestinations) {
            UserDefaults.standard.set(encoded, forKey: "savedQuickDestinations")
            print("💾 Quick destinations saved to UserDefaults")
        }
    }
}

// MARK: - Basic Location Picker View
struct BasicLocationPickerView: View {
    let searchResults: [MKMapItem]
    @Binding var selectedMapItem: MKMapItem?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List(searchResults, id: \.self) { mapItem in
                Button(action: {
                    selectedMapItem = mapItem
                    isPresented = false
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mapItem.name ?? "Unknown Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(mapItem.placemark.thoroughfare ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(mapItem.placemark.coordinate.latitude, specifier: "%.6f"), \(mapItem.placemark.coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Quick Destination Button
struct QuickDestinationButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(LocationSearchViewModel(locationManager: LocationManager()))
            .environmentObject(
                TripProgressViewModel(
                    locationViewModel: LocationSearchViewModel(locationManager: LocationManager()))
            )
            .environmentObject(LoginViewModel())
            .environmentObject(LocationManager())
            .environmentObject(WindowSharedModel())
    }
}
