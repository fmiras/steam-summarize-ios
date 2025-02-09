import Foundation

enum CacheError: Error {
    case failedToEncode
    case failedToDecode
    case failedToSave
    case failedToLoad
    case invalidData
}

struct CachedData<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    
    var isValid: Bool {
        // Cache is valid for 24 hours
        let calendar = Calendar.current
        guard let expirationDate = calendar.date(byAdding: .hour, value: 24, to: timestamp) else {
            return false
        }
        return Date() < expirationDate
    }
}

actor CacheService {
    static let shared = CacheService()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("GameCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func fileURL(forKey key: String) -> URL {
        cacheDirectory.appendingPathComponent(key).appendingPathExtension("cache")
    }
    
    func cache<T: Codable>(_ data: T, forKey key: String) async throws {
        let cachedData = CachedData(data: data, timestamp: Date())
        
        do {
            let encoded = try JSONEncoder().encode(cachedData)
            try encoded.write(to: fileURL(forKey: key))
        } catch {
            throw CacheError.failedToSave
        }
    }
    
    func retrieve<T: Codable>(forKey key: String) async throws -> T {
        let fileURL = fileURL(forKey: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CacheError.invalidData
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)
            
            guard cachedData.isValid else {
                try? fileManager.removeItem(at: fileURL)
                throw CacheError.invalidData
            }
            
            return cachedData.data
        } catch {
            throw CacheError.failedToLoad
        }
    }
    
    func clearCache(forKey key: String) async throws {
        let fileURL = fileURL(forKey: key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearAllCache() async throws {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func clearExpiredCache() async throws {
        let urls = try fileManager.contentsOfDirectory(at: cacheDirectory, 
                                                     includingPropertiesForKeys: nil)
        
        for url in urls {
            guard let data = try? Data(contentsOf: url) else { continue }
            
            // Decode just the timestamp to check validity
            struct CacheMetadata: Codable {
                let timestamp: Date
                
                var isValid: Bool {
                    let calendar = Calendar.current
                    guard let expirationDate = calendar.date(byAdding: .hour, value: 24, to: timestamp) else {
                        return false
                    }
                    return Date() < expirationDate
                }
            }
            
            if let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: data),
               !metadata.isValid {
                try? fileManager.removeItem(at: url)
            }
        }
    }
} 