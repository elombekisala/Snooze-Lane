//
//  Sound.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI
import AVFoundation
import AudioToolbox


struct Sound: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let fileName: String?
    let systemSoundID: SystemSoundID?
    
    static func ==(lhs: Sound, rhs: Sound) -> Bool {
        return lhs.id == rhs.id
    }
}
