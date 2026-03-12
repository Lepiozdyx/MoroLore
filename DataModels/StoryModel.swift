import SwiftData
import Foundation

@Model
class StoryModel {
    var id = UUID()
    var title: String
    var descriptionStory: String
    var genre: Genre
    var date: Date = Date()
    
    init(id: UUID = UUID(), title: String, descriptionStory: String, genre: Genre) {
        self.id = id
        self.title = title
        self.descriptionStory = descriptionStory
        self.genre = genre
    }
}

enum Genre: String, CaseIterable, Codable {
    case fantasy, adventure, drama, historical, youngAudience, romance, mysterySuspense, psychological, action, speculative, supernatural, other
}

extension Genre {
    var title: String {
        switch self {
        case .fantasy: return "Fantasy"
        case .adventure: return "Adventure"
        case .drama: return "Drama"
        case .historical: return "Historical"
        case .youngAudience: return "Young Audience"
        case .romance: return "Romance"
        case .mysterySuspense: return "Mystery & Suspense"
        case .psychological: return "Psychological"
        case .action: return "Action"
        case .speculative: return "Speculative"
        case .supernatural: return "Supernatural"
        case .other: return "Other..."
        }
    }
    
    var emoji: String {
        switch self {
        case .fantasy: return "✨"
        case .adventure: return "🧙‍♂️"
        case .drama: return "👑"
        case .historical: return "🏰"
        case .youngAudience: return "👧"
        case .romance: return "💘"
        case .mysterySuspense: return "🕵️‍♂️"
        case .psychological: return "🧠"
        case .action: return "🗡️"
        case .speculative: return "🌍"
        case .supernatural: return "👻"
        case .other: return "…"
        }
    }
}
