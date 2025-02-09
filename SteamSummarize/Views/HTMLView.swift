import SwiftUI
import WebKit

struct HTMLView: UIViewRepresentable {
    let htmlContent: String
    let maxHeight: CGFloat
    let isExpanded: Bool
    @Binding var contentHeight: CGFloat
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        
        // Inject CSS to handle dark mode properly
        let cssString = """
        :root { color-scheme: light dark; }
        """
        let script = WKUserScript(source: "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(script)
        
        // Set loading state to true immediately
        isLoading = true
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Reset loading state when content updates
        isLoading = true
        
        let htmlTemplate = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, system-ui;
                    font-size: 16px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    -webkit-font-smoothing: antialiased;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 8px 0;
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                p {
                    margin: 8px 0;
                }
                h1, h2, h3 {
                    font-weight: 600;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFFFFF;
                    }
                    a {
                        color: #0A84FF;
                    }
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        uiView.loadHTMLString(htmlTemplate, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLView
        
        init(_ parent: HTMLView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { [weak self] height, _ in
                guard let self = self else { return }
                if let height = height as? CGFloat {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.parent.contentHeight = height
                            let finalHeight = self.parent.isExpanded ? height : min(height, self.parent.maxHeight)
                            webView.frame.size.height = finalHeight
                            self.parent.isLoading = false
                        }
                    }
                }
            }
        }
    }
}

struct ExpandableHTMLView: View {
    let htmlContent: String
    @State private var isExpanded = false
    @State private var contentHeight: CGFloat = 0
    let maxHeight: CGFloat = 200
    @State private var isLoading = true
    
    var showExpandButton: Bool {
        contentHeight > maxHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                // Background and skeleton loader
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                            .frame(height: 16)
                            .shimmer()
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(height: 16)
                        .frame(width: 200)
                        .shimmer()
                }
                .padding()
                .frame(height: maxHeight)
                .opacity(isLoading ? 1 : 0)
                
                // HTML Content
                HTMLView(htmlContent: htmlContent,
                        maxHeight: maxHeight,
                        isExpanded: isExpanded,
                        contentHeight: $contentHeight,
                        isLoading: $isLoading)
                    .frame(maxWidth: .infinity)
                    .frame(height: isExpanded ? contentHeight : min(contentHeight, maxHeight))
                    .opacity(isLoading ? 0 : 1)
                
                // Gradient overlay
                if !isExpanded && showExpandButton {
                    VStack(spacing: 0) {
                        Spacer()
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.systemBackground).opacity(0),
                                Color(.systemBackground).opacity(0.85),
                                Color(.systemBackground).opacity(0.95),
                                Color(.systemBackground)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                    }
                    .allowsHitTesting(false)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Show More/Less button
            if showExpandButton {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .imageScale(.small)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
                .padding(.top, isExpanded ? 16 : -20)
                .padding(.bottom, isExpanded ? 16 : 0)
                .frame(maxWidth: .infinity)
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal)
        .animation(.default, value: isLoading)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// Shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color(.systemGray5).opacity(0.7),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2) * phase)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 1
            }
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
} 