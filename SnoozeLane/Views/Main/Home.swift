import Combine
import MapKit
import SwiftUI

struct Home: View {
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

            // Main content area - always show MapView
            MapView(mapState: $mapState, alarmDistance: $alarmDistance)
                .onChange(of: mapState) { oldValue, newValue in
                    windowSharedModel.updateSheetHeight(for: newValue)
                }
        }
    }
}


