import SwiftUI

struct QuickDestinationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                    
                    Image(systemName: icon)
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("1"))
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color("2"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color("3"))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("6").opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickDestinationRow_Previews: PreviewProvider {
    static var previews: some View {
        QuickDestinationRow(
            title: "Home",
            subtitle: "123 Main St",
            icon: "house.fill"
        ) {
            print("Home tapped")
        }
        .padding()
        .background(Color("6"))
    }
}
