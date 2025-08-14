import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
@Observable final class QuickDestinationsManager {
    private(set) var quickDestinations: [QuickDestination] = []
    private var listener: ListenerRegistration?
    private let db: Firestore
    private let userDefaults = UserDefaults.standard
    private let quickDestinationsKey = "savedQuickDestinations"

    static let shared = QuickDestinationsManager()

    init() {
        db = Firestore.firestore()
        loadLocalQuickDestinations()
        syncWithFirebase()
    }

    deinit {
        Task { @MainActor in
            listener?.remove()
        }
    }

    // MARK: - Public Methods

    func addQuickDestination(_ destination: QuickDestination) async throws {
        // Add to local array
        quickDestinations.append(destination)

        // Save locally
        saveLocalQuickDestinations()

        // Save to Firebase if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            try await saveQuickDestinationToFirebase(destination, userId: userId)
        }
    }

    func updateQuickDestination(_ destination: QuickDestination) async throws {
        // Update in local array
        if let index = quickDestinations.firstIndex(where: { $0.id == destination.id }) {
            quickDestinations[index] = destination

            // Save locally
            saveLocalQuickDestinations()

            // Update in Firebase if user is logged in
            if let userId = Auth.auth().currentUser?.uid {
                try await saveQuickDestinationToFirebase(destination, userId: userId)
            }
        }
    }

    func removeQuickDestination(_ destinationId: String) async throws {
        // Remove from local array
        quickDestinations.removeAll { $0.id == destinationId }

        // Save locally
        saveLocalQuickDestinations()

        // Remove from Firebase if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            try await removeQuickDestinationFromFirebase(destinationId, userId: userId)
        }
    }

    func getQuickDestination(by id: String) -> QuickDestination? {
        return quickDestinations.first { $0.id == id }
    }

    func getQuickDestinations(by category: QuickDestinationCategory) -> [QuickDestination] {
        return quickDestinations.filter { $0.category == category }
    }

    func initializeDefaultDestinations() {
        // Only initialize if no destinations exist
        if quickDestinations.isEmpty {
            quickDestinations = QuickDestination.defaultDestinations
            saveLocalQuickDestinations()
        }
    }

    func reorderDestinations(_ destinations: [QuickDestination]) {
        quickDestinations = destinations
        saveLocalQuickDestinations()

        // Update Firebase if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            Task {
                try await syncAllToFirebase(userId: userId)
            }
        }
    }

    // MARK: - Private Methods

    private func loadLocalQuickDestinations() {
        if let data = userDefaults.data(forKey: quickDestinationsKey),
            let decoded = try? JSONDecoder().decode([QuickDestination].self, from: data)
        {
            quickDestinations = decoded
        } else {
            // Initialize with default destinations if none exist
            initializeDefaultDestinations()
        }
    }

    private func saveLocalQuickDestinations() {
        if let encoded = try? JSONEncoder().encode(quickDestinations) {
            userDefaults.set(encoded, forKey: quickDestinationsKey)
        }
    }

    private func syncWithFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Listen for real-time updates
        listener = db.collection("users").document(userId).collection("quickDestinations")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    print(
                        "Error fetching quick destinations: \(error?.localizedDescription ?? "Unknown error")"
                    )
                    return
                }

                // Update local quick destinations from Firebase
                var newQuickDestinations: [QuickDestination] = []
                for document in snapshot.documents {
                    let data = document.data()
                    if let destination = self.quickDestinationFromFirebaseData(
                        data, id: document.documentID)
                    {
                        newQuickDestinations.append(destination)
                    }
                }

                // Only update if we have destinations from Firebase
                if !newQuickDestinations.isEmpty {
                    self.quickDestinations = newQuickDestinations
                    self.saveLocalQuickDestinations()
                }
            }
    }

    private func quickDestinationFromFirebaseData(_ data: [String: Any], id: String)
        -> QuickDestination?
    {
        guard let title = data["title"] as? String,
            let subtitle = data["subtitle"] as? String,
            let latitude = data["latitude"] as? Double,
            let longitude = data["longitude"] as? Double,
            let icon = data["icon"] as? String,
            let colorHex = data["colorHex"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = QuickDestinationCategory(rawValue: categoryRaw)
        else {
            return nil
        }

        return QuickDestination(
            id: id,
            title: title,
            subtitle: subtitle,
            latitude: latitude,
            longitude: longitude,
            icon: icon,
            colorHex: colorHex,
            category: category
        )
    }

    private func saveQuickDestinationToFirebase(_ destination: QuickDestination, userId: String)
        async throws
    {
        try await db.collection("users").document(userId).collection("quickDestinations")
            .document(destination.id).setData([
                "title": destination.title,
                "subtitle": destination.subtitle,
                "latitude": destination.latitude,
                "longitude": destination.longitude,
                "icon": destination.icon,
                "colorHex": destination.colorHex,
                "category": destination.category.rawValue,
            ])
    }

    private func removeQuickDestinationFromFirebase(_ destinationId: String, userId: String)
        async throws
    {
        try await db.collection("users").document(userId).collection("quickDestinations")
            .document(destinationId).delete()
    }

    private func syncAllToFirebase(_ userId: String) async throws {
        // Remove all existing documents
        let snapshot = try await db.collection("users").document(userId).collection(
            "quickDestinations"
        ).getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }

        // Add all current destinations
        for destination in quickDestinations {
            try await saveQuickDestinationToFirebase(destination, userId: userId)
        }
    }
}
