//
//  DailyContentStore.swift
//  Just Euchre iOS
//
//  Manages the user's preferred post-game daily content (none / dad joke / useless fact).
//  Each content type has its own daily cache slot, so switching types and switching back
//  within the same day reuses the already-fetched content rather than hitting the API again.
//

import Foundation

enum DailyContentType: String {
    case none        = "none"
    case dadJoke     = "dadJoke"
    case uselessFact = "uselessFact"

    var headerLabel: String {
        switch self {
        case .none:        return ""
        case .dadJoke:     return "DAD JOKE"
        case .uselessFact: return "USELESS FACT"
        }
    }

    fileprivate var textKey: String { "justeuchre.dailycontent.\(rawValue).text" }
    fileprivate var dateKey: String { "justeuchre.dailycontent.\(rawValue).date" }
}

// Defined at file scope so the compiler doesn't infer @MainActor on Decodable conformances,
// which would prevent use in background URLSession callbacks.
private struct DadJokeResponse: Decodable { let joke: String }
private struct FactResponse:    Decodable { let text: String }

enum DailyContentStore {

    private static let preferenceKey = "justeuchre.dailycontent.type"

    static var preferred: DailyContentType {
        get {
            guard let raw = UserDefaults.standard.string(forKey: preferenceKey),
                  let type = DailyContentType(rawValue: raw) else { return .uselessFact }
            return type
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: preferenceKey) }
    }

    /// Returns today's cached text for the given type, or nil if not yet fetched today.
    private static func cached(for type: DailyContentType) -> String? {
        guard let storedDate = UserDefaults.standard.object(forKey: type.dateKey) as? Date,
              Calendar.current.isDateInToday(storedDate) else { return nil }
        return UserDefaults.standard.string(forKey: type.textKey)
    }

    /// Returns content immediately if cached for today; otherwise fetches, caches, then calls back.
    /// Calls back with nil when preference is .none or the fetch fails.
    /// Always calls back on the main queue.
    static func fetchIfNeeded(completion: @escaping (String?) -> Void) {
        let type = preferred
        guard type != .none else { completion(nil); return }

        if let cached = cached(for: type) { completion(cached); return }

        switch type {
        case .none:
            completion(nil)
        case .dadJoke:
            fetchDadJoke(completion: completion)
        case .uselessFact:
            fetchUselessFact(completion: completion)
        }
    }

    // MARK: - Fetchers

    private static func fetchDadJoke(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://icanhazdadjoke.com/") else { completion(nil); return }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(DadJokeResponse.self, from: data),
                  !response.joke.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            cache(response.joke, for: .dadJoke)
            DispatchQueue.main.async { completion(response.joke) }
        }.resume()
    }

    private static func fetchUselessFact(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://uselessfacts.jsph.pl/api/v2/facts/today?language=en") else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(FactResponse.self, from: data),
                  !response.text.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            cache(response.text, for: .uselessFact)
            DispatchQueue.main.async { completion(response.text) }
        }.resume()
    }

    private static func cache(_ text: String, for type: DailyContentType) {
        UserDefaults.standard.set(text,  forKey: type.textKey)
        UserDefaults.standard.set(Date(), forKey: type.dateKey)
    }
}
