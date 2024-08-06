import Foundation

struct Podcast: Identifiable, Hashable {
    let id: UInt
    let image: URL?
    let name: String
    let creator: String
}

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
            let trackID: UInt
        }

        var url = baseURL
        url.append(path: "search")
        url.append(queryItems: [
            .init(name: "term", value: query),
            .init(name: "media", value: "podcast"),
        ])

        let (data, _) = try await URLSession.shared.data(from: url)
        let results = try JSONDecoder().decode(SearchResults.self, from: data).results
        let podcasts = results.map { result in
            Podcast(
                id: result.trackID,
                image: result.artworkUrl600,
                name: result.collectionName,
                creator: result.artistName
            )
        }

        return podcasts
    }
}
