import SwiftData
import Foundation

@Model
class CharacterModel {
    var id = UUID()
    var storyId: UUID
    
    var name: String
    var role: Role
    
    var age: Int
    var origin: String
    
    var traits: String?
    var motivation: String?
    var internalConflict: String?
    var secret: String?
    
    var status: Status
    var notes: String?
    
    init(id: UUID = UUID(), storyId: UUID, name: String, role: Role, age: Int, origin: String, traits: String? = nil, motivation: String? = nil, internalConflict: String? = nil, secret: String? = nil, status: Status, notes: String? = nil) {
        self.id = id
        self.storyId = storyId
        self.name = name
        self.role = role
        self.age = age
        self.origin = origin
        self.traits = traits
        self.motivation = motivation
        self.internalConflict = internalConflict
        self.secret = secret
        self.status = status
        self.notes = notes
    }
}

enum Role: String, CaseIterable, Codable {
    case main, supporting, antagonist, other
}

enum Status: String, CaseIterable, Codable {
    case alive, missing, changed, revealed
}
