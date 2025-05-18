import MapKit
import SwiftUI

struct MapView: View {
    @State private var showSheet: Bool = true
    @State private var userHasInteractedWithMap = false
    @State private var selectedMapItem: MKMapItem?
    @State private var showDetails: Bool = false
    @State private var showErrorAlert = false
    @State private var mapType: MKMapType = .standard
    @State private var isFollowingUser: Bool = true

    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var scheme
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var locationManager: LocationManager

    @Binding var mapState: MapViewState
    @Binding var alarmDistance: Double

    var body: some View {
        ZStack(alignment: .top) {
            MapViewRepresentable(
                selectedMapItem: $selectedMapItem,
                showingDetails: $showDetails,
                mapState: $mapState,
                userHasInteractedWithMap: $userHasInteractedWithMap,
                alarmDistance: $alarmDistance,
                mapType: $mapType,
                isFollowingUser: $isFollowingUser
            )
            .ignoresSafeArea(edges: .bottom)

            // Add map type selector at the top right and re-center at the top left
            HStack(alignment: .top) {
                // Re-center button (top left)
                Button(action: {
                    NotificationCenter.default.post(name: .centerOnUserLocation, object: nil)
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isFollowingUser ? .gray : .orange)
                        .padding(16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("4"), Color("5"), Color("5")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.95)
                        )
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .padding(.leading, 16)
                .padding(.top, 16)

                Spacer()

                // Map type selector (top right)
                MapTypeSelector(mapType: $mapType)
                    .padding(.trailing, 16)
                    .padding(.top, 16)
            }
            Spacer()

                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text("Failed to retrieve address for selected location."),
                        dismissButton: .default(Text("OK"))
                    )
                }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initial setup: ensure the map starts in follow mode
            locationManager.userHasInteractedWithMap = false
        }
    }
}
