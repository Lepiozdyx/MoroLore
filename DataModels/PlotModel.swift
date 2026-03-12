import Foundation
import SwiftData

@Model
class PlotContainer {
    var id = UUID()
    var storyId: UUID
    
    var beginingPlotSections: [PlotSceneModel]
    var conflictPlotSections: [PlotSceneModel]
    var developmentPlotSections: [PlotSceneModel]
    var climaxPlotSections: [PlotSceneModel]
    var resolutionPlotSections: [PlotSceneModel]
    
    var customPlotSections: [CustomPlotSection]
    
    init(id: UUID = UUID(), storyId: UUID, beginingPlotSections: [PlotSceneModel], conflictPlotSections: [PlotSceneModel], developmentPlotSections: [PlotSceneModel], climaxPlotSections: [PlotSceneModel], resolutionPlotSections: [PlotSceneModel], customPlotSections: [CustomPlotSection]) {
        self.id = id
        self.storyId = storyId
        self.beginingPlotSections = beginingPlotSections
        self.conflictPlotSections = conflictPlotSections
        self.developmentPlotSections = developmentPlotSections
        self.climaxPlotSections = climaxPlotSections
        self.resolutionPlotSections = resolutionPlotSections
        self.customPlotSections = customPlotSections
    }
}

@Model
class CustomPlotSection {
    var id = UUID()
    
    var name: String
    var sectionType: SectionType
    var position: PositionInStory
    var sectionColor: SectionColor
    
    var scenes: [PlotSceneModel]
    
    init(id: UUID = UUID(), name: String, sectionType: SectionType, position: PositionInStory, sectionColor: SectionColor, scenes: [PlotSceneModel]) {
        self.id = id
        self.name = name
        self.sectionType = sectionType
        self.position = position
        self.sectionColor = sectionColor
        self.scenes = scenes
    }
}

enum SectionColor: String, CaseIterable, Codable {
    case gold, burntOrange, emrald, sand, deepIndigo, amber, crismon, violet
}

enum PositionInStory: String, CaseIterable, Codable {
    case addAtEnd, insertBefore, insertAfter
}

enum SectionType: String, CaseIterable, Codable {
    case stiryPhase, flashback, parallelAct, politicalAct, romanceArc, custom
}

@Model
class PlotSceneModel {
    var id = UUID()
    
    var title: String
    var sceneDescription: String
    var characterIds: [UUID]
    var timelinePosition: TimeLinePosition
    var emotionalTone: EmotionalTone?
    
    init(id: UUID = UUID(), title: String, sceneDescription: String, characterIds: [UUID], timelinePosition: TimeLinePosition, emotionalTone: EmotionalTone? = nil) {
        self.id = id
        self.title = title
        self.sceneDescription = sceneDescription
        self.characterIds = characterIds
        self.timelinePosition = timelinePosition
        self.emotionalTone = emotionalTone
    }
}

extension PlotSceneModel {
    func getCharacters(from allCharacters: [CharacterModel]) -> [CharacterModel] {
        allCharacters.filter { characterIds.contains($0.id) }
    }
}

enum EmotionalTone: String, CaseIterable, Codable {
    case tense, hopeful, dark, revaling, political
}

enum TimeLinePosition: String, CaseIterable, Codable {
    case auto, before, after
}
