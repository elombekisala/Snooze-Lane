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
    
    // New sheet state management
    @State private var sheetOffset: CGFloat = 0
    @State private var sheetHeight: CGFloat = 120
    @State private var isDragging: Bool = false
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

            // Top left: Re-center button
            VStack {
                HStack {
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
            }

            // Floating Cancel Button for Trip in Progress
            if mapState == .tripInProgress {
                VStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            // Complete app reset - stop trip progress
                            tripProgressViewModel.stopTrip()

                            // Clear all map data and reset states
                            mapState = .noInput
                            locationViewModel.clearMapElements()

                            // Reset all UI states to initial app state
                            showProgressView = true
                            sheetHeight = 120
                            showSearchOverlay = false
                            isSearching = false
                            locationViewModel.queryFragment = ""

                            // Center map on user location
                            locationViewModel.centerOnUserLocation()

                            // Log the reset operation instead of using print
                            #if DEBUG
                                print(
                                    "🔄 COMPLETE APP RESET: All states cleared, map centered on user"
                                )
                            #endif
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Cancel Trip")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.8),
                                    Color.red.opacity(0.6),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(radius: 4)
                    }
                    .padding(.top, 80)  // Below ad banner
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // Improved Dynamic Bottom Sheet
            if showSearchOverlay {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Draggable Sheet
                    VStack(spacing: 0) {
                        // Drag Handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 36, height: 4)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        let newOffset = value.translation.height + lastDragOffset
                                        sheetOffset = max(-sheetHeight + 60, min(0, newOffset))
                                    }
                                    .onEnded { value in
                                        isDragging = false
                                        let velocity = value.predictedEndTranslation.height - value.translation.height
                                        
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            if velocity > 500 || sheetOffset > -sheetHeight / 2 {
                                                // Snap to bottom (minimal view)
                                                sheetOffset = -sheetHeight + 60
                                            } else {
                                                // Snap to top (full view)
                                                sheetOffset = 0
                                            }
                                        }
                                        lastDragOffset = sheetOffset
                                    }
                            )

                        // Search Header and Input - Only show when not in trip progress with visible progress view
                        if !(mapState == .tripInProgress && showProgressView) {
                            HStack {
                                Button("Cancel") {
                                    dismissSearchOverlay()
                                }
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.leading, 20)

                                Spacer()

                                Text("Search Destination")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                // Invisible button for balance
                                Button("Cancel") {
                                    dismissSearchOverlay()
                                }
                                .foregroundColor(.clear)
                                .padding(.trailing, 20)
                            }
                            .padding(.bottom, 16)

                            // Search Input
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                    .padding(.leading, 16)

                                TextField("Where To?", text: $locationViewModel.queryFragment)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .onChange(of: locationViewModel.queryFragment) { _, newValue in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSearching = !newValue.isEmpty
                                            updateSheetHeight()
                                        }
                                    }

                                if !locationViewModel.queryFragment.isEmpty {
                                    Button(action: {
                                        locationViewModel.queryFragment = ""
                                        isSearching = false
                                        updateSheetHeight()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16))
                                    }
                                    .padding(.trailing, 16)
                                }
                            }
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6).opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }

                        // Content based on state
                        if isSearching || mapState == .locationSelected
                            || mapState == .polylineAdded
                            || mapState == .settingAlarmRadius || mapState == .tripInProgress
                        {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 0) {
                                    if isSearching && !locationViewModel.results.isEmpty {
                                        // Search Results
                                        LazyVStack(spacing: 0) {
                                            ForEach(locationViewModel.results, id: \.self) {
                                                result in
                                                LocationSearchResultsCell(
                                                    title: result.title,
                                                    subtitle: result.subtitle
                                                )
                                                .onTapGesture {
                                                    locationViewModel.selectLocation(result)
                                                    mapState = .locationSelected
                                                    isSearching = false
                                                    updateSheetHeight()
                                                }
                                            }
                                        }
                                        .padding(.top, 8)
                                    } else if mapState == .locationSelected {
                                        // Trip Setup View
                                        TripSetupView(
                                            mapState: $mapState,
                                            alarmDistance: $alarmDistance
                                        )
                                        .onChange(of: mapState) { _, newState in
                                            if newState == .settingAlarmRadius {
                                                updateSheetHeight()
                                            }
                                        }
                                    } else if mapState == .settingAlarmRadius {
                                        // Alarm Settings View
                                        AlarmSettingsView(
                                            isPresented: .constant(true),
                                            alarmDistance: $alarmDistance,
                                            onConfirm: {
                                                mapState = .tripInProgress
                                                updateSheetHeight()
                                            }
                                        )
                                    } else if mapState == .tripInProgress && showProgressView {
                                        // Trip Progress View with Toggle
                                        VStack(spacing: 0) {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showProgressView.toggle()
                                                        updateSheetHeight()
                                                    }
                                                }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "eye.slash")
                                                            .font(.system(size: 14))
                                                        Text("Hide")
                                                            .font(.system(size: 14, weight: .medium))
                                                    }
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.white.opacity(0.2))
                                                    .cornerRadius(12)
                                                }
                                                .padding(.trailing, 20)
                                                .padding(.top, 8)
                                            }

                                            TripProgressView(
                                                mapState: $mapState,
                                                distance: locationViewModel.distance ?? 0,
                                                isActive: .constant(true)
                                            )
                                        }
                                    } else if mapState == .tripInProgress && !showProgressView {
                                        // Hidden Progress View - Just the toggle button
                                        VStack(spacing: 0) {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        showProgressView.toggle()
                                                        updateSheetHeight()
                                                    }
                                                }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "eye")
                                                            .font(.system(size: 14))
                                                        Text("Show")
                                                            .font(.system(size: 14, weight: .medium))
                                                    }
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.white.opacity(0.2))
                                                    .cornerRadius(12)
                                                }
                                                .padding(.trailing, 20)
                                                .padding(.top, 8)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.9),
                                Color.black.opacity(0.85),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .offset(y: sheetOffset)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .ignoresSafeArea(edges: .bottom)
                }
                .transition(.opacity)
                .zIndex(1000)
            }

            // Bottom right: Search and Settings buttons
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSearchOverlay.toggle()
                        if showSearchOverlay {
                            sheetHeight = 120
                            sheetOffset = 0
                            isSearching = false
                        }
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
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
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
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
            }
            .padding(.trailing, 20)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Failed to retrieve address for selected location."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showSettings = false
                            }
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initial setup: ensure the map starts in follow mode
            locationManager.userHasInteractedWithMap = false
        }
    }

    private func dismissSearchOverlay() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSearchOverlay = false
            sheetHeight = 0
            sheetOffset = 0
            isSearching = false
            locationViewModel.queryFragment = ""
            mapState = .noInput
            locationViewModel.clearMapElements()
        }
    }
    
    private func updateSheetHeight() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch mapState {
            case .noInput:
                sheetHeight = 120
            case .locationSelected:
                sheetHeight = 400
            case .settingAlarmRadius:
                sheetHeight = 500
            case .tripInProgress:
                sheetHeight = showProgressView ? 500 : 120
            default:
                sheetHeight = 120
            }
            
            // Update offset to match new height
            if sheetOffset < -sheetHeight + 60 {
                sheetOffset = -sheetHeight + 60
            }
        }
    }
}

// Use existing RoundedCorners for top corners only
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorners(topLeft: radius, topRight: radius))
    }
}
