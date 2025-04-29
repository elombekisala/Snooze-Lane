import MapKit
import SwiftUI

struct MapView: View {
    @State private var showSheet: Bool = true
    @State private var userHasInteractedWithMap = false
    @State private var selectedMapItem: MKMapItem?
    @State private var showDetails: Bool = false
    @State private var showErrorAlert = false
    @State private var mapType: MKMapType = .standard

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
                mapType: $mapType
            )
            .ignoresSafeArea(edges: .bottom)

            // Add map type selector at the top
            VStack {
                HStack {
                    Spacer()
                    MapTypeSelector(mapType: $mapType)
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                }
                Spacer()
            }

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
