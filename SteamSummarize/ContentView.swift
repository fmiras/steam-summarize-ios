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
        NavigationSplitView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Add spacing to account for the sticky header
                        Color.clear.frame(height: 60)
                        
                        if searchText.isEmpty {
                            // Suggestions content
                            ScrollView {
                                VStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Suggestions")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal)
                                            .padding(.top, 20)
                                        
                                        VStack(spacing: 0) {
                                            ForEach(exampleGames) { game in
                                                NavigationLink(destination: GameDetailView(game: game)) {
                                                    SuggestionButton(game: game)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                if game.id != exampleGames.last?.id {
                                                    Divider()
                                                        .padding(.leading, 120)
                                                }
                                            }
                                        }
                                    }
                                    
                                    BrowseView()
                                        .padding(.top, 16)
                                }
                            }
                        } else {
                            // Search Results content
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
                }
                
                // Sticky Header
                VStack(spacing: 0) {
                    // Background blur for the header
                    Color.clear
                        .background(.ultraThinMaterial)
                        .frame(height: 60)
                        .overlay(
                            SearchBar(text: $searchText, onSearch: fetchGames, isSearchFocused: $isSearchFocused)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        )
                }
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !isSearchFocused {
                        Text("Steam Summarize")
                            .font(.headline)
                            .opacity(1.0)
                    }
                }
            }
        } detail: {
            NavigationStack {
                EmptyStateView()
            }
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
            .background(Color(.systemGray6))
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
    @State private var gameSummary: GameSummary?
    @State private var isGeneratingSummary = false
    @State private var summaryError: String?
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            if let gameDetails = gameDetails {
                VStack(spacing: 20) {
                    // Header Image
                    if let imageUrl = gameDetails.headerImage {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                    }
                    
                    // Game Description
                    if let description = gameDetails.description {
                        ExpandableHTMLView(htmlContent: description)
                    }
                    
                    // Review Summary
                    if let summary = reviewSummary {
                        ReviewSummaryView(summary: summary)
                    }
                    
                    // TabView section
                    VStack(spacing: 16) {
                        Picker("View Mode", selection: $selectedTab) {
                            Text("Recent Reviews").tag(0)
                            Text("Generate Summary").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedTab) { _, newValue in
                            if newValue == 1 && gameSummary == nil && !isGeneratingSummary {
                                generateSummary()
                            }
                        }
                        .padding(.horizontal)
                        
                        if selectedTab == 0 {
                            ReviewsListView(reviews: reviews)
                                .transition(.opacity)
                        } else {
                            if let summary = gameSummary {
                                AISummaryView(summary: summary)
                            } else if isGeneratingSummary {
                                SummaryLoadingView()
                            } else if let error = summaryError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                    .animation(.easeInOut, value: selectedTab)
                }
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 700 : .infinity)
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
            } else {
                // Replace the ProgressView with a skeleton loader
                VStack(spacing: 20) {
                    // Header Image Skeleton
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shimmer()
                    
                    // Description Skeleton
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shimmer()
                        }
                        
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 200, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmer()
                    }
                    .padding(.horizontal)
                    
                    // Review Summary Skeleton
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 40, height: 40)
                            .shimmer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(width: 120, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shimmer()
                            
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(width: 80, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shimmer()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(game.name)
        .onAppear {
            fetchGameDetails()
            fetchGameReviews()
        }
    }
    
    private func fetchGameDetails() {
        Task {
            do {
                // Check cache first
                if let details = try? await CacheService.shared.retrieve(forKey: "game_details_\(game.id)") as GameDetails {
                    await MainActor.run {
                        self.gameDetails = details
                        self.isLoading = false
                    }
                    return
                }
                
                let urlString = "https://store.steampowered.com/api/appdetails/?appids=\(game.id)&l=english&cc=US"
                guard let url = URL(string: urlString) else { return }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let gameData = json?["\(game.id)"] as? [String: Any],
                   let detailsData = gameData["data"] as? [String: Any] {
                    let jsonData = try JSONSerialization.data(withJSONObject: detailsData)
                    let details = try JSONDecoder().decode(GameDetails.self, from: jsonData)
                    
                    // Cache the response
                    try await CacheService.shared.cache(details, forKey: "game_details_\(game.id)")
                    
                    await MainActor.run {
                        self.gameDetails = details
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchGameReviews() {
        Task {
            do {
                // Check cache first
                if let cachedResponse = try? await CacheService.shared.retrieve(forKey: "game_reviews_\(game.id)") as ReviewsResponse {
                    self.reviews = cachedResponse.reviews
                    self.reviewSummary = cachedResponse.querySummary
                    return
                }
                
                let urlString = "https://store.steampowered.com/appreviews/\(game.id)?json=1&language=english"
                guard let url = URL(string: urlString) else { return }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ReviewsResponse.self, from: data)
                
                // Cache the response
                try await CacheService.shared.cache(response, forKey: "game_reviews_\(game.id)")
                
                await MainActor.run {
                    self.reviews = response.reviews
                    self.reviewSummary = response.querySummary
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func generateSummary() {
        Task {
            do {
                // Check cache first
                if let cachedSummary = try? await CacheService.shared.retrieve(forKey: "game_summary_\(game.id)") as GameSummary {
                    await MainActor.run {
                        self.gameSummary = cachedSummary
                    }
                    return
                }
                
                await MainActor.run {
                    isGeneratingSummary = true
                    summaryError = nil
                }
                
                guard let url = URL(string: "https://steamsummarize.com/api/summarize") else {
                    throw URLError(.badURL)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body = ["game_id": String(game.id)]
                request.httpBody = try JSONEncoder().encode(body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let summary = try JSONDecoder().decode(GameSummary.self, from: data)
                
                // Cache the response
                try await CacheService.shared.cache(summary, forKey: "game_summary_\(game.id)")
                
                await MainActor.run {
                    self.gameSummary = summary
                    self.isGeneratingSummary = false
                }
            } catch {
                await MainActor.run {
                    self.summaryError = error.localizedDescription
                    self.isGeneratingSummary = false
                }
            }
        }
    }
}

struct ReviewsListView: View {
    let reviews: [Review]
    @State private var isExpanded = false
    
    var displayedReviews: [Review] {
        isExpanded ? reviews : Array(reviews.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(displayedReviews) { review in
                ReviewCell(review: review)
            }
            
            if reviews.count > 3 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(isExpanded ? "Show Less" : "Show More")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.blue)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
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
                .frame(maxWidth: .infinity, alignment: .leading)
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
                        .frame(width: 92, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(width: 92, height: 46)
                }
            }
            
            // Game Title
            Text(game.name)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .contentShape(Rectangle()) // Makes the entire row tappable
    }
}

#Preview {
    ContentView()
}
