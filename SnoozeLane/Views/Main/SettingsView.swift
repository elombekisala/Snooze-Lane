import Contacts
import ContactsUI
import Firebase
import LinkPresentation
import MapKit
import SwiftUI
import UIKit
import os.log

// Define the notification name
extension Notification.Name {
    static let callCountUpdated = Notification.Name("callCountUpdated")
}

// Add SettingsViewModel to manage state
class SettingsViewModel: ObservableObject {
    @Published private(set) var callCount: Int = 0
    @Published var isDarkModeEnabled: Bool = true  // Default to dark mode
    @Published var selectedMapType: String = "Standard"
    @Published var showTraffic: Bool = false
    @Published var units: String = "Miles"
    @Published var defaultAlarmRadius: Int = 500
    @Published var callTiming: String = "Immediate"

    private var observer: NSObjectProtocol?
    private let notificationCenter = NotificationCenter.default
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: "com.snoozelane.app", category: "Settings")

    init() {
        // Load saved settings from UserDefaults
        showTraffic = UserDefaults.standard.bool(forKey: "showTraffic")
        print("🚦 SettingsViewModel initialized - Traffic setting loaded: \(showTraffic ? "ON" : "OFF")")
        
        // Load units preference
        let savedUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
        units = savedUnits ? "Kilometers" : "Miles"
        print("📏 SettingsViewModel initialized - Units preference loaded: \(units)")
        
        // Load default alarm radius
        let savedRadius = UserDefaults.standard.double(forKey: "defaultAlarmRadiusMeters")
        if savedRadius > 0 {
            defaultAlarmRadius = Int(savedRadius)
            print("🔔 SettingsViewModel initialized - Default alarm radius loaded: \(defaultAlarmRadius)m")
        } else {
            // Set default if none saved
            defaultAlarmRadius = 500
            UserDefaults.standard.set(Double(defaultAlarmRadius), forKey: "defaultAlarmRadiusMeters")
            print("🔔 SettingsViewModel initialized - Default alarm radius set to default: \(defaultAlarmRadius)m")
        }
        
        setupObserver()
        fetchCallCount()
    }

    deinit {
        if let observer = observer {
            notificationCenter.removeObserver(observer)
        }
    }

    private func isUserLoggedIn() -> Bool {
        if let user = Auth.auth().currentUser {
            logger.debug("👤 User is logged in with ID: \(user.uid)")
            return true
        }
        logger.warning("⚠️ No user is currently logged in")
        return false
    }

    private func setupObserver() {
        logger.debug("🔄 Setting up call count observer")
        observer = notificationCenter.addObserver(
            forName: .callCountUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newCount = notification.userInfo?["count"] as? Int {
                self?.logger.notice("📢 Received call count update: \(newCount)")
                self?.callCount = newCount
            }
        }
    }

    func fetchCallCount() {
        guard isUserLoggedIn() else {
            logger.error("❌ Cannot fetch call count: User not logged in")
            return
        }

        let userID = Auth.auth().currentUser!.uid
        logger.debug("📊 Fetching call count for user: \(userID)")

        db.collection("Users").document(userID).getDocument { [weak self] document, error in
            if let error = error {
                self?.logger.error("❌ Error getting call count: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                if let count = document.data()?["CallCount"] as? Int {
                    DispatchQueue.main.async {
                        self?.logger.notice("📈 Initial call count fetched: \(count)")
                        self?.callCount = count
                    }
                }
            } else {
                self?.logger.warning("⚠️ No document found for user")
                // Initialize the call count for new users
                self?.initializeUserCallCount(userID: userID)
            }
        }
    }

    private func initializeUserCallCount(userID: String) {
        logger.debug("🆕 Initializing call count for new user: \(userID)")
        db.collection("Users").document(userID).setData([
            "CallCount": 0
        ]) { [weak self] error in
            if let error = error {
                self?.logger.error("❌ Error initializing call count: \(error.localizedDescription)")
            } else {
                self?.logger.notice("✅ Successfully initialized call count to 0")
                DispatchQueue.main.async {
                    self?.callCount = 0
                }
            }
        }
    }

    func resetCallCount() {
        guard isUserLoggedIn() else {
            logger.error("❌ Cannot reset call count: User not logged in")
            return
        }

        let userID = Auth.auth().currentUser!.uid
        logger.debug("🔄 Resetting call count for user: \(userID)")

        db.collection("Users").document(userID).updateData([
            "CallCount": 0
        ]) { [weak self] error in
            if let error = error {
                self?.logger.error("❌ Error resetting call count: \(error.localizedDescription)")
            } else {
                self?.logger.notice("✅ Successfully reset call count to 0")
                DispatchQueue.main.async {
                    self?.callCount = 0
                }
            }
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasCompletedWalkthrough") var hasCompletedWalkthrough: Bool = false
    @AppStorage("currentPage") var currentPage: Int = 1
    @AppStorage("useMetricUnits") var useMetricUnits: Bool = false
    @State private var isLoggingOut = false

    @State private var showingContactAddAlert = false
    @State private var showingSaveConfirmation = false
    @State private var showContactView = false
    @State private var savedContact: CNContact?
    @State private var showInstructions = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var showLocationPermissionsSheet = false
    @State private var showAddContactSheet = false

    let twilioPhoneNumber = "8557096502"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Contact Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                // Add Snooze Lane to contacts action
                                addSnoozeLaneToContacts()
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Add Snooze Lane to Contacts")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())
                        }
                        .padding(.horizontal)
                    }

                    // App Preferences Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("App Preferences")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 12) {

                            Button(action: {
                                // Show location permissions options
                                showLocationPermissionsOptions()
                            }) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Location Permissions")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(getLocationPermissionStatus())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())
                        }
                        .padding(.horizontal)
                    }

                    // Map Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Map Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                // Map type selection -> cycle through types via notification
                                let next: MKMapType
                                switch viewModel.selectedMapType {
                                case "Standard":
                                    next = .satellite
                                    viewModel.selectedMapType = "Satellite"
                                case "Satellite":
                                    next = .hybrid
                                    viewModel.selectedMapType = "Hybrid"
                                default:
                                    next = .standard
                                    viewModel.selectedMapType = "Standard"
                                }
                                NotificationCenter.default.post(
                                    name: .mapTypeChanged, object: nil,
                                    userInfo: ["mapType": next.rawValue])
                            }) {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Map Type")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(viewModel.selectedMapType)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Traffic display toggle with logging
                                let newTrafficState = !viewModel.showTraffic
                                viewModel.showTraffic = newTrafficState
                                
                                print("🚦 Traffic display toggled: \(newTrafficState ? "ON" : "OFF")")
                                
                                // Save to UserDefaults for persistence
                                UserDefaults.standard.set(newTrafficState, forKey: "showTraffic")
                                
                                // Notify listeners that traffic setting changed
                                NotificationCenter.default.post(
                                    name: .trafficToggled, object: nil,
                                    userInfo: ["enabled": newTrafficState])
                                
                                print("📢 Traffic notification posted: enabled=\(newTrafficState)")
                            }) {
                                HStack {
                                    Image(systemName: "car.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Show Traffic")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(viewModel.showTraffic ? "On" : "Off")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Units preference toggle mi/km with enhanced logging
                                let newUnits = !useMetricUnits
                                useMetricUnits = newUnits
                                
                                let unitText = newUnits ? "Kilometers" : "Miles"
                                let unitSymbol = newUnits ? "km" : "mi"
                                
                                print("📏 Units preference changed: \(unitText) (\(unitSymbol))")
                                print("   Previous: \(viewModel.units)")
                                print("   New: \(unitText)")
                                
                                viewModel.units = unitText
                                
                                // Save to UserDefaults for persistence
                                UserDefaults.standard.set(newUnits, forKey: "useMetricUnits")
                                
                                // Notify listeners that units changed
                                NotificationCenter.default.post(
                                    name: .unitsPreferenceChanged, object: nil,
                                    userInfo: ["useMetricUnits": newUnits, "unitText": unitText])
                                
                                print("✅ Units preference saved and notification posted")
                            }) {
                                HStack {
                                    Image(systemName: "ruler.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Units")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(useMetricUnits ? "Kilometers" : "Miles")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())
                        }
                        .padding(.horizontal)
                    }

                    // Wake-Up Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wake-Up Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                // Default alarm radius: cycle 250m, 500m, 1000m with enhanced logging
                                let current = viewModel.defaultAlarmRadius
                                let next = (current == 250) ? 500 : (current == 500 ? 1000 : 250)
                                
                                print("🔔 Default alarm radius changed:")
                                print("   Previous: \(current)m")
                                print("   New: \(next)m")
                                
                                viewModel.defaultAlarmRadius = next
                                
                                // Save to UserDefaults for persistence
                                UserDefaults.standard.set(Double(next), forKey: "defaultAlarmRadiusMeters")
                                print("💾 Alarm radius saved to UserDefaults: \(next)m")
                                
                                // Notify listeners that alarm distance changed
                                NotificationCenter.default.post(
                                    name: .alarmDistanceChanged, object: nil,
                                    userInfo: ["radius": Double(next), "previousRadius": Double(current)])
                                
                                print("✅ Alarm radius notification posted")
                            }) {
                                HStack {
                                    Image(systemName: "circle.dashed")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Default Alarm Radius")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(viewModel.defaultAlarmRadius)m")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Call timing
                            }) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Call Timing")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(viewModel.callTiming)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Reset overlays button with enhanced logging
                                print("🗺️ Reset map overlays requested")
                                print("   This will clear all map annotations, polylines, and circles")
                                
                                // Notify listeners to reset map overlays
                                NotificationCenter.default.post(
                                    name: .resetMapOverlays, object: nil)
                                
                                print("✅ Reset map overlays notification posted")
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Reset Map Overlays")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())
                        }
                        .padding(.horizontal)
                    }

                    // Settings Section
                    VStack(spacing: 16) {
                        Button("Restart Walkthrough") {
                            currentPage = 1
                            hasCompletedWalkthrough = false
                        }
                        .buttonStyle(SettingsButtonStyle())

                        Button(action: logout) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Logout")
                            }
                        }
                        .buttonStyle(SettingsButtonStyle(isDestructive: true))
                    }
                    .padding(.horizontal)

                    // Data Management Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                // Clear app data
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Clear App Data")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Export trip history
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Export Trip History")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Privacy settings
                            }) {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Privacy Settings")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())
                        }
                        .padding(.horizontal)
                    }

                    // Support Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Support")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button(action: {
                                // Help center
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Help Center")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Contact support
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Contact Support")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())

                            Button(action: {
                                // Rate app
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Rate SnoozeLane")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(SettingsButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                })
        }
        .background(Color.black)
        .sheet(isPresented: $showLocationPermissionsSheet) {
            LocationPermissionsView()
        }
    }

    func savePhoneNumber() {
        let store = CNContactStore()
        let contact = CNMutableContact()

        // Set the name and other details
        contact.givenName = "Snooze Lane"
        contact.note =
            "Add this contact to your favorites and allow Snooze Lane to wake you up even on Do Not Disturb. \n\nSettings > Focus > Do Not Disturb > \nAllow Notifications from Snooze Lane under People and Apps"

        // Set the phone number
        contact.phoneNumbers = [
            CNLabeledValue(
                label: CNLabelPhoneNumberMain,
                value: CNPhoneNumber(stringValue: twilioPhoneNumber))
        ]

        // Set the contact image if you have an image asset
        if let imageData = UIImage(named: "appLogo")?.pngData() {
            contact.imageData = imageData
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)

        do {
            try store.execute(saveRequest)
            savedContact = contact.copy() as? CNContact
            showingSaveConfirmation = true  // Show confirmation alert on success
        } catch {
            print("Failed to save contact: \(error)")
            showingSaveConfirmation = false  // Optionally handle error feedback
        }
    }

    func clearLocalData() {
        hasCompletedWalkthrough = false
        viewModel.resetCallCount()
    }

    func logout() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }

        isLoggingOut = true

        // Revoke refresh tokens
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Error fetching ID token: \(error.localizedDescription)")
                isLoggingOut = false
                return
            }

            // Revoke the token on the Firebase server side
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                let apiKey = dict["API_KEY"] as? String
            {
                let url = URL(
                    string:
                        "https://identitytoolkit.googleapis.com/v1/accounts:signOut?key=\(apiKey)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = ["idToken": idToken]

                request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error revoking token on server side: \(error.localizedDescription)")
                        isLoggingOut = false
                        return
                    }

                    // Successfully revoked token, now sign out on client side
                    do {
                        try Auth.auth().signOut()

                        // Clear any local data related to the user session
                        clearLocalData()

                        // Update login status to reflect logout
                        DispatchQueue.main.async {
                            loginViewModel.status = false

                            // Dismiss the current view first
                            dismiss()

                            // Wait a brief moment before resetting the root view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let window = UIApplication.shared.windows.first {
                                    // Create new content view with clean state
                                    let contentView = ContentView()
                                        .environmentObject(loginViewModel)
                                        .environmentObject(locationManager)

                                    // Wrap in animation for smooth transition
                                    withAnimation {
                                        window.rootViewController = UIHostingController(
                                            rootView: contentView)
                                    }
                                    window.makeKeyAndVisible()
                                }
                            }
                        }

                        print("Successfully signed out")
                    } catch let signOutError as NSError {
                        print("Error signing out: \(signOutError.localizedDescription)")
                        isLoggingOut = false
                    }
                }
                task.resume()
            } else {
                print("Failed to load GoogleService-Info.plist or find API_KEY")
                isLoggingOut = false
            }
        }
    }

    //    func logout() {
    //        do {
    //            try Auth.auth().signOut()
    //            loginViewModel.status = false // Update login status to reflect logout
    //        } catch let signOutError as NSError {
    //            print("Error signing out: \(signOutError.localizedDescription)")
    //        }
    //    }

    // MARK: - New Functions

    func addSnoozeLaneToContacts() {
        print("📱 Adding Snooze Lane to contacts")
        showAddContactSheet = true
    }

    func showLocationPermissionsOptions() {
        print("📍 Showing location permissions options")
        showLocationPermissionsSheet = true
    }

    func getLocationPermissionStatus() -> String {
        guard let status = locationManager.authorizationStatus else {
            return "Not Set"
        }

        switch status {
        case .notDetermined:
            return "Not Set"
        case .restricted, .denied:
            return "Never"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "While Using"
        @unknown default:
            return "Unknown"
        }
    }
}

struct SettingsButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isDestructive ? Color.red.opacity(0.8) : Color.gray.opacity(0.2)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    instructionSection(
                        title: "1. Add to Contacts",
                        description:
                            "First, add Snooze Lane to your contacts using the 'Add to Contacts' button.",
                        icon: "person.crop.circle.badge.plus"
                    )

                    instructionSection(
                        title: "2. Add to Favorites",
                        description:
                            "Open the saved contact and tap the star icon to add it to your Favorites.",
                        icon: "star.fill"
                    )

                    instructionSection(
                        title: "3. Enable in Do Not Disturb",
                        description:
                            "Go to Settings > Focus > Do Not Disturb > People > Add People, and select Snooze Lane from your contacts.",
                        icon: "moon.fill"
                    )

                    instructionSection(
                        title: "4. Set Custom Ringtone",
                        description:
                            "Open the Snooze Lane contact, tap Edit, and set a distinct ringtone to ensure you won't miss our calls.",
                        icon: "music.note"
                    )

                    Text(
                        "Note: These steps ensure you'll receive our wake-up calls even when your phone is on Do Not Disturb mode."
                    )
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Setup Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func instructionSection(title: String, description: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color("MainOrange"))
                Text(title)
                    .font(.headline)
            }
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("4").opacity(0.5))
        )
    }
}

// MARK: - Location Permissions View
struct LocationPermissionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("Location Permissions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Choose how Snooze Lane can access your location")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Permission Options
                VStack(spacing: 16) {
                    PermissionOptionButton(
                        title: "Never",
                        subtitle: "Snooze Lane cannot access your location",
                        icon: "xmark.circle.fill",
                        color: .red,
                        action: {
                            requestLocationPermission(.denied)
                        }
                    )

                    PermissionOptionButton(
                        title: "While Using App",
                        subtitle: "Snooze Lane can access your location only when the app is open",
                        icon: "location.circle.fill",
                        color: .blue,
                        action: {
                            requestLocationPermission(.authorizedWhenInUse)
                        }
                    )

                    PermissionOptionButton(
                        title: "Always Allow",
                        subtitle:
                            "Snooze Lane can access your location even when the app is closed",
                        icon: "location.fill",
                        color: .green,
                        action: {
                            requestLocationPermission(.authorizedAlways)
                        }
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Current Status
                VStack(spacing: 8) {
                    Text("Current Status:")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(getCurrentPermissionStatus())
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.bottom)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func requestLocationPermission(_ status: CLAuthorizationStatus) {
        print("📍 Requesting location permission: \(status.rawValue)")

        switch status {
        case .denied:
            // Open system settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            // Request permission through location manager
            locationManager.requestAuthorization()
        default:
            break
        }
    }

    private func getCurrentPermissionStatus() -> String {
        guard let status = locationManager.authorizationStatus else {
            return "Not Determined"
        }

        switch status {
        case .notDetermined:
            return "Not Determined"
        case .restricted, .denied:
            return "Never"
        case .authorizedAlways:
            return "Always Allow"
        case .authorizedWhenInUse:
            return "While Using App"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Permission Option Button
struct PermissionOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(LoginViewModel())
    }
}

#Preview {
    SettingsView()
}
