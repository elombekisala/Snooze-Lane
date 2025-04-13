import SwiftUI
import CoreLocation
import MapKit

struct TripSetupView: View {
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var progressViewModel: TripProgressViewModel
    @EnvironmentObject var locationManager: LocationManager
    @State var isActive = false
    @State private var destinationLocation: SnoozeLaneLocation?
    @State private var estimatedTravelTime: String = "---"
    @State private var isAlarmSet = false
    @State private var isLoading = false
    @Binding var alarmDistance: Double
    @State private var isAlarmSettingsPresented = false

    var body: some View {
        VStack {
            HStack(spacing: 15) {
                VStack {
                    Circle()
                        .fill(Color(.white))
                        .frame(width: 10, height: 10)

                    Rectangle()
                        .fill(Color(.systemGray))
                        .frame(width: 1, height: 32)

                    Circle()
                        .fill(.orange)
                        .frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Current Location")
                            .font(.system(size: 16))
                            .foregroundColor(.white).opacity(0.6)

                        Spacer()

                        Text(locationViewModel.pickUpTime ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white).opacity(0.6)
                    }
                    .padding(.bottom, 10)

                    HStack {
                        if let location = locationViewModel.selectedSnoozeLaneLocation {
                            Text(location.title ?? "Selected location")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("No location selected")
                                .font(.headline)
                                .padding()
                        }

                        Spacer()

                        Text(locationViewModel.dropOffTime ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white).opacity(0.6)
                    }
                }
                .padding(.leading, 8)
            }
            .padding()

            Divider()

            HStack() {
                Text("ESTIMATED REST TIME")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    Text("\(estimatedTravelTime)")
                        .font(.title)
                        .foregroundColor(.orange)
                        .padding()
                }
            }
            .padding(.horizontal, 8)

            Divider()
                .padding(.vertical, 8)

            Button(action: {
                mapState = .settingAlarmRadius
                isAlarmSettingsPresented = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .imageScale(.large)
                        .padding(6)
                        .foregroundColor(.white)
                        .padding(.leading)

                    Text(isAlarmSet ? "Alarm Set (\(alarmDistance / 1609.34, specifier: "%.1f") miles)" : "Set Alarm Distance")
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .padding()
                }
                .frame(height: 50)
                .background(isAlarmSet ? Color.green : Color("3"))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }

            HStack(alignment: .center) {
                Button(action: {
//                    mapState = .searchingForLocation
                    mapState = .noInput
                }) {
                    Text("BACK")
                        .fontWeight(.bold)
                        .frame(width: UIScreen.main.bounds.width / 2.2, height: 50)
                        .background(Color("2"))
                        .cornerRadius(10)
                        .foregroundColor(Color("5")).opacity(0.8)
                }

                Spacer()

                Button(action: {
                    if let destinationLocation = locationViewModel.selectedSnoozeLaneLocation {
                        let destination = CLLocation(latitude: destinationLocation.coordinate.latitude, longitude: destinationLocation.coordinate.longitude)
                        progressViewModel.setDestination(destination)
                    }

                    progressViewModel.startTrip()
                    self.locationViewModel.showProgressView = true
                    mapState = .tripInProgress
                }) {
                    Text("CONFIRM TRIP")
                        .fontWeight(.bold)
                        .frame(width: UIScreen.main.bounds.width / 2, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("MainOrange"), Color(.orange).opacity(0.9)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .foregroundColor(Color.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear {
            isLoading = true
        }
        .onReceive(locationViewModel.$estimatedRestTime.receive(on: DispatchQueue.main)) { estimatedRestTime in
            isLoading = false
            if let estimatedRestTime = estimatedRestTime {
                let restTimeInMinutes = Int(round(estimatedRestTime / 60))
                let hours = restTimeInMinutes / 60
                let minutes = restTimeInMinutes % 60

                if hours > 0 {
                    let hourString = hours > 1 ? "hrs" : "hr"
                    let minuteString = minutes > 1 ? "mins" : "min"
                    estimatedTravelTime = "\(hours) \(hourString) \(minutes) \(minuteString)"
                } else {
                    let minuteString = minutes > 1 ? "mins" : "min"
                    estimatedTravelTime = "\(minutes) \(minuteString)"
                }
            } else {
                estimatedTravelTime = "---"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .alarmDistanceChanged)) { notification in
            if let userInfo = notification.userInfo, let newAlarmDistance = userInfo["alarmDistance"] as? Double {
                alarmDistance = newAlarmDistance
                isAlarmSet = true
            }
        }
    }
}
