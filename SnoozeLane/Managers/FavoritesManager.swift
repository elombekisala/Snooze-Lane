/*
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

@MainActor
@Observable final class FavoritesManager {
    private(set) var favorites: [FavoriteDestination] = []
    @MainActor private var listener: ListenerRegistration?
    private let db: Firestore
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "savedFavorites"

    static let shared = FavoritesManager()

    init() {
        db = Firestore.firestore()
        loadLocalFavorites()
        syncWithFirebase()
    }

    deinit {
        Task { @MainActor in
            listener?.remove()
        }
    }

    // MARK: - Public Methods

    func addFavorite(_ location: SnoozeLaneLocation) async throws {
        let favorite = FavoriteDestination(
            id: UUID().uuidString,
            title: location.title ?? "Unnamed Location",
            subtitle: location.subtitle ?? "",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            isFavorite: true
        )

        // Add to local array
        favorites.append(favorite)

        // Save locally
        saveLocalFavorites()

        // Save to Firebase if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            try await saveFavoriteToFirebase(favorite, userId: userId)
        }
    }

    func removeFavorite(_ favoriteId: String) async throws {
        // Remove from local array
        favorites.removeAll { $0.id == favoriteId }

        // Save locally
        saveLocalFavorites()

        // Remove from Firebase if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            try await removeFavoriteFromFirebase(favoriteId, userId: userId)
        }
    }

    func isFavorite(_ location: SnoozeLaneLocation) -> Bool {
        favorites.contains { favorite in
            abs(favorite.latitude - location.coordinate.latitude) < 0.0001
                && abs(favorite.longitude - location.coordinate.longitude) < 0.0001
        }
    }

    // MARK: - Private Methods

    private func loadLocalFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
            let decoded = try? JSONDecoder().decode([FavoriteDestination].self, from: data)
        {
            favorites = decoded
        }
    }

    private func saveLocalFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            userDefaults.set(encoded, forKey: favoritesKey)
        }
    }

    private func syncWithFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Listen for real-time updates
        listener = db.collection("users").document(userId).collection("favorites")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    print(
                        "Error fetching favorites: \(error?.localizedDescription ?? "Unknown error")"
                    )
                    return
                }

                // Update local favorites from Firebase
                var newFavorites: [FavoriteDestination] = []
                for document in snapshot.documents {
                    let data = document.data()
                    let favorite = FavoriteDestination(
                        id: document.documentID,
                        title: data["title"] as? String ?? "",
                        subtitle: data["subtitle"] as? String ?? "",
                        latitude: data["latitude"] as? Double ?? 0,
                        longitude: data["longitude"] as? Double ?? 0,
                        isFavorite: true
                    )
                    newFavorites.append(favorite)
                }

                self.favorites = newFavorites
                self.saveLocalFavorites()
            }
    }

    private func saveFavoriteToFirebase(_ favorite: FavoriteDestination, userId: String)
        async throws
    {
        try await db.collection("users").document(userId).collection("favorites")
            .document(favorite.id).setData([
                "title": favorite.title,
                "subtitle": favorite.subtitle,
                "latitude": favorite.latitude,
                "longitude": favorite.longitude,
                "isFavorite": favorite.isFavorite,
            ])
    }

    private func removeFavoriteFromFirebase(_ favoriteId: String, userId: String) async throws {
        try await db.collection("users").document(userId).collection("favorites")
            .document(favoriteId).delete()
    }
}
*/
