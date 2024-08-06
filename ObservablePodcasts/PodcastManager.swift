import UIKit
import Nuke

struct PodcastManager {
    let baseURL = URL(string: "https://itunes.apple.com")!
    
    func search(for query: String) async throws -> [Podcast] {
        struct SearchResults: Decodable {
            let results: [Result]
        }
        
        struct Result: Decodable {
            let artistName: String
            let collectionName: String
            let artworkUrl600: URL
            let trackId: UInt
        }

        var url = baseURL
        url.append(path: "search")
        url.append(queryItems: [
            .init(name: "term", value: query),
            .init(name: "media", value: "podcast")
        ])
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let results = try JSONDecoder().decode(SearchResults.self, from: data).results
        let podcasts = await results.map { result in
            Podcast(
                id: result.trackId,
                image: try? await ImagePipeline.shared.imageTask(with: result.artworkUrl600).image,
                name: result.collectionName,
                creator: result.artistName
            )
        }
        
        return podcasts
    }
}
