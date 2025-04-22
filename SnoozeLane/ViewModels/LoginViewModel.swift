import Firebase
//
//  LoginViewModel.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//
import SwiftUI

class LoginViewModel: ObservableObject {

    @Published var phNo = ""

    @Published var code = ""

    // getting country Phone Code....

    // DataModel For Error View...
    @Published var errorMsg = ""
    @Published var error = false

    // storing CODE for verification...
    @Published var CODE = ""

    @Published var gotoVerify = false

    // User Logged Status
    @AppStorage("log_Status") var status = false

    // Loading View....
    @Published var loading = false
    @Published var fullPhoneNumber: String = ""

    // Default test verification code for simulator
    private let testVerificationCode = "123456"

    var isPhoneNumberValid: Bool {
        // Example: Check for minimum length of 10 digits
        return phNo.count >= 10
    }

    func getCountryCode() -> String {

        let regionCode = Locale.current.regionCode ?? ""

        return countries[regionCode] ?? ""
    }

    // sending Code To User....

    func sendCode() {
        #if targetEnvironment(simulator)
            // For simulator testing
            Auth.auth().settings?.isAppVerificationDisabledForTesting = true
            let number = "+\(getCountryCode())\(phNo)"

            // Use a test verification ID for simulator
            self.CODE = "test-verification-id"
            self.gotoVerify = true
            self.errorMsg = "Test verification code: \(testVerificationCode)"
            withAnimation { self.error.toggle() }
        #else
            // For real device
            Auth.auth().settings?.isAppVerificationDisabledForTesting = false
            let number = "+\(getCountryCode())\(phNo)"

            PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { (CODE, err) in
                if let error = err {
                    self.errorMsg = error.localizedDescription
                    withAnimation { self.error.toggle() }
                    return
                }
                self.CODE = CODE ?? ""
                self.gotoVerify = true
                self.errorMsg = "Code sent successfully!"
                withAnimation { self.error.toggle() }
            }
        #endif
    }

    func verifyCode() {
        loading = true

        #if targetEnvironment(simulator)
            // For simulator testing
            if code == testVerificationCode {
                withAnimation {
                    self.status = true
                    self.loading = false
                }
            } else {
                self.errorMsg = "Invalid verification code. Use: \(testVerificationCode)"
                withAnimation {
                    self.error.toggle()
                    self.loading = false
                }
            }
        #else
            // For real device
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: self.CODE,
                verificationCode: code
            )

            Auth.auth().signIn(with: credential) { (result, err) in
                self.loading = false

                if let error = err {
                    self.errorMsg = error.localizedDescription
                    withAnimation { self.error.toggle() }
                    return
                }
                withAnimation { self.status = true }
            }
        #endif
    }

    func requestCode() {
        sendCode()
    }
}
