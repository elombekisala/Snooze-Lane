import SwiftUI
import MapKit
import CoreLocation

struct QuickDestinationEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var quickDestinationsManager: QuickDestinationsManager
    
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var address: String = ""
    @State private var selectedCategory: QuickDestinationCategory = .other
    @State private var selectedIcon: String = "mappin.circle.fill"
    @State private var selectedColorHex: String = "#007AFF"
    
    @State private var isSearching = false
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var showingLocationPicker = false
    
    // For editing existing destination
    let editingDestination: QuickDestination?
    
    init(quickDestinationsManager: QuickDestinationsManager, editingDestination: QuickDestination? = nil) {
        self.quickDestinationsManager = quickDestinationsManager
        self.editingDestination = editingDestination
        
        // Initialize with existing data if editing
        if let destination = editingDestination {
            _title = State(initialValue: destination.title)
            _subtitle = State(initialValue: destination.subtitle)
            _address = State(initialValue: destination.subtitle) // Use subtitle as address
            _selectedCategory = State(initialValue: destination.category)
            _selectedIcon = State(initialValue: destination.icon)
            _selectedColorHex = State(initialValue: destination.colorHex)
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
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(QuickDestinationCategory.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    // Icon and Color
                    HStack(spacing: 20) {
                        // Icon Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                // TODO: Show icon picker
                                print("Icon picker tapped")
                            }) {
                                Image(systemName: selectedIcon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color(hex: selectedColorHex) ?? .blue)
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                // TODO: Show color picker
                                print("Color picker tapped")
                            }) {
                                Circle()
                                    .fill(Color(hex: selectedColorHex) ?? .blue)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
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
        let newDestination = QuickDestination(
            id: editingDestination?.id ?? UUID().uuidString,
            title: title,
            subtitle: subtitle.isEmpty ? address : subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            category: selectedCategory
        )
        
        print("💾 Saving quick destination:")
        print("   Title: \(newDestination.title)")
        print("   Address: \(newDestination.subtitle)")
        print("   Coordinates: (\(coordinate.latitude), \(coordinate.longitude))")
        print("   Category: \(newDestination.category.displayName)")
        
        Task {
            do {
                if editingDestination != nil {
                    try await quickDestinationsManager.updateQuickDestination(newDestination)
                    print("✅ Quick destination updated successfully")
                } else {
                    try await quickDestinationsManager.addQuickDestination(newDestination)
                    print("✅ Quick destination added successfully")
                }
                
                // Save to Firebase
                print("🔥 Syncing to Firebase database...")
                
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                print("❌ Error saving quick destination: \(error.localizedDescription)")
            }
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
    QuickDestinationEditView(quickDestinationsManager: QuickDestinationsManager.shared)
        .background(Color.black)
}
