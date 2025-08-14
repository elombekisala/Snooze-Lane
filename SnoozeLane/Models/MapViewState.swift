//
//  MapViewState.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import Foundation
import SwiftUI

enum MapViewState: String, CaseIterable {
    case noInput = "No Input"
    case searchingForLocation = "Searching"
    case locationSelected = "Location Selected"
    case polylineAdded = "Route Added"
    case settingAlarmRadius = "Setting Alarm"
    case tripInProgress = "Trip in Progress"

    // MARK: - State Properties
    var displayName: String {
        return self.rawValue
    }

    var shouldShowSearchBar: Bool {
        switch self {
        case .noInput, .searchingForLocation:
            return true
        case .locationSelected, .polylineAdded, .settingAlarmRadius, .tripInProgress:
            return false
        }
    }

    var shouldShowTopControls: Bool {
        switch self {
        case .noInput, .searchingForLocation, .locationSelected, .polylineAdded:
            return true
        case .settingAlarmRadius, .tripInProgress:
            return false
        }
    }

    var shouldShowTripProgress: Bool {
        return self == .tripInProgress
    }

    var shouldShowAlarmSettings: Bool {
        return self == .settingAlarmRadius
    }

    var shouldShowLocationDetails: Bool {
        return self == .locationSelected || self == .polylineAdded
    }

    var shouldShowMapControls: Bool {
        switch self {
        case .noInput, .searchingForLocation, .locationSelected:
            return true
        case .polylineAdded, .settingAlarmRadius, .tripInProgress:
            return false
        }
    }

    var backgroundColor: Color {
        switch self {
        case .noInput, .searchingForLocation:
            return Color("6").opacity(0.1)
        case .locationSelected, .polylineAdded:
            return Color("MainOrange").opacity(0.1)
        case .settingAlarmRadius:
            return Color("2").opacity(0.1)
        case .tripInProgress:
            return Color("3").opacity(0.1)
        }
    }

    var accentColor: Color {
        switch self {
        case .noInput, .searchingForLocation:
            return Color("MainOrange")
        case .locationSelected, .polylineAdded:
            return Color("MainOrange")
        case .settingAlarmRadius:
            return Color("2")
        case .tripInProgress:
            return Color("3")
        }
    }
}
