//
//  ProgressViewModel.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import AVFoundation
import AudioToolbox
import Combine
import CoreLocation
import Firebase
import FirebaseAppCheck
import FirebaseFunctions
import Foundation
import UserNotifications

final class TripProgressViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    private let locationManager = LocationManager.shared
    private let locationViewModel: LocationSearchViewModel
    private let twilioService = TwilioService()

    private var cancellables = Set<AnyCancellable>()
    var destination: CLLocation?

    @Published private(set) var callMade: Bool = false
    @Published var hasReachedDestination = false
    @Published var selectedSound: Sound?
    @Published var currentLocation: CLLocation?
    @Published var initialLocation: CLLocation?
    @Published var estimatedRestTime: TimeInterval?
    @Published var isStarted = false
    @Published var isFinished = false
    @Published var progress: Double = 0.0
    @Published var distance: Double = 0.0
    @Published var alarmDistanceThreshold: Double = 1609.34
    @Published var tripCompleted: Bool = false

    private var callInProgress = false
    private var notificationAuthorized = false

    init(locationViewModel: LocationSearchViewModel) {
        self.locationViewModel = locationViewModel

        // Initialize with default values from UserDefaults
        let savedRadius = UserDefaults.standard.double(forKey: "defaultAlarmRadiusMeters")
        if savedRadius > 0 {
            self.alarmDistanceThreshold = savedRadius
            print("🚀 TripProgressViewModel initialized - Alarm radius loaded: \(savedRadius)m")
        } else {
            self.alarmDistanceThreshold = 500  // Default to 500m if not set
            print("🚀 TripProgressViewModel initialized - Alarm radius set to default: 500m")
        }

        super.init()

        self.setupLocationUpdates()
        self.authorizeNotification()

        // Listen for alarm distance changes from settings
        NotificationCenter.default.addObserver(
            forName: .alarmDistanceChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let radius = notification.userInfo?["radius"] as? Double {
                self?.alarmDistanceThreshold = radius
                print("🔔 Alarm distance threshold updated to: \(radius)m")
            }
        }

        print("Initial status of callMade: \(callMade)")
    }

    // MARK: Requesting Notification Access
    func authorizeNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) {
            [weak self] granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            } else {
                print("Notification authorization granted: \(granted)")
                self?.notificationAuthorized = granted
            }
        }

        // Assign delegate
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        completionHandler([.sound, .banner, .list, .badge])
        print("Notification will present: \(notification.request.content.title)")
    }

    func getDestination() -> CLLocation? {
        return destination
    }

    func setDestination(_ destination: CLLocation) {
        self.destination = destination
        print(
            "🎯 Destination set in TripProgressViewModel: \(destination.coordinate.latitude), \(destination.coordinate.longitude)"
        )
    }

    private func setupLocationUpdates() {
        locationManager.$location.sink { [weak self] location in
            guard let self = self, let location = location else { return }
            self.currentLocation = location
            self.updateDistance(location: location)
        }
        .store(in: &cancellables)

        // Listen for distance updates from LocationSearchViewModel
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(distanceUpdated),
            name: .distanceUpdated,
            object: nil
        )
    }

    @objc func distanceUpdated(_ notification: Notification) {
        guard let newDistance = notification.object as? Double else { return }
        distance = newDistance
        updateProgress()
    }

    private func updateDistance(location: CLLocation) {
        guard isStarted, let destination = destination else { return }

        distance = location.distance(from: destination)
        updateProgress()
    }

    func startTrip() {
        print("🚀 START TRIP FUNCTION CALLED.")
        initialLocation = currentLocation

        // Set the destination from the selected location
        if let selectedLocation = locationViewModel.selectedSnoozeLaneLocation {
            let destinationCoordinate = selectedLocation.coordinate
            destination = CLLocation(
                latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude
            )
            print(
                "🎯 Destination set for trip: \(destinationCoordinate.latitude), \(destinationCoordinate.longitude)"
            )
        } else {
            print("⚠️ No destination selected for trip")
        }

        isStarted = true
        locationManager.startUpdatingLocation()
    }

    private func updateProgress() {
        guard let currentLocation = currentLocation, let destination = destination,
            !hasReachedDestination
        else {
            print(
                "⚠️ Update progress guard failed - currentLocation: \(currentLocation != nil), destination: \(destination != nil), hasReachedDestination: \(hasReachedDestination)"
            )
            return
        }

        let currentDistance = currentLocation.distance(from: destination)
        let distanceToThreshold = max(0, currentDistance - alarmDistanceThreshold)

        print("📍 Current distance: \(currentDistance)m, Threshold: \(alarmDistanceThreshold)m")

        // Progress is calculated based on the distance to the threshold
        let totalThresholdDistance = max(
            currentLocation.distance(from: destination), alarmDistanceThreshold)
        progress = 1 - (distanceToThreshold / totalThresholdDistance)

        // Ensure the progress is within the range of 0 to 1
        progress = max(0, min(progress, 1))

        // Progress calculation only - threshold detection is handled by checkThresholdReached
        // This prevents duplicate call triggering
        if currentDistance <= alarmDistanceThreshold && !hasReachedDestination {
            print("📍 Progress update: Within threshold but not yet processed")
        }
    }

    func triggerNotification() {
        guard notificationAuthorized else {
            print("⚠️ Notifications not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Wake up! You're almost there!"
        content.body = "You're approaching your stop📍"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: trigger)

        // Check if the app is in the background or foreground
        DispatchQueue.main.async {
            let state = UIApplication.shared.applicationState
            if state == .active {
                print("App is in foreground, showing alert instead of notification.")
                self.showForegroundAlert(content: content)
            } else {
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    } else {
                        print("Notification scheduled successfully")
                    }
                }
            }
        }
    }

    private func showForegroundAlert(content: UNMutableNotificationContent) {
        let alert = UIAlertController(
            title: content.title, message: content.body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alert, animated: true, completion: nil)
        }
    }

    func triggerCall(retryCount: Int = 0) {
        guard !callInProgress else {
            print("📞 Call already in progress, skipping...")
            return
        }

        print("📞 Initiating call function (attempt \(retryCount + 1))")
        print(
            "📞 Current state - callMade: \(callMade), hasReachedDestination: \(hasReachedDestination)"
        )
        callInProgress = true

        let functions = Functions.functions()
        print("📞 Calling Firebase function 'makeCallOnTrigger'...")

        functions.httpsCallable("makeCallOnTrigger").call { result, error in
            self.callInProgress = false
            if let error = error {
                print("❌ Error calling Firebase function: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                if retryCount < 3 {  // Retry logic with up to 3 retries
                    print("📞 Retrying call in 2 seconds... (attempt \(retryCount + 2))")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        self.triggerCall(retryCount: retryCount + 1)
                    }
                } else {
                    print("❌ Call failed after \(retryCount + 1) attempts")
                }
            } else {
                print("✅ Firebase function call succeeded!")
                print("✅ Result data: \(result?.data ?? "No data")")
                self.callMade = true
                self.incrementCallCount()
            }
        }
    }

    func incrementCallCount() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("Users").document(userID)

        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldCallCount = userDocument.data()?["CallCount"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain", code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Unable to retrieve call count from snapshot \(userDocument)"
                    ])
                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(["CallCount": oldCallCount + 1], forDocument: userRef)
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                print("Transaction successfully committed!")
            }
        }
    }

    func stopTrip() {
        isStarted = false
        callMade = false
        locationManager.stopUpdatingLocation()
        resetTripProgress()
        // Clear map overlays
        NotificationCenter.default.post(name: .clearMapOverlays, object: nil)
        print("STOP TRIP FUNCTION CALLED.")
    }

    func resetTripProgress() {
        hasReachedDestination = false
        progress = 0
        distance = 0
        callInProgress = false
        currentLocation = nil
        destination = nil
        initialLocation = nil
        tripCompleted = false
        print("RESET TRIP PROGRESS FUNCTION CALLED.")
    }

    func resetTrip() {
        print("🔄 Resetting trip state")
        resetTripProgress()
        isStarted = false
        print("✅ Trip reset successfully")
    }

    func startNewTrip() {
        // Reset everything for a fresh start
        resetTripProgress()
        // Clear map overlays
        NotificationCenter.default.post(name: .clearMapOverlays, object: nil)
    }

    func updateAlarmDistanceThreshold(_ newRadius: Double) {
        print("🔔 Manually updating alarm distance threshold to: \(newRadius)m")
        alarmDistanceThreshold = newRadius
        print("✅ Alarm distance threshold updated")
    }

    private func cancelDestinationNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "BannerNotification", "AlertNotification",
        ])
    }

    // MARK: - Threshold Detection
    func checkThresholdReached(distance: Double) {
        print("🔍 checkThresholdReached called with distance: \(distance)m")
        print(
            "🔍 Current state - hasReachedDestination: \(hasReachedDestination), destination: \(destination != nil), callMade: \(callMade)"
        )

        // Only check destination exists - allow multiple threshold checks
        guard let destination = destination else {
            print(
                "⚠️ Threshold check guard failed - destination is nil"
            )
            return
        }

        print(
            "🎯 Destination coordinates: \(destination.coordinate.latitude), \(destination.coordinate.longitude)"
        )

        // Use the user's configured alarm distance as the threshold, not the hardcoded value
        // This ensures the Firebase function triggers at the user's chosen distance
        let userAlarmDistance = UserDefaults.standard.double(forKey: "defaultAlarmRadiusMeters")
        let threshold = userAlarmDistance > 0 ? userAlarmDistance : 500.0  // Fallback to 500m if not set

        print("🎯 Threshold check - Distance: \(distance)m, User's Alarm Distance: \(threshold)m")

        if distance <= threshold {
            print(
                "🎯 Distance threshold reached! Current: \(distance)m, Threshold: \(threshold)m"
            )

            // Check if we should trigger the Firebase function
            if !callMade {
                print("📞 Call not yet made, triggering call function...")
                print("📞 FIREBASE FUNCTION WILL BE CALLED NOW!")
                
                // Mark that we've reached the destination
                hasReachedDestination = true
                
                // Trigger notification and call
                triggerNotification()
                triggerCall()
                
                // Don't stop the trip yet - let it continue monitoring
                // The user might move in and out of the threshold
                print("📞 Firebase function triggered, continuing to monitor...")
                
            } else if callInProgress {
                print("📞 Call already in progress, waiting...")
            } else {
                print("📞 Call already made successfully, threshold monitoring continues...")
            }
        } else {
            print("🎯 Distance \(distance)m still above threshold \(threshold)m")
        }
    }
}
