import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "gamecontroller")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 16) {
                Text("Select a Game")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a game from the suggestions or search for your favorite titles to see reviews and AI-powered insights.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
} 