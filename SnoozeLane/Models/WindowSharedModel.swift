//
//  WindowSharedModel.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 9/9/24.
//

import SwiftUI

@Observable
class WindowSharedModel {
    var activeTab: MenuTabs = .search
    var hideTabBar: Bool = false
}
