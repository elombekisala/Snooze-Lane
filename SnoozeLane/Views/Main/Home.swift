import SwiftUI
import MapKit
import Combine

struct Home: View {
    @State private var activeTab: MenuTabs = .search
    @State private var mapState: MapViewState = .noInput
    @State private var alarmDistance: Double = 482.81
    @State private var sheetHeight: CGFloat = 110
    
//    @EnvironmentObject var locationSearchViewModel: LocationSearchViewModel
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var tripProgressViewModel: TripProgressViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @Environment(WindowSharedModel.self) private var windowSharedModel
    @Environment(SceneDelegate.self) private var sceneDelegate
    
    var body: some View {
        
        VStack() {
            
            BannerAd(unitID: "ca-app-pub-2382471766301173/6160219590")
                .frame(height: 50)
                .padding(.top)
            
            Spacer()
            
            @Bindable var bindableObject = windowSharedModel
            
            TabView(selection: $activeTab) {
                NavigationStack {
                    MapView(mapState: $mapState, alarmDistance: $alarmDistance)
                }
                .tag(MenuTabs.search)
                .hideNativeTabBar()
                
                NavigationStack {
                    Text("Favorites")
                }
                .tag(MenuTabs.favorites)
                .hideNativeTabBar()
                
                NavigationStack {
                    AiAssistantView()
                }
                .tag(MenuTabs.ai)
                .hideNativeTabBar()
                
                NavigationStack {
                    SettingsView()
                }
                .tag(MenuTabs.settings)
                .hideNativeTabBar()
            }
            .tabSheet(initialHeight: 200, sheetCornerRadius: 15) {
                NavigationStack {
                    ScrollView {
                        /// Showing Some Sample Mock Devices
                        VStack(spacing: 15) {
                            if windowSharedModel.activeTab == .search {
                                dynamicSheet
                            } else if windowSharedModel.activeTab == .favorites {
                                Text("Favorites")
                            } else if windowSharedModel.activeTab == .ai {
                                AiAssistantView()
                            }
                            else if windowSharedModel.activeTab == .settings {
                               SettingsView()
                           }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                    }
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .toolbar(content: {
                        /// Leading Title
                        ToolbarItem(placement: .topBarLeading) {
                            Text(windowSharedModel.activeTab.title)
                                .font(.title3.bold())
                        }
                        
                        /// Showing Plus Button for only Devices
                        if windowSharedModel.activeTab == .favorites {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {}, label: {
                                    Image(systemName: "plus")
                                })
                            }
                        }
                    })
                }
            }
            .onAppear {
                guard sceneDelegate.tabWindow == nil else { return }
                sceneDelegate.addTabBar(windowSharedModel)
            }
        }
    }
    
    @ViewBuilder
    private var dynamicSheet: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 15) {
                if mapState == .noInput {
                    LocationSearchView(mapState: $mapState, sheetHeight: $sheetHeight, locationViewModel: locationViewModel)
                        .environmentObject(locationViewModel)
                } else if mapState == .searchingForLocation {
                    LocationSearchView(mapState: $mapState, sheetHeight: $sheetHeight, locationViewModel: locationViewModel)
                        .environmentObject(locationViewModel)
                } else if mapState == .locationSelected || mapState == .polylineAdded {
                    TripSetupView(mapState: $mapState, alarmDistance: $alarmDistance)
                        .environmentObject(locationViewModel)
                        .environmentObject(tripProgressViewModel)
                } else if mapState == .tripInProgress {
                    TripProgressView(mapState: $mapState, distance: locationViewModel.distance ?? 0, isActive: .constant(true))
                        .environmentObject(locationViewModel)
                        .environmentObject(tripProgressViewModel)
                } else if mapState == .settingAlarmRadius {
                    AlarmSettingsView(isPresented: .constant(true), alarmDistance: $alarmDistance, onConfirm: {
                        mapState = .locationSelected
                    })
                    .environmentObject(locationViewModel)
                    .environmentObject(tripProgressViewModel)
                }
            }
//            .padding()
        }
    }
}


/// Custom Tab Bar
struct CustomTabBar: View {
    @Environment(WindowSharedModel.self) private var windowSharedModel
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
                        .foregroundStyle(windowSharedModel.activeTab == tab ? Color(.systemOrange) : Color("2"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.rect)
                    }
                }
            }
            .frame(height: 55)
        }
        .background(Color("5"))
        .offset(y: windowSharedModel.hideTabBar ? 100 : 0)
        .animation(.snappy(duration: 0.25, extraBounce: 0), value: windowSharedModel.hideTabBar)
    }
}


