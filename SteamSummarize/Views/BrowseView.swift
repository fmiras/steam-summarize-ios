import SwiftUI

struct GameCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let searchTerm: String
    let isEnabled: Bool
}

struct BrowseView: View {
    let categories = [
        GameCategory(
            name: "Local Co-op",
            icon: "person.2.fill",
            color: Color.blue,
            searchTerm: "local-coop",
            isEnabled: false
        ),
        GameCategory(
            name: "Online Co-op",
            icon: "network",
            color: Color.green,
            searchTerm: "online-coop",
            isEnabled: false
        ),
        GameCategory(
            name: "Action",
            icon: "bolt.fill",
            color: Color.orange,
            searchTerm: "action",
            isEnabled: false
        ),
        GameCategory(
            name: "RPG",
            icon: "wand.and.stars",
            color: Color.purple,
            searchTerm: "rpg",
            isEnabled: false
        ),
        GameCategory(
            name: "Strategy",
            icon: "brain.head.profile",
            color: Color.indigo,
            searchTerm: "strategy",
            isEnabled: false
        ),
        GameCategory(
            name: "Sports",
            icon: "sportscourt.fill",
            color: Color.teal,
            searchTerm: "sports",
            isEnabled: false
        )
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Browse")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(categories) { category in
                    if category.isEnabled {
                        NavigationLink(destination: CategoryGamesView(category: category)) {
                            CategoryButton(category: category)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    } else {
                        CategoryButton(category: category)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let category: GameCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(category.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(category.color.opacity(category.isEnabled ? 1 : 0.3))
                .shadow(color: category.color.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            Group {
                if !category.isEnabled {
                    Text("Coming Soon")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        )
    }
}

struct CategoryGamesView: View {
    let category: GameCategory
    @State private var games: [Game] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(games) { game in
                        NavigationLink(destination: GameDetailView(game: game)) {
                            GameRow(game: game)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(category.name)
        .onAppear {
            fetchGames()
        }
    }
    
    private func fetchGames() {
        // Use the category.searchTerm to fetch relevant games
        let urlString = "https://store.steampowered.com/api/storesearch/?term=\(category.searchTerm)&l=english&cc=US"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
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
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let items = json["items"] as? [[String: Any]] {
                        self.games = items.compactMap { item in
                            guard let id = item["id"] as? Int,
                                  let name = item["name"] as? String else {
                                return nil
                            }
                            return Game(
                                id: id,
                                name: name,
                                imageURL: item["tiny_image"] as? String
                            )
                        }
                    }
                } catch {
                    errorMessage = "Failed to parse data"
                }
            }
        }.resume()
    }
}

struct GameRow: View {
    let game: Game
    
    var body: some View {
        HStack {
            if let imageURL = game.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                } placeholder: {
                    Color(.systemGray6)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                }
            } else {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                    .frame(width: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
} 