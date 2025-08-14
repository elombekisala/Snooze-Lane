//
//  FavoriteDestination.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 4/11/24.
//

import SwiftUI
import FirebaseFirestore

struct FavoriteDestination {
    let id: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    var isFavorite: Bool
}
