import SwiftUI
import AVFoundation
import AudioToolbox

struct AlarmSettingsView: View {
    @EnvironmentObject var progressViewModel: TripProgressViewModel
    @Binding var isPresented: Bool
    @Binding var alarmDistance: Double
    var onConfirm: () -> Void
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedSoundIndex: Int?
    @State private var isAlarmConfirmed = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Alarm Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("1"))
            }
            .padding(.horizontal)
            .padding(.top, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            AlarmDistanceView(alarmDistance: $alarmDistance)
                .environmentObject(progressViewModel)
                .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                isPresented = false
                isAlarmConfirmed = true
                onConfirm()
                // Update the alarmDistanceThreshold in the TripProgressViewModel
                progressViewModel.alarmDistanceThreshold = alarmDistance
                NotificationCenter.default.post(name: .alarmDistanceChanged, object: nil, userInfo: ["alarmDistance": alarmDistance])
            }) {
                Text("Confirm Alarm")
                    .fontWeight(.bold)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("MainOrange"), .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .foregroundColor(Color(.white))
            }
        }
        .onChange(of: alarmDistance) { newDistance in
            print("Slider changed to: \(newDistance)") // Debug line
            if let coordinate = locationViewModel.selectedSnoozeLaneLocation?.coordinate {
                NotificationCenter.default.post(name: .updateCircle, object: ["coordinate": coordinate, "radius": newDistance])
            }
        }
        .onAppear {
            isAlarmConfirmed = false // Reset the confirmation state when the view appears
        }
    }
}

struct AlarmDistanceView: View {
    @EnvironmentObject var progressViewModel: TripProgressViewModel
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var locationManager: LocationManager
    @Binding var alarmDistance: Double
    
    var body: some View {
        VStack {
            VStack(alignment: .center) {
                Text("Alarm Distance From Destination")
                    .font(.headline)
                    .foregroundColor(Color("1"))
                
                Text("\(alarmDistance / 1609.34, specifier: "%.1f") miles")
                    .font(.title)
                    .foregroundColor(Color("1"))
            }
            
            Slider(value: $alarmDistance, in: 482.81...3218.68)
                .padding(.horizontal)
                .accentColor(.orange)
                .onChange(of: alarmDistance) { newValue in
                    if let coordinate = locationViewModel.selectedSnoozeLaneLocation?.coordinate {
                        NotificationCenter.default.post(name: .updateCircle, object: ["coordinate": coordinate, "radius": newValue])
                    }
                    
                    // Haptic feedback on value change
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
        }
    }
}

struct AlarmSettingsView_Previews: PreviewProvider {
    @State static var isShowingAlarmSettingsView = true
    
    static var previews: some View {
        AlarmSettingsView(isPresented: .constant(true), alarmDistance: .constant(1609.34), onConfirm: {})
    }
}
