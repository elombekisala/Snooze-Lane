import Combine
import MapKit
import SwiftUI

struct Home: View {
    @State private var activeTab: MenuTabs = .search
    @State private var mapState: MapViewState = .noInput
    @State private var alarmDistance: Double = 482.81
    @State private var localSheetHeight: CGFloat = 110

    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var windowSharedModel: WindowSharedModel
    @Environment(SceneDelegate.self) private var sceneDelegate

    private var sheetHeightBinding: Binding<CGFloat> {
        Binding(
            get: { localSheetHeight },
            set: { newValue in
                localSheetHeight = newValue
                windowSharedModel.sheetHeight = newValue
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            BannerAd(unitID: "ca-app-pub-2382471766301173/6160219590")
                .frame(height: 50)
                .padding(.top)

            TabView(selection: $activeTab) {
                NavigationStack {
                    MapView(mapState: $mapState, alarmDistance: $alarmDistance)
                        .padding(.bottom, windowSharedModel.contentPadding)
                }
                .tag(MenuTabs.search)
                .hideNativeTabBar()

                NavigationStack {
                    SettingsView()
                        .padding(.bottom, windowSharedModel.contentPadding)
                }
                .tag(MenuTabs.settings)
                .hideNativeTabBar()
            }
            .tabSheet(initialHeight: windowSharedModel.sheetHeight, sheetCornerRadius: 15) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 15) {
                            if windowSharedModel.activeTab == .search {
                                dynamicSheet
                            } else if windowSharedModel.activeTab == .settings {
                                SettingsView()
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                    }
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .toolbar(content: {
                        ToolbarItem(placement: .topBarLeading) {
                            Text(windowSharedModel.activeTab.title)
                                .font(.title3.bold())
                        }
                    })
                }
            }
            .onChange(of: mapState) { oldValue, newValue in
                windowSharedModel.updateSheetHeight(for: newValue)
            }
            .onAppear {
                guard sceneDelegate.tabWindow == nil else { return }
                sceneDelegate.addTabBar(windowSharedModel)
            }
        }
    }

    @ViewBuilder
    private var dynamicSheet: some View {
        VStack(alignment: .leading, spacing: 15) {
            if mapState == .noInput {
                LocationSearchView(
                    mapState: $mapState,
                    locationViewModel: locationViewModel
                )
                .environmentObject(locationViewModel)
            } else if mapState == .searchingForLocation {
                LocationSearchView(
                    mapState: $mapState,
                    locationViewModel: locationViewModel
                )
                .environmentObject(locationViewModel)
            } else if mapState == .locationSelected || mapState == .polylineAdded {
                TripSetupView(mapState: $mapState, alarmDistance: $alarmDistance)
                    .environmentObject(locationViewModel)
                    .environmentObject(tripProgressViewModel)
            } else if mapState == .tripInProgress {
                TripProgressView(
                    mapState: $mapState,
                    distance: locationViewModel.distance ?? 0,
                    isActive: .constant(true)
                )
                .environmentObject(locationViewModel)
                .environmentObject(tripProgressViewModel)
            } else if mapState == .settingAlarmRadius {
                AlarmSettingsView(
                    isPresented: .constant(true),
                    alarmDistance: $alarmDistance,
                    onConfirm: {
                        mapState = .locationSelected
                    }
                )
                .environmentObject(locationViewModel)
                .environmentObject(tripProgressViewModel)
            }
        }
    }
}

/// Custom Tab Bar
struct CustomTabBar: View {
    @EnvironmentObject var windowSharedModel: WindowSharedModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                ForEach(MenuTabs.allCases, id: \.rawValue) { tab in
                    Button {
                        windowSharedModel.activeTab = tab
                    } label: {
                        VStack {
                            Image(systemName: tab.rawValue)
                                .font(.title2)

                            Text(tab.title)
                                .font(.caption)
                        }
                        .foregroundStyle(
                            windowSharedModel.activeTab == tab ? Color(.systemOrange) : Color("2")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.rect)
                    }
                }
            }
            .frame(height: windowSharedModel.tabBarHeight)
        }
        .background(Color("5"))
        .offset(y: windowSharedModel.hideTabBar ? windowSharedModel.tabBarHeight : 0)
        .animation(.snappy(duration: 0.25, extraBounce: 0), value: windowSharedModel.hideTabBar)
    }
}
