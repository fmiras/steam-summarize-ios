import SwiftUI

struct Game: Identifiable {
    let id: Int
    let name: String
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var games: [Game] = []
    
    let exampleGames = [
        Game(id: 570, name: "Dota 2"),
        Game(id: 730, name: "Counter-Strike 2"),
        Game(id: 1172470, name: "Apex Legends"),
        Game(id: 578080, name: "PUBG: BATTLEGROUNDS")
    ]
    
    var displayedGames: [Game] {
        searchText.isEmpty ? exampleGames : games
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Steam Summarize")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                SearchBar(text: $searchText, onSearch: fetchGames)
                    .padding(.horizontal)
                
                if searchText.isEmpty {
                    
                    VStack(alignment: .leading) {
                        Text("Suggested")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(exampleGames) { game in
                            NavigationLink(destination: GameDetailView(game: game)) {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                        .frame(width: 30)
                                    
                                    Text(game.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color(.systemGray5), radius: 2, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Search Results
                    List(games) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            Text(game.name)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func fetchGames() {
        guard !searchText.isEmpty else {
            games = []
            return
        }
        
        let urlString = "https://store.steampowered.com/api/storesearch/?term=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&l=english&cc=US"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.games = items.compactMap { item in
                            if let id = item["id"] as? Int, let name = item["name"] as? String {
                                return Game(id: id, name: name)
                            }
                            return nil
                        }
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }.resume()
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            TextField("Search games", text: $text)
                .padding(8)
                .onChange(of: text) { _ in
                    onSearch()
                }
        }
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .padding(.vertical, 10)
    }
}

struct GameDetailView: View {
    let game: Game
    @State private var gameDetails: GameDetails?
    @State private var reviews: [Review] = []
    @State private var reviewSummary: QuerySummary?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var descriptionHeight: CGFloat = 200 // Default height
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let gameDetails = gameDetails {
                    // Header Image
                    if let imageUrl = gameDetails.headerImage {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    }
                    
                    // Game Description
                    if let description = gameDetails.description {
                        ExpandableHTMLView(htmlContent: description)
                            .padding(.horizontal)
                    }
                    
                    // Review Summary
                    if let summary = reviewSummary {
                        ReviewSummaryView(summary: summary)
                    }
                    
                    // Reviews List
                    ReviewsListView(reviews: reviews)
                    
                } else if isLoading {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationTitle(game.name)
        .onAppear {
            fetchGameDetails()
            fetchGameReviews()
        }
    }
    
    private func fetchGameDetails() {
        let urlString = "https://store.steampowered.com/api/appdetails/?appids=\(game.id)&l=english&cc=US"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let gameData = json?["\(game.id)"] as? [String: Any],
                       let data = gameData["data"] as? [String: Any] {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        gameDetails = try JSONDecoder().decode(GameDetails.self, from: jsonData)
                    }
                } catch {
                    errorMessage = "Failed to parse game details"
                }
            }
        }.resume()
    }
    
    private func fetchGameReviews() {
        let urlString = "https://store.steampowered.com/appreviews/\(game.id)?json=1&language=english"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No review data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ReviewsResponse.self, from: data)
                    reviews = response.reviews
                    reviewSummary = response.querySummary
                } catch {
                    errorMessage = "Failed to parse reviews"
                }
            }
        }.resume()
    }
}

struct ReviewsListView: View {
    let reviews: [Review]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Reviews")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(reviews) { review in
                ReviewCell(review: review)
            }
        }
    }
}

struct ReviewCell: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: review.voted_up ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .foregroundColor(review.voted_up ? .green : .red)
                
                Text("Games owned: \(review.author.num_games_owned)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.review)
                .font(.body)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}