import SwiftUI
import MapKit

struct EnhancedSearchModal: View {
    @Binding var isPresented: Bool
    @Binding var mapState: MapViewState
    @ObservedObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var searchText = ""
    @State private var showQuickDestinations = true
    
    private let quickDestinations = [
        QuickDestination(title: "Home", icon: "house.fill", color: .blue),
        QuickDestination(title: "Work", icon: "briefcase.fill", color: .green),
        QuickDestination(title: "Gym", icon: "dumbbell.fill", color: .purple),
        QuickDestination(title: "Grocery Store", icon: "cart.fill", color: .orange),
        QuickDestination(title: "Coffee Shop", icon: "cup.and.saucer.fill", color: .brown),
        QuickDestination(title: "Gas Station", icon: "fuelpump.fill", color: .red)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.secondaryText)
                        
                        TextField("Search destinations...", text: $searchText)
                            .font(.system(size: 18, weight: .medium))
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { _, newValue in
                                locationViewModel.queryFragment = newValue
                                showQuickDestinations = newValue.isEmpty
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                locationViewModel.queryFragment = ""
                                showQuickDestinations = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeManager.currentTheme.secondaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(themeManager.currentTheme.searchBarBackground)
                    .cornerRadius(12)
                    .themedBorder(themeManager.currentTheme)
                    .themedShadow(themeManager.currentTheme)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(themeManager.currentTheme.secondaryBackground)
                
                // Content
                if showQuickDestinations {
                    QuickDestinationsView(
                        destinations: quickDestinations,
                        onDestinationSelected: { destination in
                            // Handle quick destination selection
                            print("Selected: \(destination.title)")
                        }
                    )
                    .themedBackground(themeManager.currentTheme)
                } else {
                    SearchResultsView(
                        results: locationViewModel.results,
                        onResultSelected: { result in
                            locationViewModel.selectLocation(result)
                            mapState = .locationSelected
                            isPresented = false
                        }
                    )
                    .themedBackground(themeManager.currentTheme)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .themedAccentText(themeManager.currentTheme),
                
                trailing: Button("Done") {
                    isPresented = false
                }
                .themedAccentText(themeManager.currentTheme)
            )
        }
        .themedBackground(themeManager.currentTheme)
    }
}

// MARK: - Quick Destinations View
struct QuickDestinationsView: View {
    let destinations: [QuickDestination]
    let onDestinationSelected: (QuickDestination) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Destinations")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themedText(themeManager.currentTheme)
                
                Text("Tap to set your frequently visited places")
                    .font(.subheadline)
                    .themedSecondaryText(themeManager.currentTheme)
            }
            .padding(.horizontal, 20)
            
            // Quick Destination Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(destinations, id: \.title) { destination in
                    QuickDestinationCard(
                        destination: destination,
                        onTap: { onDestinationSelected(destination) }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - Quick Destination Card
struct QuickDestinationCard: View {
    let destination: QuickDestination
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: destination.icon)
                    .font(.title)
                    .foregroundColor(destination.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(destination.color.opacity(0.1))
                    )
                
                Text(destination.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .themedText(themeManager.currentTheme)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(themeManager.currentTheme.tertiaryBackground)
            .cornerRadius(16)
            .themedBorder(themeManager.currentTheme)
            .themedShadow(themeManager.currentTheme)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [MKLocalSearchCompletion]
    let onResultSelected: (MKLocalSearchCompletion) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themedText(themeManager.currentTheme)
                
                Text("\(results.count) location\(results.count == 1 ? "" : "s") found")
                    .font(.subheadline)
                    .themedSecondaryText(themeManager.currentTheme)
            }
            .padding(.horizontal, 20)
            
            // Results List
            if results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                    
                    Text("No results found")
                        .font(.headline)
                        .themedText(themeManager.currentTheme)
                    
                    Text("Try adjusting your search terms")
                        .font(.subheadline)
                        .themedSecondaryText(themeManager.currentTheme)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .themedBackground(themeManager.currentTheme)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results, id: \.self) { result in
                            SearchResultRow(
                                result: result,
                                onTap: { onResultSelected(result) }
                            )
                            
                            if result != results.last {
                                Divider()
                                    .background(themeManager.currentTheme.dividerColor)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(themeManager.currentTheme.secondaryBackground)
                    .cornerRadius(16)
                    .themedShadow(themeManager.currentTheme)
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: MKLocalSearchCompletion
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location Icon
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                
                // Location Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .themedText(themeManager.currentTheme)
                        .lineLimit(1)
                    
                    Text(result.subtitle)
                        .font(.caption)
                        .themedSecondaryText(themeManager.currentTheme)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Destination Model
struct QuickDestination {
    let title: String
    let icon: String
    let color: Color
}

#Preview {
    EnhancedSearchModal(
        isPresented: .constant(true),
        mapState: .constant(.noInput),
        locationViewModel: LocationSearchViewModel(locationManager: LocationManager())
    )
    .environmentObject(ThemeManager.shared)
}
