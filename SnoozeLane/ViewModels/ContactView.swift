//
//  ContactView.swift
//  SnoozeLane
//
//  Created by Elombe.Kisala on 4/22/24.
//

import SwiftUI
import ContactsUI

struct ContactView: UIViewControllerRepresentable {
    var contact: CNContact

    func makeUIViewController(context: Context) -> CNContactViewController {
        let viewController = CNContactViewController(for: contact)
        return viewController
    }

    func updateUIViewController(_ uiViewController: CNContactViewController, context: Context) {
        // Update the view controller if needed.
    }
}
