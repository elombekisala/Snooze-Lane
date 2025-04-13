import SwiftUI
import Contacts
import ContactsUI
import LinkPresentation
import Firebase

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


struct SettingsView: View {
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("hasCompletedWalkthrough") var hasCompletedWalkthrough: Bool = false
    
    @State private var callCount: Int = 0
    @State private var showingContactAddAlert = false
    @State private var showingSaveConfirmation = false
    @State private var showContactView = false
    @State private var savedContact: CNContact?
    
    let twilioPhoneNumber = "8557096502"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Display the Call Count
                Text("Total Trips Completed: \(callCount)")
                    .font(.title2)
                    .foregroundColor(Color("2"))
                
                Spacer()
                
                Image("appLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .frame(width: 75, height: 75, alignment: .center)
                    .shadow(color: Color("3").opacity(0.6), radius: 5, x: -3, y: -3)
                    .shadow(color: Color(.black).opacity(0.6), radius: 5, x: 3, y: 3)
                    .padding()
                
                Button("Add Snooze Lane To Contacts") {
                    savePhoneNumber()
                }
                .padding()
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("MainOrange"), .orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .foregroundColor(Color(.white))
                .alert("Contact Saved", isPresented: $showingSaveConfirmation) {
                    Button("OK", role: .cancel) {}
                    Button("View") {
                        // Prepare to show the contact view
                        showContactView = true
                    }
                }
                .sheet(isPresented: $showContactView) {
                    if let contact = savedContact {
                        ContactView(contact: contact)
                    }
                }
                
                Text("This is the phone number Snooze Lane will call you from to alert you of your destination. Customize the ringtone and add it to your favorites to ensure you receive calls even when your phone is on Do Not Disturb.")
                    .kerning(1.3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("2"))
                    .padding(.horizontal, 12)
                
                Spacer()
                
                Button("Restart Walkthrough") {
                    hasCompletedWalkthrough = false
                }
                .padding()
                .foregroundColor(Color.white)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .background(Color("3"))
                .cornerRadius(10)
                
                // Logout Button
                Button(action: logout) {
                    Text("Logout")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("3"))
                        .cornerRadius(10)
                }
            }
            .padding()
            .onAppear(perform: fetchCallCount)
//            .background(
//                LinearGradient(
//                    gradient: Gradient(colors: [Color("4"), Color("5")]),
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//                .ignoresSafeArea()
//            )
        }
    }
    
    func fetchCallCount() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in")
            return
        }
        
        let userRef = Firestore.firestore().collection("Users").document(userID)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists, let data = document.data(), let count = data["CallCount"] as? Int {
                self.callCount = count
            } else {
                print("Document does not exist or call count not found")
            }
        }
    }
    
    func savePhoneNumber() {
        let store = CNContactStore()
        let contact = CNMutableContact()
        
        // Set the name and other details
        contact.givenName = "Snooze Lane"
        contact.note = "Add this contact to your favorites and allow Snooze Lane to wake you up even on Do Not Disturb. \n\nSettings > Focus > Do Not Disturb > \nAllow Notifications from Snooze Lane under People and Apps"
        
        // Set the phone number
        contact.phoneNumbers = [CNLabeledValue(
            label: CNLabelPhoneNumberMain,
            value: CNPhoneNumber(stringValue: twilioPhoneNumber))]
        
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
        // Clear any local caches, user defaults, or session data
        hasCompletedWalkthrough = false
        callCount = 0
        // Add any additional local data cleanup here
    }
    
    func logout() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        // Revoke refresh tokens
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Error fetching ID token: \(error.localizedDescription)")
                return
            }
            
            // Revoke the token on the Firebase server side
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_API_KEY") as? String {
                let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signOut?key=\(apiKey)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = [
                    "idToken": idToken
                ]
                
                request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error revoking token on server side: \(error.localizedDescription)")
                        return
                    }
                    
                    // Successfully revoked token, now sign out on client side
                    do {
                        try Auth.auth().signOut()
                        loginViewModel.status = false // Update login status to reflect logout
                        print("Successfully signed out")
                        
                        // Clear any local data related to the user session
                        clearLocalData()
                        
                        // Optionally navigate the user back to the login screen
                        DispatchQueue.main.async {
                            presentationMode.wrappedValue.dismiss()
                        }
                        
                    } catch let signOutError as NSError {
                        print("Error signing out: \(signOutError.localizedDescription)")
                    }
                }
                task.resume()
            } else {
                print("Firebase API Key not found in Info.plist")
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(LoginViewModel())  // Provide LoginViewModel for previews
    }
}

#Preview {
    SettingsView()
}
