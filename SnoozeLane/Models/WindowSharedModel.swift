//
//  WindowSharedModel.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 9/9/24.
//

import SwiftUI

final class WindowSharedModel: ObservableObject {
    // Stored properties that need to be observed
    @Published var activeTab: MenuTabs = .search
    @Published var hideTabBar: Bool = false
    @Published var tabBarHeight: CGFloat = 55  // Standard tab bar height
    @Published var sheetHeight: CGFloat = 200  // Initial sheet height

    // Constants (don't need @Published since they don't change)
    let searchSheetHeight: CGFloat = 110
    let tripSetupSheetHeight: CGFloat = 400  // Taller to show all trip setup content
    let searchResultsSheetHeight: CGFloat = UIScreen.main.bounds.height / 2

    // Computed property (doesn't need @Published)
    var contentPadding: CGFloat {
        hideTabBar ? 0 : tabBarHeight
    }

    // Function to update sheet height based on state
    func updateSheetHeight(for state: MapViewState) {
        switch state {
        case .noInput:
            sheetHeight = searchSheetHeight
        case .searchingForLocation:
            sheetHeight = searchResultsSheetHeight
        case .locationSelected, .polylineAdded, .tripInProgress, .settingAlarmRadius:
            sheetHeight = tripSetupSheetHeight
        }
    }
}
