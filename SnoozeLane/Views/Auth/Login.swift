//
//  Login.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/29/24.
//

import SwiftUI

struct Login: View {
    @StateObject var loginViewModel = LoginViewModel()
    @State var isSmall = UIScreen.main.bounds.height < 750
    @State private var isTermsAccepted = false
    @State private var showingCountryPicker = false

    var body: some View {

        ZStack {

            VStack {

                VStack {

                    Text("Continue With Phone")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("2"))
                        .padding()

                    //                    Image("logo")
                    //                        .resizable()
                    //                        .aspectRatio(contentMode: .fit)
                    //                        .padding()

                    Text("You'll receive a 4 digit code\n to verify next.")
                        .font(isSmall ? .none : .title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()

                    VStack {

                        // Mobile Number Field....
                        HStack {

                            VStack(alignment: .leading, spacing: 6) {

                                Text("Enter Your Number")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                HStack(spacing: 8) {
                                    // Country Code Button
                                    Button(action: {
                                        showingCountryPicker = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(
                                                "+\(loginViewModel.selectedCountryCode.isEmpty ? loginViewModel.getDetectedCountryCode() : loginViewModel.selectedCountryCode)"
                                            )
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("2"))

                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(Color("2"))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color("2").opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color("2").opacity(0.3), lineWidth: 1)
                                    )

                                    Text(loginViewModel.phNo)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("2"))
                                }
                            }

                            Spacer(minLength: 0)

                            NavigationLink(
                                destination: Verification(loginViewModel: loginViewModel),
                                isActive: $loginViewModel.gotoVerify
                            ) {

                                Text("")
                                    .hidden()
                            }

                            Button(action: loginViewModel.sendCode) {
                                Text("Continue")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 18)
                                    .padding(.horizontal, 38)
                                    .background(
                                        isTermsAccepted
                                            ? Color.green.opacity(0.7) : Color.black.opacity(0.2)
                                    )
                                    .cornerRadius(15)
                            }
                            .disabled(!isTermsAccepted || loginViewModel.phNo.isEmpty)
                            .shadow(color: Color.white.opacity(0.1), radius: 5, x: 0, y: -5)
                            .padding()

                        }
                        .padding(.horizontal, 10)

                        // Checkbox for Terms of Service
                        VStack {

                            VStack(spacing: 0) {
                                Text("I agree to the ")
                                    .foregroundColor(.gray)
                                HStack {
                                    // You can create separate views for each link
                                    Link(
                                        "Terms of Service",
                                        destination: URL(
                                            string:
                                                "https://snoozelane.webflow.io/terms-and-conditions"
                                        )!
                                    )
                                    .foregroundColor(.white)

                                    Text("and")
                                        .foregroundColor(.gray)

                                    Link(
                                        "Privacy Policy.",
                                        destination: URL(
                                            string: "https://snoozelane.webflow.io/privacy-policy")!
                                    )
                                    .foregroundColor(.white)
                                }

                            }

                            Button(action: {
                                // Toggle the checkbox state
                                self.isTermsAccepted.toggle()
                            }) {
                                // Display a checkmark if isTermsAccepted is true
                                Image(
                                    systemName: isTermsAccepted ? "checkmark.square.fill" : "square"
                                )
                                .foregroundColor(isTermsAccepted ? .green : .gray)
                            }
                            .font(.title2)
                        }
                        .padding()
                        .padding(.horizontal, 10)
                    }
                }
                .frame(height: UIScreen.main.bounds.height / 1.8)
                //                .background(Color("5"))
                .cornerRadius(20)

                // Custom Number Pad....

                CustomNumberPad(value: $loginViewModel.phNo, isVerify: false)

            }.background {
                LinearGradient(
                    colors: [Color("4"), Color("5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .ignoresSafeArea(.all, edges: .bottom)

                if loginViewModel.error {

                    AlertView(msg: loginViewModel.errorMsg, show: $loginViewModel.error)
                }
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            NavigationView {
                ZStack {
                    LinearGradient(
                        colors: [Color("4"), Color("5")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    VStack {
                        // Search bar
                        HStack {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("3"))
                                    .shadow(color: Color("3").opacity(0.6), radius: 5, x: -3, y: -3)
                                    .shadow(color: Color(.black).opacity(0.4), radius: 5, x: 3, y: 3)
                                
                                HStack {
                                    if loginViewModel.searchText.isEmpty {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(Color("1"))
                                            .padding(.leading, 15)
                                    }
                                    
                                    TextField("Search countries...", text: $loginViewModel.searchText)
                                        .foregroundColor(.white)
                                        .padding(.leading, loginViewModel.searchText.isEmpty ? 0 : 15)
                                    
                                    if !loginViewModel.searchText.isEmpty {
                                        Button(action: {
                                            loginViewModel.searchText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                        .padding(.trailing, 15)
                                    }
                                }
                            }
                            .frame(height: 50)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Countries list
                        List {
                            ForEach(loginViewModel.filteredCountries, id: \.self) { country in
                                Button(action: {
                                    loginViewModel.selectedCountryCode = country.code
                                    showingCountryPicker = false
                                }) {
                                    HStack {
                                        Text(country.flag)
                                        Text(country.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("+\(country.code)")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .navigationTitle("Select Country")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingCountryPicker = false
                        }
                    }
                }
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
}
