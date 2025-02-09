struct GameSummary: Codable {
    let summary: String
    let pros: [SummaryPoint]
    let cons: [SummaryPoint]
    let recommendation: String
}

struct SummaryPoint: Codable, Identifiable {
    let content: String
    let weight: Int
    
    var id: String { content }
} 