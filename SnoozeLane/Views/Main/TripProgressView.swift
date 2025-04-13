//
//  TripProgressView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI
import CoreLocation
import AVFoundation
import AudioToolbox
import UserNotifications

struct TripProgressView: View {
    
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var progressViewModel: TripProgressViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject var loginModel: LoginViewModel = .init()
    @StateObject var loginData = LoginViewModel()
    @State var distance: Double
    @Binding var isActive: Bool
    
    var destinationLocation: SnoozeLaneLocation?
    
    @State private var showNotification = false
    @State private var displayedDistance: String = ""
    @State private var tripCompleted: Bool = false
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    var body: some View {
    
        VStack {
            Text("Rest easy, we'll wake you when you're close😴")
                .font(.title2.bold())
                .foregroundColor(Color("1"))
                .padding(.horizontal)
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            
            
            
            GeometryReader { proxy in
                VStack(spacing: 15) {
                    
                    // MARK: Timer Ring
//                    ZStack {
//                        Circle()
//                            .fill(.white.opacity(0.03))
//                            .padding(-20) // Adjusted padding to reduce size
//                        
//                        Circle()
//                            .trim(from: 0, to: progressViewModel.progress)
//                            .stroke(.white.opacity(0.03), lineWidth: 40) // Adjusted line width to reduce size
//                        
//                        // MARK: Shadow
//                        Circle()
//                            .stroke(Color("1"), lineWidth: 5)
//                            .blur(radius: 15)
//                            .padding(-2)
//                        
//                        Circle()
//                            .fill(Color("5"))
//                        
//                        Circle()
//                            .trim(from: 0, to: CGFloat(progressViewModel.progress))
//                            .stroke(
//                                AngularGradient(
//                                    gradient: Gradient(colors: [Color("MainOrange"), .orange, Color(uiColor: .systemOrange)]),
//                                    center: .center,
//                                    startAngle: .zero,
//                                    endAngle: .init(degrees: 360)
//                                ),
//                                lineWidth: 20 // Adjusted line width to reduce size
//                            )
//                            .rotationEffect(.init(degrees: 0))
//                            .animation(.linear(duration: 0.991), value: progressViewModel.progress)
//                        
//                        // MARK: Knob
//                        GeometryReader { proxy in
//                            let size = proxy.size
//                            
//                            Circle()
//                                .fill(Color("1"))
//                                .frame(width: 20, height: 20) // Adjusted size to reduce size
//                                .overlay(content: {
//                                    Circle()
//                                        .fill(.orange)
//                                        .padding(3)
//                                })
//                                .frame(width: size.width, height: size.height, alignment: .center)
//                            
//                            // MARK: Since View is Rotated That's Why Using X
//                                .offset(x: size.height / 2)
//                                .rotationEffect(.init(degrees: 360 * progressViewModel.progress))
//                        }
//                        
//                        // Display remaining distance to threshold in miles
////                        Text("\(String(format: "%.2f", ((progressViewModel.currentLocation?.distance(from: progressViewModel.destination ?? CLLocation()) ?? 0) - progressViewModel.alarmDistanceThreshold) / 1609.34)) mi")
////                            .foregroundColor(.white)
////                            .font(.system(size: 30, weight: .light))
////                            .rotationEffect(.init(degrees: 90))
////                            .animation(.none, value: progressViewModel.progress)
//                        
//                        let distanceToAlarm = ((progressViewModel.currentLocation?.distance(from: progressViewModel.destination ?? CLLocation()) ?? 0) - progressViewModel.alarmDistanceThreshold)
//                        let displayedDistance = max(0, distanceToAlarm / 1609.34) // Prevent negative distance
//
//                        Text("\(String(format: "%.2f", displayedDistance)) mi")
//                            .foregroundColor(.white)
//                            .font(.system(size: 30, weight: .light))
//                            .rotationEffect(.init(degrees: 90))
//                            .animation(.none, value: progressViewModel.progress)
//                    }
//                    .padding(20)
//                    .frame(height: proxy.size.width * 0.7) // Adjusted height to reduce size
//                    .rotationEffect(.init(degrees: -90))
//                    .animation(.linear(duration: 0.991), value: progressViewModel.progress)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.03))
                            .padding(-20) // You can adjust the padding if needed

                        Circle()
                            .trim(from: 0, to: progressViewModel.progress)
                            .stroke(.white.opacity(0.03), lineWidth: 40) // Adjust line width if necessary

                        // MARK: Shadow
                        Circle()
                            .stroke(Color("1"), lineWidth: 5)
                            .blur(radius: 15)
                            .padding(-2)

                        Circle()
                            .fill(Color("5"))
                        
                        // Main Progress Circle
                        Circle()
                            .trim(from: 0, to: CGFloat(progressViewModel.progress))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [Color("MainOrange"), .orange, Color(uiColor: .systemOrange)]),
                                    center: .center,
                                    startAngle: .zero,
                                    endAngle: .init(degrees: 360)
                                ),
                                lineWidth: 20 // Adjust line width if necessary
                            )
                            .rotationEffect(.init(degrees: 0))
                            .animation(.linear(duration: 0.991), value: progressViewModel.progress)

                        // MARK: Knob
                        GeometryReader { proxy in
                            let size = proxy.size
                            
                            Circle()
                                .fill(Color("1"))
                                .frame(width: 20, height: 20) // Adjust the knob size as needed
                                .overlay(
                                    Circle()
                                        .fill(.orange)
                                        .padding(3)
                                )
                                .frame(width: size.width, height: size.height, alignment: .center)
                                .offset(x: size.height / 2) // Position knob correctly
                                .rotationEffect(.init(degrees: 360 * progressViewModel.progress))
                        }
                        
                        // Display remaining distance in miles
                        Text("\(String(format: "%.2f", ((progressViewModel.currentLocation?.distance(from: progressViewModel.destination ?? CLLocation()) ?? 0) - progressViewModel.alarmDistanceThreshold) / 1609.34)) mi")
                            .foregroundColor(.white)
                            .font(.system(size: 30, weight: .light))
                            .rotationEffect(.init(degrees: 90)) // Ensure text isn't cut off
                            .animation(.none, value: progressViewModel.progress)
                    }
                    .padding(20) // Adjust this value if needed
                    .rotationEffect(.init(degrees: -90))
                    .animation(.linear(duration: 0.991), value: progressViewModel.progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                    Button {
                        if tripCompleted {
                            // Reset everything for a new trip
                            progressViewModel.resetTripProgress()
                            tripCompleted = false
                            mapState = .noInput
                        } else {
                            // Stop the trip and reset progress
                            progressViewModel.stopTrip()
                            progressViewModel.resetTripProgress()
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            mapState = .polylineAdded
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Spacer()

                            Text(tripCompleted ? "START NEW TRIP" : "CANCEL TRIP")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(0.6)

                            Spacer()
                        }
                        .frame(height: 50)
                        .background(Color("6"))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding()
        .preferredColorScheme(.dark)
        .onReceive(locationViewModel.$formattedDistance) { formattedDistance in
            displayedDistance = formattedDistance
        }
        .onChange(of: progressViewModel.hasReachedDestination) { reachedDestination in
            if reachedDestination {
                progressViewModel.triggerNotification()
                tripCompleted = true
            }
        }
    }
    
    // MARK: Reusable Context Menu Options
    @ViewBuilder
    func ContextMenuOptions(maxValue: Int, hint: String, onClick: @escaping (Int) -> ()) -> some View {
        ForEach(0...maxValue, id: \.self) { value in
            Button("\(value) \(hint)") {
                onClick(value)
            }
        }
    }
}
