//
//  VerificationView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/29/24.
//

import SwiftUI

struct Verification: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @Environment(\.presentationMode) var present

    var body: some View {
        ZStack {
            VStack {
                VStack {
                    HStack {
                        Button(action: { present.wrappedValue.dismiss() }) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Text("Verify Phone")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Spacer()

                        if loginViewModel.loading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .padding()

                    Text(
                        "Code sent to +\(loginViewModel.selectedCountryCode.isEmpty ? loginViewModel.getCountryCode() : loginViewModel.selectedCountryCode)\(loginViewModel.phNo)"
                    )
                    .foregroundColor(Color("2"))
                    .padding(.bottom)

                    #if targetEnvironment(simulator)
                        Text("Using simulator test code")
                            .foregroundColor(.gray)
                            .font(.caption)
                    #endif

                    Spacer(minLength: 0)

                    HStack(spacing: 15) {
                        ForEach(0..<6, id: \.self) { index in
                            CodeView(code: getCodeAtIndex(index: index))
                        }
                    }
                    .padding()
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)

                    HStack(spacing: 6) {
                        Text("Didn't receive code?")
                            .foregroundColor(Color("MainOrange"))

                        Button(action: loginViewModel.requestCode) {
                            Text("Request Again")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: loginViewModel.verifyCode) {
                        Text("Verify and Create Account")
                            .foregroundColor(.white)
                            .padding(.vertical)
                            .frame(width: UIScreen.main.bounds.width - 30)
                            .background(Color("3"))
                            .cornerRadius(15)
                    }
                    .padding()
                }
                .frame(height: UIScreen.main.bounds.height / 1.8)
                .cornerRadius(20)

                CustomNumberPad(value: $loginViewModel.code, isVerify: true)
            }
            .zIndex(1)
            .background(
                LinearGradient(
                    colors: [Color("4"), Color("5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all, edges: .bottom)
            )

            if loginViewModel.error {
                AlertView(msg: loginViewModel.errorMsg, show: $loginViewModel.error)
                    .zIndex(2)
            }
        }
        .background(
            LinearGradient(
                colors: [Color("4"), Color("5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .ignoresSafeArea(.all, edges: .bottom)
        )
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    func getCodeAtIndex(index: Int) -> String {
        if loginViewModel.code.count > index {
            let start = loginViewModel.code.startIndex
            let current = loginViewModel.code.index(start, offsetBy: index)
            return String(loginViewModel.code[current])
        }
        return ""
    }
}

struct CodeView: View {
    var code: String

    var body: some View {
        VStack(spacing: 10) {
            Text(code)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
                .frame(height: 45)

            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(height: 4)
        }
    }
}
