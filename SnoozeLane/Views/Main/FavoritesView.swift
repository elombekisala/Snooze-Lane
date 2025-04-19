/*
import MapKit
import SwiftUI
import FirebaseFirestore

struct FavoritesView: View {
    @Bindable var favoritesManager: FavoritesManager
    @Bindable var locationManager: LocationManager
    @Bindable var locationViewModel: LocationSearchViewModel
    @Bindable var windowSharedModel: WindowSharedModel
    @Binding var mapState: MapViewState
    @State private var showingDeleteAlert = false
    @State private var selectedFavorite: FavoriteDestination?
    @State private var searchText = ""
    @State private var isAddingFavorite = false
    @State private var selectedLocation: SnoozeLaneLocation?

    init(
        locationViewModel: LocationSearchViewModel,
        windowSharedModel: WindowSharedModel,
        mapState: Binding<MapViewState>
    ) {
        self.favoritesManager = FavoritesManager.shared
        self.locationManager = LocationManager.shared
        self.locationViewModel = locationViewModel
        self.windowSharedModel = windowSharedModel
        self._mapState = mapState
    }

    var filteredFavorites: [FavoriteDestination] {
        if searchText.isEmpty {
            return favoritesManager.favorites
        } else {
            return favoritesManager.favorites.filter { favorite in
                favorite.name.localizedCaseInsensitiveContains(searchText) ||
                favorite.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search favorites...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // Favorites List
            if filteredFavorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites",
                    systemImage: "star.slash",
                    description: Text("Add locations to your favorites to quickly access them later.")
                )
            } else {
                List {
                    ForEach(filteredFavorites) { favorite in
                        FavoriteRow(favorite: favorite)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        try? await favoritesManager.removeFavorite(favorite.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding()
    }
}

struct FavoriteRow: View {
    let favorite: FavoriteDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(favorite.name)
                .font(.headline)

            Text(favorite.address)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    @MainActor func createPreview() -> FavoritesView {
        let locationManager = LocationManager.shared
        let locationViewModel = LocationSearchViewModel(locationManager: locationManager)
        let windowSharedModel = WindowSharedModel()

        return FavoritesView(
            locationViewModel: locationViewModel,
            windowSharedModel: windowSharedModel,
            mapState: .constant(.noInput)
        )
    }
    return createPreview()
}
*/
