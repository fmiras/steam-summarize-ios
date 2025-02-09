import SwiftUI

struct ReviewSummaryView: View {
    let summary: QuerySummary
    
    var formattedPositive: String {
        formatNumber(summary.totalPositive)
    }
    
    var formattedNegative: String {
        formatNumber(summary.totalNegative)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Review Summary")
                .font(.headline)
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(formattedPositive)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.green)
                    Text("Positive")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text(formattedNegative)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.red)
                    Text("Negative")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
} 