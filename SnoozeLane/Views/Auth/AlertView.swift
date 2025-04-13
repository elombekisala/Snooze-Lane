//
//  AlertView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/29/24.
//

import SwiftUI

struct AlertView: View {
    var msg: String
    @Binding var show: Bool
    var body: some View {
        
        VStack(alignment: .leading, spacing: 15, content: {
            Text("Message")
                .fontWeight(.bold)
                .foregroundColor(Color("1"))
            
            Text(msg)
                .foregroundColor(Color("1"))
            
            Button(action: {
                // closing popup...
                show.toggle()
            }, label: {
                Text("Close")
                    .foregroundColor(Color("1"))
                    .padding(.vertical)
                    .frame(width: UIScreen.main.bounds.width - 100)
                    .background(Color("MainOrange"))
                    .cornerRadius(15)
            })
            
            // centering the button
            .frame(alignment: .center)
        })
        .padding()
        .background(Color("3"))
        .cornerRadius(15)
        .padding(.horizontal,25)
        .zIndex(5)
        // background dim...
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7).ignoresSafeArea())
    }
}

