//
//  LocationSearchActivationView.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI

struct LocationSearchActivationView: View {
    @StateObject var locationManager: LocationManager = .init()
    @Binding var mapState: MapViewState
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color("1"))
                    .padding(.leading, 15)
                
                Text("Search your destination")
                    .foregroundColor(Color("1"))
                    .padding(.trailing)
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("3"))
                    .shadow(color: Color("3").opacity(0.6), radius: 5, x: -3, y: -3)
                    .shadow(color: Color(.black).opacity(0.4), radius: 5, x: 3, y: 3)
            )
            .onTapGesture {
                mapState = .searchingForLocation // Example state transition
            }
        }
    }
}

struct LocationSearchActivationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchActivationView(mapState: .constant(.noInput))
    }
}
