import SwiftUI

struct Game: Identifiable {
    let id: Int
    let name: String
    let imageURL: String?
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var games: [Game] = []
    @State private var selectedTab = 0
    @State private var isSearchFocused = false
    
    let exampleGames = [
        Game(id: 1091500, name: "Cyberpunk 2077", imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1091500/capsule_231x87.jpg?t=1734434803"),
        Game(id: 2322010, name: "God of War Ragnarök", imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2322010/capsule_231x87.jpg?t=1738256985"),
        Game(id: 1245620, name: "ELDEN RING", imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1245620/capsule_231x87.jpg?t=1738690346"),
        Game(id: 1888930, name: "The Last of Us™ Part I", imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1888930/capsule_231x87.jpg?t=1736371681"),
        Game(id: 1174180, name: "Red Dead Redemption 2", imageURL: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1174180/capsule_231x87.jpg?t=1720558643")
    ]
    
    var displayedGames: [Game] {
        searchText.isEmpty ? exampleGames : games
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, onSearch: fetchGames, isSearchFocused: $isSearchFocused)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if searchText.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Suggestions")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                
                                ForEach(exampleGames) { game in
                                    NavigationLink(destination: GameDetailView(game: game)) {
                                        SuggestionButton(game: game)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                            // Browse Section Second
                            BrowseView()
                                .padding(.top, 16)
                        }
                    }
                } else {
                    // Search Results
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(games) { game in
                                NavigationLink(destination: GameDetailView(game: game)) {
                                    HStack(spacing: 12) {
                                        // Game Image
                                        if let imageURL = game.imageURL {
                                            AsyncImage(url: URL(string: imageURL)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } placeholder: {
                                                Color(.systemGray6)
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        } else {
                                            Image(systemName: "gamecontroller.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                                .frame(width: 60, height: 60)
                                                .background(Color(.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        
                                        // Game Info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(game.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color(.systemGray5), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .dismissKeyboardOnTap()
                }
            }
            .navigationTitle(isSearchFocused ? "" : "Steam Summarize")
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
                            if let id = item["id"] as? Int,
                               let name = item["name"] as? String {
                                return Game(
                                    id: id,
                                    name: name,
                                    imageURL: item["tiny_image"] as? String
                                )
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
    @Binding var isSearchFocused: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Search games", text: $text)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onChange(of: text) { oldValue, newValue in
                        onSearch()
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        isSearchFocused = newValue
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6).opacity(0.95))
            .cornerRadius(10)
            
            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.default, value: isFocused)
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

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())  // Makes entire area tappable
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                             to: nil,
                                             from: nil,
                                             for: nil)
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

// New SuggestionButton component with Apple-style design
struct SuggestionButton: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 12) {
            // Game Image
            if let imageURL = game.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 92, height: 46)  // 2:1 aspect ratio for game banners
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(width: 92, height: 46)
                        .shimmer()  // Add shimmer effect while loading
                }
            }
            
            // Game Title
            Text(game.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
}
