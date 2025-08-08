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
    @State private var showSettings: Bool = false
    @State private var showSearchOverlay: Bool = false
    @State private var searchPanelHeight: CGFloat = 0
    @State private var isSearching: Bool = false
    @State private var showProgressView: Bool = true

    // Modal state management
    @State private var showModal: Bool = false
    @State private var modalOffset: CGFloat = 0
    @State private var isDraggingModal: Bool = false
    @State private var lastDragOffset: CGFloat = 0

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
        ZStack {
            // Map View
            MapViewRepresentable(
                selectedMapItem: $selectedMapItem,
                showingDetails: $showDetails,
                mapState: $mapState,
                userHasInteractedWithMap: $userHasInteractedWithMap,
                alarmDistance: $alarmDistance,
                mapType: $mapType,
                isFollowingUser: $isFollowingUser
            )
            .ignoresSafeArea()

            // Top Controls
            VStack {
                HStack {
                    // Location Button
                    Button(action: {
                        locationViewModel.centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.leading, 20)

                    Spacer()

                    // Map Type Button
                    Button(action: {
                        mapType = mapType == .standard ? .hybrid : .standard
                    }) {
                        Image(systemName: mapType == .standard ? "map" : "map.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)

                Spacer()
            }

            // Modal View
            if showModal {
                ModalView(
                    locationViewModel: locationViewModel,
                    tripProgressViewModel: tripProgressViewModel,
                    mapState: $mapState,
                    showModal: $showModal,
                    modalOffset: $modalOffset,
                    isDraggingModal: $isDraggingModal,
                    lastDragOffset: $lastDragOffset
                )
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .onAppear {
            // Show modal by default
            showModal = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .locationSelected)) { _ in
            // Show modal when location is selected
            showModal = true
        }
    }
}

struct ModalView: View {
    @ObservedObject var locationViewModel: LocationSearchViewModel
    @ObservedObject var tripProgressViewModel: TripProgressViewModel
    @Binding var mapState: MapViewState
    @Binding var showModal: Bool
    @Binding var modalOffset: CGFloat
    @Binding var isDraggingModal: Bool
    @Binding var lastDragOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                // Modal Content
                VStack(spacing: 0) {
                    // Drag Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Content based on state
                    if locationViewModel.selectedSnoozeLaneLocation != nil {
                        // Trip Setup View
                        TripSetupView(
                            mapState: $mapState,
                            alarmDistance: .constant(100.0)
                        )
                        .environmentObject(locationViewModel)
                        .environmentObject(tripProgressViewModel)
                                            } else if tripProgressViewModel.isStarted {
                            // Trip Progress View
                            TripProgressView(
                                mapState: $mapState,
                                distance: 0.0,
                                isActive: .constant(true)
                            )
                            .environmentObject(tripProgressViewModel)
                                                                } else {
                        // Location Search View
                        LocationSearchView(
                            mapState: $mapState,
                            locationViewModel: locationViewModel
                        )
                }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .offset(y: modalOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDraggingModal = true
                            let newOffset = value.translation.height + lastDragOffset
                            modalOffset = max(-geometry.size.height + 100, min(0, newOffset))
                        }
                        .onEnded { value in
                            isDraggingModal = false
                            let velocity =
                                value.predictedEndTranslation.height - value.translation.height

                            withAnimation(.easeOut(duration: 0.3)) {
                                if velocity > 500 || modalOffset > -geometry.size.height / 2 {
                                    // Snap to bottom (almost completely hidden)
                                    modalOffset = -geometry.size.height + 100
                                } else {
                                    // Snap to top (fully visible)
                                    modalOffset = 0
                                }
                            }
                            lastDragOffset = modalOffset
                        }
                )
            }
        }
    }
}
