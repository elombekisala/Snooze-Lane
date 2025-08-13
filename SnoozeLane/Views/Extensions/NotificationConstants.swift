//
//  NotificationConstants.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 8/31/24.
//

import Foundation
import MapKit
import SwiftUI

// Define custom notification names for better code management
extension Notification.Name {
    static let updateCircle = Notification.Name("updateCircle")
    static let didUpdateLocation = Notification.Name("didUpdateLocation")
    static let locationSelected = Notification.Name("locationSelected")
    static let alarmDistanceChanged = Notification.Name("alarmDistanceChanged")
    static let didClearMapElements = Notification.Name("didClearMapElements")
    static let clearMapOverlays = Notification.Name("clearMapOverlays")
    static let distanceUpdated = Notification.Name("distanceUpdated")
    static let fitMapToUserAndDestination = Notification.Name("fitMapToUserAndDestination")
    static let addDestinationAnnotation = Notification.Name("addDestinationAnnotation")
}
