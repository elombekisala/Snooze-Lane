import SwiftUI
import MapKit

struct LocationDetailsView: View {
    @Binding var mapSelection: MKMapItem?
    @Binding var showDetails: Bool
    @Binding var getDirections: Bool
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationManager: LocationManager

    @State private var lookAroundScene: MKLookAroundScene?

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    if let name = mapSelection?.placemark.name {
                        Text(name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    if let subtitle = mapSelection?.placemark.title {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .padding(.trailing)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showDetails = false
                    mapSelection = nil
                    mapState = .searchingForLocation // Change mapState when details are dismissed
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray, Color(.systemGray6))
                }
            }
            
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding()
            } else {
                ContentUnavailableView("No preview available", systemImage: "eye.slash")
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    if let selection = mapSelection {
                        selection.openInMaps()
                    }
                }) {
                    Text("View In Maps")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    mapState = .locationSelected // Set the mapState to location selected to show the trip request view.
                    showDetails = false
                }) {
                    Text("Confirm")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            fetchLookAroundPreview()
        }
        .onChange(of: mapSelection) { _ in
            fetchLookAroundPreview()
        }
        .padding()
    }

    func fetchLookAroundPreview() {
        if let selection = mapSelection {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: selection)
                lookAroundScene = try? await request.scene
            }
        }
    }
}

// Preview provider
struct LocationDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationDetailsView(
            mapSelection: .constant(MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.009020)))),
            showDetails: .constant(true),
            getDirections: .constant(false),
            mapState: .constant(.searchingForLocation)
        )
    }
}

#Preview {
    LocationDetailsView(mapSelection: .constant(nil), showDetails: .constant(false), getDirections: .constant(false), mapState: .constant(.noInput))
}
