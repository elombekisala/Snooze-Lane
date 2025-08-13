import MapKit
import SwiftUI

struct MapView: View {
    @Binding var mapState: MapViewState
    @Binding var alarmDistance: Double
    @Binding var showLocationSearch: Bool

    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map
            Map(
                coordinateRegion: $region, showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .ignoresSafeArea()

            // Top Controls - Pinned to top right
            VStack(spacing: 12) {
                // Map Type Button
                Button(action: {
                    // Toggle map type if needed
                }) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }

                // Location Button
                Button(action: {
                    // Center on user location
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                }
            }
            .padding(.top, 60)  // Account for status bar
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            // Request location when view appears
            // locationManager.requestLocation()
        }
        .onChange(of: mapState) { oldValue, newValue in
            // Handle state changes
        }
    }
}

#Preview {
    MapView(
        mapState: .constant(.noInput),
        alarmDistance: .constant(482.81),
        showLocationSearch: .constant(false)
    )
}
