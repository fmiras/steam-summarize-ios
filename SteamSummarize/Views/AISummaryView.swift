import SwiftUI

struct AISummaryView: View {
    let summary: GameSummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("AI Summary")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            // Main summary
            Text(summary.summary)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .padding(.horizontal)
            
            if !isExpanded {
                Button("Read More") {
                    withAnimation {
                        isExpanded = true
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal)
            }
            
            // Pros and Cons
            VStack(spacing: 16) {
                // Pros
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pros")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(summary.pros) { pro in
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text(pro.content)
                                .font(.system(.body, design: .rounded))
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(0..<pro.weight, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                }
                
                // Cons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cons")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(summary.cons) { con in
                        HStack(spacing: 8) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                            Text(con.content)
                                .font(.system(.body, design: .rounded))
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(0..<con.weight, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Recommendation
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommendation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(summary.recommendation)
                    .font(.system(.body, design: .rounded))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
    }
} 