//
//  LoginViewModel.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//
import SwiftUI
import Firebase

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
    
    var isPhoneNumberValid: Bool {
            // Example: Check for minimum length of 10 digits
            return phNo.count >= 10
        }
    
    func getCountryCode()->String{
        
        let regionCode = Locale.current.regionCode ?? ""
        
        return countries[regionCode] ?? ""
    }
    
    // sending Code To User....
    
    func sendCode(){
        
        // enabling testing code...
        // disable when you need to test with real device...
        
        Auth.auth().settings?.isAppVerificationDisabledForTesting = false
        
        let number = "+\(getCountryCode())\(phNo)"
        PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { (CODE, err) in
            
            if let error = err{
                
                self.errorMsg = error.localizedDescription
                withAnimation{ self.error.toggle()}
                return
            }
            
            self.CODE = CODE ?? ""
            self.gotoVerify = true
        }
    }
    
    func verifyCode(){
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: self.CODE, verificationCode: code)
        
        loading = true
        
        Auth.auth().signIn(with: credential) { (result, err) in
            
            self.loading = false
            
            if let error = err{
                self.errorMsg = error.localizedDescription
                withAnimation{ self.error.toggle()}
                return
            }
            // else user logged in Successfully ....
            withAnimation{self.status = true}
        }
    }
    
    func requestCode(){
        
        sendCode()
        withAnimation{
            
            self.errorMsg = "Code Sent Successfully !!!"
            self.error.toggle()
        }
    }
}

