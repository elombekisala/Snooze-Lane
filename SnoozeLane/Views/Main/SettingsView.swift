import Contacts
import ContactsUI
import Firebase
import LinkPresentation
import SwiftUI
import UIKit
import os.log

// Define the notification name
extension Notification.Name {
    static let callCountUpdated = Notification.Name("callCountUpdated")
}

//struct SettingsView: View {
//    var body: some View {
//        VStack {
//            ZStack {
//                Image(systemName: "person.fill")
//            }
//            .background(
//                LinearGradient(
//                    gradient: Gradient(colors: [Color("4"), Color("5")]),
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//                .ignoresSafeArea()
//            )
//        }
//    }
//}

// Add SettingsViewModel to manage state
class SettingsViewModel: ObservableObject {
    @Published private(set) var callCount: Int = 0
    private var observer: NSObjectProtocol?
    private let notificationCenter = NotificationCenter.default
    private let db = Firestore.firestore()
    private let logger = Logger(subsystem: "com.snoozelane.app", category: "Settings")

    init() {
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
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("hasCompletedWalkthrough") var hasCompletedWalkthrough: Bool = false
    @AppStorage("currentPage") var currentPage: Int = 1
    @State private var isLoggingOut = false

    @State private var showingContactAddAlert = false
    @State private var showingSaveConfirmation = false
    @State private var showContactView = false
    @State private var savedContact: CNContact?
    @State private var showInstructions = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    let twilioPhoneNumber = "8557096502"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats Section
                HStack(spacing: 12) {
                    Text("\(viewModel.callCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color("MainOrange"))
                        .opacity(1.0)
                        .shadow(color: Color("MainOrange").opacity(0.3), radius: 2, x: 0, y: 0)

                    Text("Trips Completed")
                        .font(.subheadline)
                        .foregroundColor(Color("2"))
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color("4").opacity(0.5))
                )
                .padding(.horizontal)
                .padding(.top, 16)  // Add some top padding since we removed the logo

                // Contact Section
                VStack(spacing: 16) {
                    Button(action: {
                        savePhoneNumber()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.title2)
                            Text("Add to Contacts")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("MainOrange"), .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .foregroundColor(.white)
                    }

                    Button(action: {
                        showInstructions = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.title2)
                            Text("How to Enable Calls")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("3"))
                        .cornerRadius(15)
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

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
            }
            .padding()
        }
        .alert("Contact Saved!", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) {}
            Button("View Contact") {
                showContactView = true
            }
        } message: {
            Text("Would you like to view the contact to add it to your favorites?")
        }
        .sheet(isPresented: $showContactView) {
            if let contact = savedContact {
                ContactView(contact: contact)
            }
        }
        .sheet(isPresented: $showInstructions) {
            InstructionsView()
        }
        .onAppear {
            viewModel.fetchCallCount()
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
                            presentationMode.wrappedValue.dismiss()

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
}

struct SettingsButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDestructive ? Color.red.opacity(0.8) : Color("3"))
            .foregroundColor(.white)
            .cornerRadius(15)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct InstructionsView: View {
    @Environment(\.presentationMode) var presentationMode

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
                        presentationMode.wrappedValue.dismiss()
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(LoginViewModel())
    }
}

#Preview {
    SettingsView()
}
