//
//  ContentView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("hasCompletedWalkthrough") var hasCompletedWalkthrough: Bool = false
    @AppStorage("log_Status") var status = false
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        
        Group {
            if !status {
                // User is not logged in
                NavigationView {
                    Login()
                        .navigationBarHidden(true)
                        .navigationBarBackButtonHidden(true)
                }
            } else if status && !hasCompletedWalkthrough {
                // User is logged in but hasn't completed the walkthrough
                WalkthroughScreen()
                    
            } else if status && hasCompletedWalkthrough {
                // User is logged in and has completed the walkthrough
                Home()
                    
            }
        }
        .environmentObject(locationManager)
    }
}

#Preview {
    ContentView()
}
