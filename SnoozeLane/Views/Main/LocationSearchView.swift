import MapKit
import SwiftUI

struct LocationSearchView: View {

    @Binding var mapState: MapViewState
    @EnvironmentObject var windowSharedModel: WindowSharedModel
    @EnvironmentObject var locationSearchViewModel: LocationSearchViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var startLocationText = ""
    @State private var isKeyboardVisible = false

    @ObservedObject var locationViewModel: LocationSearchViewModel
    @ObservedObject var progressViewModel = TripProgressViewModel(
        locationViewModel: LocationSearchViewModel(locationManager: LocationManager()))

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 15) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 3, x: 0, y: 2)

                    HStack {
                        if locationSearchViewModel.queryFragment.isEmpty {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 15)
                        }
                        TextField(
                            "Where To?", text: $locationSearchViewModel.queryFragment,
                            onEditingChanged: { editing in
                                withAnimation {
                                    self.isKeyboardVisible = editing
                                }
                            }
                        )
                        .foregroundColor(.primary)
                        .padding(.leading, locationSearchViewModel.queryFragment.isEmpty ? 0 : 15)

                        if !locationSearchViewModel.queryFragment.isEmpty {
                            Button(action: {
                                locationSearchViewModel.queryFragment = ""
                                mapState = .noInput
                                withAnimation {
                                    self.isKeyboardVisible = false
                                    windowSharedModel.sheetHeight = 100
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
                .frame(width: UIScreen.main.bounds.width - 50, height: 50)
            }
            .cornerRadius(10)
            .padding(.horizontal)
            .onTapGesture {
                self.isKeyboardVisible = true
                startLocationText = ""  // clear the text field when the user taps it
            }

            if isKeyboardVisible {
                Divider()
                    .padding(.vertical)
                    .frame(height: 2)

                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(locationViewModel.results, id: \.self) { result in
                            LocationSearchResultsCell(
                                title: result.title, subtitle: result.subtitle
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    locationViewModel.selectLocation(result)
                                    mapState = .locationSelected
                                    self.isKeyboardVisible = false
                                }
                            }
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.35), value: isKeyboardVisible)
            }
        }
        .frame(maxHeight: isKeyboardVisible ? .infinity : 80)
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { _ in
            self.isKeyboardVisible = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            self.isKeyboardVisible = false
            if locationSearchViewModel.queryFragment.isEmpty {
                withAnimation {
                    windowSharedModel.sheetHeight = 100
                }
            }
        }
        .onChange(of: locationSearchViewModel.queryFragment) { oldValue, newValue in
            if newValue.isEmpty {
                withAnimation {
                    windowSharedModel.sheetHeight = 100
                }
            } else {
                withAnimation {
                    windowSharedModel.sheetHeight = UIScreen.main.bounds.height / 2
                }
            }
        }
        .padding(.horizontal)
    }
}

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        let locationViewModel = LocationSearchViewModel(locationManager: LocationManager())
        LocationSearchView(
            mapState: .constant(.searchingForLocation),
            locationViewModel: locationViewModel)
    }
}
