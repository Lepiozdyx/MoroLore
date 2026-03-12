import SwiftData

final class AppDataContainer {
    static let shared = AppDataContainer()
    let container: ModelContainer

    private init() {
        do {
            self.container = try ModelContainer(
                for:
                    StoryModel.self,
                    CharacterModel.self,
                    RelationshipModel.self,
                    PlotContainer.self,
                    CustomPlotSection.self,
                    PlotSceneModel.self,
                    WorldContainerModel.self,
                    WorldCategoryModel.self,
                    WorldCategoryEllementModel.self
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }
}
