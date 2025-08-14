//
//  PhoneAuthView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/26/24.
//

import SwiftUI
import Firebase

struct PhoneAuthView: View {
    @State private var phoneNumber = ""
    @State private var verificationID: String?
    @State private var verificationCode = ""

    var body: some View {
        VStack {
            TextField("Enter phone number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Send Verification Code") {
                sendVerificationCode()
            }
            .padding()

            if verificationID != nil {
                TextField("Enter verification code", text: $verificationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Verify and Sign In") {
                    verifyAndSignIn()
                }
                .padding()
            }
        }
    }

    private func sendVerificationCode() {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("Error sending verification code: \(error.localizedDescription)")
                return
            }
            self.verificationID = verificationID
            // Update UI to show verification code text field
        }
    }

    private func verifyAndSignIn() {
        guard let verificationID = verificationID else { return }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            // User is signed in
            // Navigate to the next part of your app
        }
    }
}


#Preview {
    PhoneAuthView()
}
