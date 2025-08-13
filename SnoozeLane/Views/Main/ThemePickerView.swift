import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedTheme: MapTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Map Theme")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose how you want your map to look")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Theme Options
                VStack(spacing: 16) {
                    ForEach(MapTheme.allCases, id: \.self) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            onTap: {
                                selectedTheme = theme
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Apply Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Apply Theme")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedTheme.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct ThemeOptionRow: View {
    let theme: MapTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Theme Preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .frame(width: 60, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.accentColor, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "map")
                            .foregroundColor(theme.accentColor)
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text(themeDescription(for: theme))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.accentColor.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func themeDescription(for theme: MapTheme) -> String {
        switch theme {
        case .light:
            return "Clean, bright appearance"
        case .dark:
            return "Dark, easy on the eyes"
        case .custom:
            return "Unique orange theme"
        }
    }
}

#Preview {
    ThemePickerView(selectedTheme: .constant(.light))
}
