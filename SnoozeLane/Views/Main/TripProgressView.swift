//
//  TripProgressView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import AVFoundation
import AudioToolbox
import CoreLocation
import SwiftUI
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
    @AppStorage("useMetricUnits") private var useMetricUnits: Bool = false

    let notificationCenter = UNUserNotificationCenter.current()

    var body: some View {

        VStack {
            if tripCompleted {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("You've Arrived!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
            } else {
                Text("Rest easy, we'll wake you when you're close😴")
                    .font(.title2.bold())
                    .foregroundColor(Color("1"))
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }

            GeometryReader { proxy in
                VStack(spacing: 15) {

                    // MARK: Timer Ring
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.03))
                            .padding(-40)

                        Circle()
                            .trim(from: 0, to: progressViewModel.progress)
                            .stroke(.white.opacity(0.03), lineWidth: 60)

                        // MARK: Shadow
                        Circle()
                            .stroke(Color("1"), lineWidth: 8)
                            .blur(radius: 15)
                            .padding(-4)

                        Circle()
                            .fill(Color("5"))

                        // Main Progress Circle
                        Circle()
                            .trim(from: 0, to: CGFloat(progressViewModel.progress))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color("MainOrange"), .orange, Color(uiColor: .systemOrange),
                                    ]),
                                    center: .center,
                                    startAngle: .zero,
                                    endAngle: .init(degrees: 360)
                                ),
                                lineWidth: 30
                            )
                            .rotationEffect(.init(degrees: 0))
                            .animation(.linear(duration: 0.991), value: progressViewModel.progress)

                        // MARK: Knob
                        GeometryReader { proxy in
                            let size = proxy.size

                            Circle()
                                .fill(Color("1"))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .fill(.orange)
                                        .padding(4)
                                )
                                .frame(width: size.width, height: size.height, alignment: .center)
                                .offset(x: size.height / 2)
                                .rotationEffect(.init(degrees: 360 * progressViewModel.progress))
                        }

                        // Display remaining distance or arrival confirmation
                        if progressViewModel.distance <= progressViewModel.alarmDistanceThreshold
                            && progressViewModel.isStarted
                        {
                            // User is within threshold - show arrival message
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                Text("You've Arrived!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .rotationEffect(.init(degrees: 90))
                        } else {
                            // Show remaining distance
                            Text(
                                formatDistance(progressViewModel.distance)
                            )
                            .foregroundColor(.white)
                            .font(.system(size: 32, weight: .light))
                            .rotationEffect(.init(degrees: 90))
                            .animation(.none, value: progressViewModel.progress)
                        }
                    }
                    .padding(40)
                    .frame(height: 250)
                    .rotationEffect(.init(degrees: -90))
                    .animation(.linear(duration: 0.991), value: progressViewModel.progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    if tripCompleted {
                        HStack(spacing: 12) {
                            Button {
                                print("🧪 TESTING CALL FUNCTION")
                                progressViewModel.testCallFunction()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.white)
                                    Text("TEST CALL")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            
                            Button {
                                print("🔄 STARTING NEW TRIP")
                                progressViewModel.startNewTrip()
                                locationViewModel.selectedSnoozeLaneLocation = nil  // Clear destination marker and overlays
                                mapState = .noInput
                                print("✅ TRIP RESET COMPLETE")
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.white)
                                    Text("START NEW TRIP")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(height: 50)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                        }
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
            print("🔄 hasReachedDestination changed to: \(reachedDestination)")
            if reachedDestination {
                print("🎯 TRIP COMPLETED: DESTINATION REACHED")
                tripCompleted = true
                print("🔔 NOTIFICATION AND CALL TRIGGERED")
                // Clear map overlays when trip is completed
                NotificationCenter.default.post(name: .clearMapOverlays, object: nil)
            }
        }
        .onChange(of: progressViewModel.distance) { distance in
            // Single, consolidated threshold detection for call triggering
            if distance <= progressViewModel.alarmDistanceThreshold && progressViewModel.isStarted {
                print("🎯 THRESHOLD DETECTED: Distance \(distance)m, Threshold \(progressViewModel.alarmDistanceThreshold)m")
                
                // Only trigger if we haven't already completed the trip
                if !tripCompleted {
                    print("📞 TRIGGERING CALL FUNCTION - First time within threshold")
                    progressViewModel.checkThresholdReached(distance: distance)
                    tripCompleted = true
                    print("🔔 ARRIVAL THRESHOLD REACHED - CALL FUNCTION TRIGGERED")
                    NotificationCenter.default.post(name: .clearMapOverlays, object: nil)
                } else {
                    print("📞 Already within threshold, call function already triggered")
                }
            } else if distance > progressViewModel.alarmDistanceThreshold && tripCompleted && progressViewModel.isStarted {
                // User moved outside threshold - reset trip completion
                print("🚫 OUTSIDE THRESHOLD: Distance \(distance)m, Threshold \(progressViewModel.alarmDistanceThreshold)m")
                tripCompleted = false
                print("🔄 TRIP COMPLETION RESET")
            }
        }
    }

    // MARK: Reusable Context Menu Options
    @ViewBuilder
    func ContextMenuOptions(maxValue: Int, hint: String, onClick: @escaping (Int) -> Void)
        -> some View
    {
        ForEach(0...maxValue, id: \.self) { value in
            Button("\(value) \(hint)") {
                onClick(value)
            }
        }
    }

    // MARK: Distance Formatting
    private func formatDistance(_ distanceInMeters: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1

        let measurement = Measurement(value: distanceInMeters, unit: UnitLength.meters)

        if useMetricUnits {
            // Use kilometers for metric
            if distanceInMeters >= 1000 {
                let kilometers = measurement.converted(to: .kilometers)
                return formatter.string(from: kilometers)
            } else {
                return formatter.string(from: measurement)
            }
        } else {
            // Use miles for imperial
            let miles = measurement.converted(to: .miles)
            return formatter.string(from: miles)
        }
    }
}
