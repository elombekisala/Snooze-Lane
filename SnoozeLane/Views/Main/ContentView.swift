//
//  ContentView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("hasCompletedWalkthrough") var hasCompletedWalkthrough: Bool = false
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        
        Group {
            if !loginViewModel.status {
                // User is not logged in
                NavigationView {
                    Login()
                        .navigationBarHidden(true)
                        .navigationBarBackButtonHidden(true)
                }
            } else if loginViewModel.status && !hasCompletedWalkthrough {
                // User is logged in but hasn't completed the walkthrough
                WalkthroughScreen()
                    
            } else if loginViewModel.status && hasCompletedWalkthrough {
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
