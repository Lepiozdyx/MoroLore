import SwiftData
import Foundation

@Model
class WorldContainerModel {
    var id = UUID()
    var storyId: UUID
    
    var categories: [WorldCategoryModel]
    
    init(id: UUID = UUID(), storyId: UUID, categories: [WorldCategoryModel]) {
        self.id = id
        self.storyId = storyId
        self.categories = categories
    }
}

@Model
class WorldCategoryModel {
    var id = UUID()
    var name: String
    
    var ellements: [WorldCategoryEllementModel]
    
    init(id: UUID = UUID(), name: String, ellements: [WorldCategoryEllementModel]) {
        self.id = id
        self.name = name
        self.ellements = ellements
    }
}

@Model
class WorldCategoryEllementModel {
    var id = UUID()
    var title: String
    var descriptionModel: String
    var storyNotes: String?
    
    init(id: UUID = UUID(), title: String, descriptionModel: String, storyNotes: String? = nil) {
        self.id = id
        self.title = title
        self.descriptionModel = descriptionModel
        self.storyNotes = storyNotes
    }
}
