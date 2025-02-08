import SwiftUI

struct Game: Identifiable {
    let id: Int
    let name: String
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var games: [Game] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Steam Summarize")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                SearchBar(text: $searchText, onSearch: fetchGames)
                    .padding(.horizontal)
                
                List(games) { game in
                    NavigationLink(destination: GameDetailView(game: game.name)) {
                        Text(game.name)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
                .listStyle(PlainListStyle())
                
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
    var game: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(game)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Image(systemName: "photo") // Placeholder for game image
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .background(Color(.systemGray5))
                .cornerRadius(10)
            
            Text("Reviews in Steam")
                .font(.headline)
            
            Text("User Sentiment: Positive") // Placeholder for sentiment
            
            Link("View on Steam", destination: URL(string: "https://store.steampowered.com")!)
                .font(.body)
                .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
        .navigationTitle(game)
    }
}

#Preview {
    ContentView()
}