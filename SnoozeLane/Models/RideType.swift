//
//  RideType.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI
import Foundation

enum RideType: Int, CaseIterable, Identifiable {
    case car
    case transit
    
    var id: Int { return rawValue }
    
    var description: String {
        switch self {
        case.car: return "Car"
        case.transit: return "Transit"
        }
    }
    
    var imageName: String {
        switch self {
        case.car: return "car"
        case.transit: return "transit"
        }
    }
}
