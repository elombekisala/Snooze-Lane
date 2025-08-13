import MapKit
import SwiftUI

struct LocationSearchView: View {
    @Binding var mapState: MapViewState
    @ObservedObject var locationViewModel: LocationSearchViewModel

    @State private var isKeyboardVisible = false

    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .shadow(color: Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)

                HStack {
                    if locationViewModel.queryFragment.isEmpty {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 15)
                    }

                    TextField(
                        "Where To?",
                        text: $locationViewModel.queryFragment,
                        onEditingChanged: { editing in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.isKeyboardVisible = editing
                            }
                        }
                    )
                    .foregroundColor(.primary)
                    .padding(.leading, locationViewModel.queryFragment.isEmpty ? 0 : 15)

                    if !locationViewModel.queryFragment.isEmpty {
                        Button(action: {
                            locationViewModel.queryFragment = ""
                            mapState = .noInput
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.isKeyboardVisible = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 15)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 50)
            .onTapGesture {
                self.isKeyboardVisible = true
            }

            // Search Results
            if isKeyboardVisible && !locationViewModel.results.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(locationViewModel.results, id: \.self) { result in
                            LocationSearchResultsCell(
                                title: result.title,
                                subtitle: result.subtitle
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    locationViewModel.selectLocation(result)
                                    mapState = .locationSelected
                                    self.isKeyboardVisible = false

                                    // Post notification to fit map to show both user location and destination
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        NotificationCenter.default.post(
                                            name: .fitMapToUserAndDestination,
                                            object: nil
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { _ in
            self.isKeyboardVisible = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            self.isKeyboardVisible = false
        }
    }
}

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        let locationViewModel = LocationSearchViewModel(locationManager: LocationManager())
        LocationSearchView(
            mapState: .constant(.searchingForLocation),
            locationViewModel: locationViewModel
        )
    }
}
