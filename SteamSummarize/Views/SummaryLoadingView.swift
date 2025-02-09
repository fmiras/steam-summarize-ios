import SwiftUI

struct SummaryLoadingView: View {
    @State private var mainScale: CGFloat = 1.0
    @State private var mainOpacity: Double = 0.5
    @State private var rotationAngle: Double = 0
    @State private var sparkleScale: [CGFloat] = [1, 1, 1]
    @State private var sparkleOpacity: [Double] = [0, 0, 0]
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon stack
            ZStack {
                // Outer rotating glow
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                        .rotationEffect(.degrees(rotationAngle + Double(index * 45)))
                }
                
                // Pulsing background
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)
                    .scaleEffect(mainScale)
                    .opacity(mainOpacity)
                
                // Floating sparkles
                ForEach(0..<3) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .offset(
                            x: cos(Double(index) * .pi * 2/3) * 45,
                            y: sin(Double(index) * .pi * 2/3) * 45
                        )
                        .scaleEffect(sparkleScale[index])
                        .opacity(sparkleOpacity[index])
                }
                
                // Main icon with glass effect
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .symbolEffect(.bounce, options: .repeating)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            VStack(spacing: 8) {
                Text("Analyzing Reviews")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Using AI to generate insights from player feedback")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 32)
        .onAppear {
            // Main pulsing animation
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                mainScale = 1.2
                mainOpacity = 0.2
            }
            
            // Rotation animation
            withAnimation(
                .linear(duration: 8)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
            
            // Sparkle animations
            for index in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.4)
                ) {
                    sparkleScale[index] = 1.3
                    sparkleOpacity[index] = 1
                }
            }
        }
    }
} 