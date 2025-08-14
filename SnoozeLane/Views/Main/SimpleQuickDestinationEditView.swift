import SwiftUI
import MapKit

struct SimpleQuickDestinationEditView: View {
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
                // Header
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
                
                // Form
                VStack(spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("e.g., Home, Work, Gym", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                    }
                    
                    // Address
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
                    
                    // Icon Selection
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
                    
                    // Color Selection
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
                    
                    // Selected Location Preview
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
                                
                                if let placemark = selectedMapItem.placemark {
                                    Text(placemark.thoroughfare ?? "")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Lat: \(placemark.coordinate.latitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Lon: \(placemark.coordinate.longitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        saveQuickDestination()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(editingDestination != nil ? "Update Destination" : "Save Destination")
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
                    .disabled(selectedMapItem == nil || title.isEmpty)
                    
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
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(
                searchResults: searchResults,
                selectedMapItem: $selectedMapItem,
                isPresented: $showingLocationPicker
            )
        }
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
        
        let coordinate = selectedMapItem.coordinate
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

// MARK: - Location Picker View
struct LocationPickerView: View {
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
                        
                        if let placemark = mapItem.placemark {
                            Text(placemark.thoroughfare ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(placemark.coordinate.latitude, specifier: "%.6f"), \(placemark.coordinate.longitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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

#Preview {
    SimpleQuickDestinationEditView(
        quickDestinations: .constant(QuickDestinationItem.defaultDestinations)
    )
    .background(Color.black)
}
