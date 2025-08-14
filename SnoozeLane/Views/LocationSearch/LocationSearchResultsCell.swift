//
//  LocationSearchResultsCell.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//

import SwiftUI
import MapKit

struct LocationSearchResultsCell: View {
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

    var body: some View {
        HStack {

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("MainOrange"), .orange]),
                            startPoint: .top,
                            endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "mappin")
                    .resizable()
                    .foregroundColor(.white)
                    .frame(width: 8, height: 20)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .frame(maxWidth: 40, alignment: .leading)
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                if let coordinate = coordinate {
                    Text("📍 Lat: \(String(format: "%.6f", coordinate.latitude)), Lon: \(String(format: "%.6f", coordinate.longitude))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Divider()
                    .background(.white.opacity(0.3))
                    .padding(.trailing, 8)
            }
            .padding(.leading, 8)
            .padding(.vertical, 8)
        }
        .padding(.leading)
    }
}

struct LocationSearchResultsCell_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchResultsCell(title: "Sample Location", subtitle: "123 Main St, City, State")
    }
}
