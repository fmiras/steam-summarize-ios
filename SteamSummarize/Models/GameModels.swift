struct GameDetails: Codable {
    let steamAppid: Int
    let name: String
    let description: String?
    let headerImage: String?
    
    enum CodingKeys: String, CodingKey {
        case steamAppid = "steam_appid"
        case name
        case description = "detailed_description" 
        case headerImage = "header_image"
    }
}

struct ReviewsResponse: Codable {
    let success: Int
    let querySummary: QuerySummary
    let reviews: [Review]
    
    enum CodingKeys: String, CodingKey {
        case success
        case querySummary = "query_summary"
        case reviews
    }
}

struct QuerySummary: Codable {
    let numReviews: Int
    let reviewScore: Int
    let reviewScoreDesc: String
    let totalPositive: Int
    let totalNegative: Int
    let totalReviews: Int
    
    enum CodingKeys: String, CodingKey {
        case numReviews = "num_reviews"
        case reviewScore = "review_score"
        case reviewScoreDesc = "review_score_desc"
        case totalPositive = "total_positive"
        case totalNegative = "total_negative"
        case totalReviews = "total_reviews"
    }
}

struct Review: Codable, Identifiable {
    let id: String
    let author: ReviewAuthor
    let review: String
    let voted_up: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "recommendationid"
        case author
        case review
        case voted_up
    }
}

struct ReviewAuthor: Codable {
    let steamid: String
    let num_games_owned: Int
    let num_reviews: Int
} 