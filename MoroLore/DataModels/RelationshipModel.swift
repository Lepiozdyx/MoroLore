import SwiftData
import Foundation

@Model
class RelationshipModel {
    var id = UUID()
    var storyId: UUID
    var characterAId: UUID
    var characterBId: UUID
    var relationLevel: Int
    var relationType: RelationType
    var relationDescription: String?
    
    init(id: UUID = UUID(), storyId: UUID, characterAId: UUID, characterBId: UUID, relationLevel: Int, relationType: RelationType, relationDescription: String? = nil) {
        self.id = id
        self.storyId = storyId
        self.characterAId = characterAId
        self.characterBId = characterBId
        self.relationLevel = relationLevel
        self.relationType = relationType
        self.relationDescription = relationDescription
    }
}

enum RelationType: String, CaseIterable, Codable {
    case mentor, rival, love, family, ally, enemy, custom
}
