import SwiftUI

struct QuickDestinationRow: View {
    let destination: QuickDestination
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .fill(destination.color)
                        .frame(width: 40, height: 40)

                    Image(systemName: destination.icon)
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("1"))

                    Text(destination.subtitle)
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
            destination: QuickDestination.defaultDestinations[0]
        ) {
            print("Home tapped")
        }
        .padding()
        .background(Color("6"))
    }
}
