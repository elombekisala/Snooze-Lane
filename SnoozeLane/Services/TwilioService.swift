//
//  TwilioService.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/31/24.
//

import Foundation
import FirebaseFunctions

struct TwilioService {
    // Get a reference to the Cloud Functions
    let functions = Functions.functions()
    
    func initiateCall(to phoneNumber: String, completion: @escaping (Bool, Error?) -> Void) {
        // Prepare the data
        let data = ["to": phoneNumber]
        
        // Call the Cloud Function
        functions.httpsCallable("initiateCall").call(data) { result, error in
            if let error = error {
                print("Error calling the initiateCall function: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            completion(true, nil)
            print("Call initiated successfully")
        }
    }
}
