import SwiftUI
import SwiftData
import Foundation

struct PlotView: View {
    let story: StoryModel
    
    @State private var plotContainer: PlotContainer?
    @State private var characters: [CharacterModel] = []
    @State private var expandedSections: Set<String> = []
    @State private var showAddScene = false
    @State private var showAddSection = false
    @State private var showEditSection = false
    @State private var selectedSection: PlotSection?
    @State private var editingScene: PlotSceneModel?
    @State private var editingCustomSection: CustomPlotSection?
    @State private var editingSystemSection: SystemSection?
    
    enum PlotSection: Hashable {
        case beginning
        case conflict
        case development
        case climax
        case resolution
        case custom(UUID)
    }
    
    enum SystemSection {
        case beginning
        case conflict
        case development
        case climax
        case resolution
        
        var name: String {
            switch self {
            case .beginning: return "Beginning"
            case .conflict: return "Conflict"
            case .development: return "Development"
            case .climax: return "Climax"
            case .resolution: return "Resolution"
            }
        }
        
        var defaultColor: SectionColor {
            switch self {
            case .beginning: return .gold
            case .conflict: return .burntOrange
            case .development: return .sand
            case .climax: return .crismon
            case .resolution: return .emrald
            }
        }
    }
    
    init(story: StoryModel) {
        self.story = story
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    sectionCard(
                        title: "BEGINNING",
                        number: 1,
                        color: Color(hex: "#F5C542"),
                        scenes: plotContainer?.beginingPlotSections ?? [],
                        section: .beginning,
                        systemSection: .beginning
                    )
                    
                    sectionCard(
                        title: "CONFLICT",
                        number: 2,
                        color: Color(hex: "#E07B39"),
                        scenes: plotContainer?.conflictPlotSections ?? [],
                        section: .conflict,
                        systemSection: .conflict
                    )
                    
                    sectionCard(
                        title: "DEVELOPMENT",
                        number: 3,
                        color: Color(hex: "#D4923B"),
                        scenes: plotContainer?.developmentPlotSections ?? [],
                        section: .development,
                        systemSection: .development
                    )
                    
                    sectionCard(
                        title: "CLIMAX",
                        number: 4,
                        color: Color(hex: "#DC5F5F"),
                        scenes: plotContainer?.climaxPlotSections ?? [],
                        section: .climax,
                        systemSection: .climax
                    )
                    
                    sectionCard(
                        title: "RESOLUTION",
                        number: 5,
                        color: Color(hex: "#6B9B7B"),
                        scenes: plotContainer?.resolutionPlotSections ?? [],
                        section: .resolution,
                        systemSection: .resolution
                    )
                    
                    ForEach(plotContainer?.customPlotSections ?? [], id: \.id) { customSection in
                        customSectionCard(customSection)
                    }
                    
                    addSectionButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            loadPlotContainer()
            loadCharacters()
        }
        .sheet(isPresented: $showAddScene) { [selectedSection, editingScene] in
            if let section = selectedSection {
                AddSceneView(
                    story: story,
                    section: section,
                    characters: characters,
                    editingScene: editingScene,
                    onSave: { scene in
                        if editingScene == nil {
                            addScene(scene, to: section)
                        } else {
                            loadPlotContainer()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showAddSection) {
            CreateCustomSectionView { customSection in
                addCustomSection(customSection)
            }
        }
        .sheet(isPresented: $showEditSection) { [editingCustomSection, editingSystemSection] in
            if let customSection = editingCustomSection {
                EditCustomSectionView(customSection: customSection) {
                    loadPlotContainer()
                }
            }
        }
    }
    
    private func sectionCard(title: String, number: Int, color: Color, scenes: [PlotSceneModel], section: PlotSection, systemSection: SystemSection) -> some View {
        let isExpanded = expandedSections.contains(title)
        
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if isExpanded {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            } label: {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("\(number)")
                                .font(.custom("Inter-Bold", size: 20))
                                .foregroundColor(.white)
                        )
                    
                    Text(title)
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(Color(hex: "#0D0D2B"))
                    
                    Spacer()
                    
                    Text("\(scenes.count) scenes")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(Color(hex: "#0D0D2B").opacity(0.7))
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#0D0D2B").opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 20 : 20))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    if scenes.isEmpty {
                        emptySceneView(section: section, color: color)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(scenes.enumerated()), id: \.element.id) { index, scene in
                                sceneCard(scene: scene, index: index + 1, color: color, section: section)
                            }
                            
                            addSceneButton(section: section, color: color)
                        }
                        .padding(20)
                    }
                }
                .background(Color(hex: "#1A1650").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func customSectionCard(_ customSection: CustomPlotSection) -> some View {
        let isExpanded = expandedSections.contains(customSection.name)
        let color = colorForSection(customSection.sectionColor)
        
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if isExpanded {
                        expandedSections.remove(customSection.name)
                    } else {
                        expandedSections.insert(customSection.name)
                    }
                }
            } label: {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                    
                    Text(customSection.name.uppercased())
                        .font(.custom("Inter-Bold", size: 18))
                        .foregroundColor(Color(hex: "#0D0D2B"))
                    
                    Spacer()
                    
                    Button {
                        editingCustomSection = customSection
                        editingSystemSection = nil
                        showEditSection = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#0D0D2B").opacity(0.7))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(customSection.scenes.count) scenes")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(Color(hex: "#0D0D2B").opacity(0.7))
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#0D0D2B").opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    if customSection.scenes.isEmpty {
                        emptySceneView(section: .custom(customSection.id), color: color)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(customSection.scenes.enumerated()), id: \.element.id) { index, scene in
                                sceneCard(scene: scene, index: index + 1, color: color, section: .custom(customSection.id))
                            }
                            
                            addSceneButton(section: .custom(customSection.id), color: color)
                        }
                        .padding(20)
                    }
                }
                .background(Color(hex: "#1A1650").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func emptySceneView(section: PlotSection, color: Color) -> some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "film")
                        .font(.system(size: 28))
                        .foregroundColor(color.opacity(0.6))
                )
            
            VStack(spacing: 4) {
                Text("No scenes added.")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(.white)
                
                Text("This section is ready for your first scene.")
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Button {
                editingScene = nil
                selectedSection = section
                showAddScene = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add Scene")
                        .font(.custom("Inter-Bold", size: 15))
                }
                .foregroundColor(color)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func sceneCard(scene: PlotSceneModel, index: Int, color: Color, section: PlotSection) -> some View {
        Button {
            editingScene = scene
            selectedSection = section
            showAddScene = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "film")
                                .font(.system(size: 16))
                                .foregroundColor(color)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scene.title)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(.white)
                        
                        Text("#\(index)")
                            .font(.custom("Inter-Medium", size: 13))
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                }
                
                Text(scene.sceneDescription)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
                
                let sceneCharacters = scene.getCharacters(from: characters)
                if !sceneCharacters.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(sceneCharacters, id: \.id) { character in
                                    Text(character.name)
                                        .font(.custom("Inter-Medium", size: 13))
                                        .foregroundColor(color)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(color.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "#0D0D2B").opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func addSceneButton(section: PlotSection, color: Color) -> some View {
        Button {
            editingScene = nil
            selectedSection = section
            showAddScene = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text("Add Scene")
                    .font(.custom("Inter-Bold", size: 16))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var addSectionButton: some View {
        Button {
            showAddSection = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text("Add Plot Section")
                    .font(.custom("Inter-Bold", size: 16))
            }
            .foregroundColor(Color(hex: "#F5C542"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "#F5C542").opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func colorForSection(_ sectionColor: SectionColor) -> Color {
        switch sectionColor {
        case .gold: return Color(hex: "#F5C542")
        case .burntOrange: return Color(hex: "#E07B39")
        case .emrald: return Color(hex: "#6B9B7B")
        case .sand: return Color(hex: "#D4923B")
        case .deepIndigo: return Color(hex: "#4B5FA8")
        case .amber: return Color(hex: "#F59E0B")
        case .crismon: return Color(hex: "#DC5F5F")
        case .violet: return Color(hex: "#8B5CF6")
        }
    }
    
    private func loadPlotContainer() {
        let context = AppDataContainer.shared.container.mainContext
        let storyId = story.id
        
        let descriptor = FetchDescriptor<PlotContainer>(
            predicate: #Predicate { $0.storyId == storyId }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            plotContainer = existing
        } else {
            let newContainer = PlotContainer(
                storyId: story.id,
                beginingPlotSections: [],
                conflictPlotSections: [],
                developmentPlotSections: [],
                climaxPlotSections: [],
                resolutionPlotSections: [],
                customPlotSections: []
            )
            context.insert(newContainer)
            try? context.save()
            plotContainer = newContainer
        }
    }
    
    private func loadCharacters() {
        let context = AppDataContainer.shared.container.mainContext
        let storyId = story.id
        
        let descriptor = FetchDescriptor<CharacterModel>(
            predicate: #Predicate { $0.storyId == storyId }
        )
        characters = (try? context.fetch(descriptor)) ?? []
    }
    
    private func addScene(_ scene: PlotSceneModel, to section: PlotSection) {
        guard let container = plotContainer else { return }
        let context = AppDataContainer.shared.container.mainContext
        
        switch section {
        case .beginning:
            container.beginingPlotSections.append(scene)
        case .conflict:
            container.conflictPlotSections.append(scene)
        case .development:
            container.developmentPlotSections.append(scene)
        case .climax:
            container.climaxPlotSections.append(scene)
        case .resolution:
            container.resolutionPlotSections.append(scene)
        case .custom(let id):
            if let customSection = container.customPlotSections.first(where: { $0.id == id }) {
                customSection.scenes.append(scene)
            }
        }
        
        try? context.save()
        loadPlotContainer()
    }
    
    private func addCustomSection(_ customSection: CustomPlotSection) {
        guard let container = plotContainer else { return }
        let context = AppDataContainer.shared.container.mainContext
        container.customPlotSections.append(customSection)
        try? context.save()
        loadPlotContainer()
    }
}

struct AddSceneView: View {
    let story: StoryModel
    let section: PlotView.PlotSection
    let characters: [CharacterModel]
    let editingScene: PlotSceneModel?
    let onSave: (PlotSceneModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var sceneDescription: String = ""
    @State private var selectedCharacters: [CharacterModel] = []
    @State private var timelinePosition: TimeLinePosition = .auto
    @State private var emotionalTone: EmotionalTone?
    @State private var showCharacterPicker = false
    
    init(story: StoryModel, section: PlotView.PlotSection, characters: [CharacterModel], editingScene: PlotSceneModel? = nil, onSave: @escaping (PlotSceneModel) -> Void) {
        self.story = story
        self.section = section
        self.characters = characters
        self.editingScene = editingScene
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#2D2470"), Color(hex: "#0D0D2B")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        titleField
                        descriptionField
                        characterSection
                        timelineSection
                        toneSection
                        
                        saveButton
                        cancelButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .dismissKeyboardOnTap()
        .onAppear {
            fillFromEditing()
        }
        .sheet(isPresented: $showCharacterPicker) {
            CharacterMultiPickerSheet(
                items: characters,
                selected: selectedCharacters
            ) { picked in
                selectedCharacters = picked
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(editingScene == nil ? "Add Scene" : "Edit Scene")
                    .font(.custom("Inter-Bold", size: 22))
                    .foregroundColor(.white)
                
                Text(sectionName)
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(Color(hex: "#F5C542"))
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var sectionName: String {
        switch section {
        case .beginning: return "Beginning"
        case .conflict: return "Conflict"
        case .development: return "Development"
        case .climax: return "Climax"
        case .resolution: return "Resolution"
        case .custom: return "Custom Section"
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCENE TITLE *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("Give this scene a title...", text: $title)
                .font(.custom("Inter-Regular", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#5246C9").opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCENE DESCRIPTION *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("What happens? Who is involved? What changes?", text: $sceneDescription, axis: .vertical)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.white)
                .padding(16)
                .frame(minHeight: 120, alignment: .topLeading)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#5246C9").opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var characterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INVOLVED CHARACTERS")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            if selectedCharacters.isEmpty {
                Button {
                    showCharacterPicker = true
                } label: {
                    HStack {
                        Text("No characters selected")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(hex: "#1A1650").opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#5246C9").opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showCharacterPicker = true
                } label: {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedCharacters, id: \.id) { character in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: "#F5C542").opacity(0.2))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Text(String(character.name.prefix(1)).uppercased())
                                                .font(.custom("Inter-Bold", size: 12))
                                                .foregroundColor(Color(hex: "#F5C542"))
                                        )
                                    
                                    Text(character.name)
                                        .font(.custom("Inter-Medium", size: 13))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#1A1650").opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#1A1650").opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#5246C9").opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TIMELINE POSITION")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            HStack(spacing: 12) {
                timelineButton(position: .auto, title: "Auto")
                timelineButton(position: .before, title: "Before...")
                timelineButton(position: .after, title: "After...")
            }
        }
    }
    
    private func timelineButton(position: TimeLinePosition, title: String) -> some View {
        Button {
            timelinePosition = position
        } label: {
            Text(title)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(timelinePosition == position ? Color(hex: "#F5C542") : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    timelinePosition == position ?
                    Color(hex: "#5246C9").opacity(0.4) :
                    Color(hex: "#1A1650").opacity(0.3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            timelinePosition == position ?
                            Color(hex: "#F5C542").opacity(0.6) :
                            Color(hex: "#5246C9").opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EMOTIONAL TONE (optional)")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            let tones: [(EmotionalTone, String, String)] = [
                (.tense, "Tense", "⚡️"),
                (.hopeful, "Hopeful", "🟧"),
                (.dark, "Dark", "🌑"),
                (.revaling, "Revealing", "✨"),
                (.political, "Political", "⚔️")
            ]
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(tones, id: \.0) { tone in
                    Button {
                        if emotionalTone == tone.0 {
                            emotionalTone = nil
                        } else {
                            emotionalTone = tone.0
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(tone.2)
                                .font(.system(size: 18))
                            
                            Text(tone.1)
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(emotionalTone == tone.0 ? .white : .white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            emotionalTone == tone.0 ?
                            Color(hex: "#5246C9").opacity(0.4) :
                            Color(hex: "#1A1650").opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    emotionalTone == tone.0 ?
                                    Color(hex: "#F5C542").opacity(0.6) :
                                    Color(hex: "#5246C9").opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(editingScene == nil ? "Save Scene" : "Update Scene")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(canSave ? .white : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    canSave ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#6B5AED"), Color(hex: "#5246C9")]),
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#2D2470").opacity(0.5), Color(hex: "#2D2470").opacity(0.5)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.top, 8)
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    
    private var canSave: Bool {
        !title.isEmpty && !sceneDescription.isEmpty
    }
    
    private func fillFromEditing() {
        guard let scene = editingScene else { return }
        title = scene.title
        sceneDescription = scene.sceneDescription
        selectedCharacters = scene.getCharacters(from: characters)
        timelinePosition = scene.timelinePosition
        emotionalTone = scene.emotionalTone
    }
    
    private func save() {
        let context = AppDataContainer.shared.container.mainContext
        let characterIds = selectedCharacters.map { $0.id }
        
        if let scene = editingScene {
            scene.title = title
            scene.sceneDescription = sceneDescription
            scene.characterIds = characterIds
            scene.timelinePosition = timelinePosition
            scene.emotionalTone = emotionalTone
            
            try? context.save()
            dismiss()
        } else {
            let scene = PlotSceneModel(
                title: title,
                sceneDescription: sceneDescription,
                characterIds: characterIds,
                timelinePosition: timelinePosition,
                emotionalTone: emotionalTone
            )
            context.insert(scene)
            try? context.save()
            onSave(scene)
            dismiss()
        }
    }
}

struct CharacterMultiPickerSheet: View {
    let items: [CharacterModel]
    let selected: [CharacterModel]
    let onSelect: ([CharacterModel]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: Set<UUID>
    
    init(items: [CharacterModel], selected: [CharacterModel], onSelect: @escaping ([CharacterModel]) -> Void) {
        self.items = items
        self.selected = selected
        self.onSelect = onSelect
        self._selectedItems = State(initialValue: Set(selected.map { $0.id }))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#2D2470"), Color(hex: "#0D0D2B")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text("No Characters Yet")
                                .font(.custom("Inter-Bold", size: 18))
                                .foregroundColor(.white)
                            
                            Text("Add characters in the Characters tab first.")
                                .font(.custom("Inter-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                } else {
                    List(items) { item in
                        Button {
                            if selectedItems.contains(item.id) {
                                selectedItems.remove(item.id)
                            } else {
                                selectedItems.insert(item.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: "#F5C542").opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Text(String(item.name.prefix(1)).uppercased())
                                            .font(.custom("Inter-Bold", size: 14))
                                            .foregroundColor(Color(hex: "#F5C542"))
                                    )
                                
                                Text(item.name)
                                    .font(.custom("Inter-Medium", size: 15))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if selectedItems.contains(item.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color(hex: "#F5C542"))
                                }
                            }
                        }
                        .listRowBackground(Color(hex: "#1A1650").opacity(0.4))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Characters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#F5C542"))
                }
                if !items.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            let selected = items.filter { selectedItems.contains($0.id) }
                            onSelect(selected)
                            dismiss()
                        }
                        .foregroundColor(Color(hex: "#F5C542"))
                    }
                }
            }
        }
    }
}

struct CreateCustomSectionView: View {
    let onSave: (CustomPlotSection) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var sectionName: String = ""
    @State private var sectionType: SectionType = .stiryPhase
    @State private var position: PositionInStory = .addAtEnd
    @State private var sectionColor: SectionColor = .gold
    
    private let suggestedNames = ["The Fall", "Prophecy", "Redemption", "Turning Point", "Epilogue"]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#2D2470"), Color(hex: "#0D0D2B")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        nameSection
                        typeSection
                        colorSection
                        
                        saveButton
                        cancelButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Create New Plot Section")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                Text("Structure your story arc")
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SECTION NAME *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("e.g. Betrayal, The Journey, Revelation...", text: $sectionName)
                .font(.custom("Inter-Medium", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedNames, id: \.self) { name in
                        Button {
                            sectionName = name
                        } label: {
                            Text(name)
                                .font(.custom("Inter-Medium", size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#1A1650").opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECTION TYPE (optional)")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            let items: [(SectionType, String)] = [
                (.stiryPhase, "Story Phase"),
                (.flashback, "Flashback"),
                (.parallelAct, "Parallel Arc"),
                (.politicalAct, "Political Arc"),
                (.romanceArc, "Romance Arc"),
                (.custom, "Custom")
            ]
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(items, id: \.0) { item in
                    Button {
                        sectionType = item.0
                    } label: {
                        Text(item.1)
                            .font(.custom("Inter-Medium", size: 13))
                            .foregroundColor(sectionType == item.0 ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(sectionType == item.0 ? Color(hex: "#3D3680").opacity(0.8) : Color(hex: "#1A1650").opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECTION COLOUR")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            let colors: [(SectionColor, String, Color)] = [
                (.gold, "Gold", Color(hex: "#F5C542")),
                (.burntOrange, "Burnt\nOrange", Color(hex: "#E07B39")),
                (.emrald, "Emerald", Color(hex: "#6B9B7B")),
                (.sand, "Sand", Color(hex: "#D4923B")),
                (.deepIndigo, "Deep Indigo", Color(hex: "#4B5FA8")),
                (.amber, "Amber", Color(hex: "#F59E0B")),
                (.crismon, "Crimson", Color(hex: "#DC5F5F")),
                (.violet, "Violet", Color(hex: "#8B5CF6"))
            ]
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(colors, id: \.0) { color in
                    Button {
                        sectionColor = color.0
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(color.2)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(sectionColor == color.0 ? Color.white : Color.clear, lineWidth: 3)
                                        .padding(-4)
                                )
                            
                            Text(color.1)
                                .font(.custom("Inter-Medium", size: 11))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(height: 80)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Add Section")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(canSave ? .white : .white.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    canSave ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#6B5AED"), Color(hex: "#5246C9")]),
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#2D2470").opacity(0.5), Color(hex: "#2D2470").opacity(0.5)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    
    private var canSave: Bool {
        !sectionName.isEmpty
    }
    
    private func save() {
        let context = AppDataContainer.shared.container.mainContext
        let customSection = CustomPlotSection(
            name: sectionName,
            sectionType: sectionType,
            position: position,
            sectionColor: sectionColor,
            scenes: []
        )
        context.insert(customSection)
        try? context.save()
        onSave(customSection)
        dismiss()
    }
}

struct EditCustomSectionView: View {
    let customSection: CustomPlotSection
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var sectionName: String
    @State private var sectionColor: SectionColor
    
    init(customSection: CustomPlotSection, onSave: @escaping () -> Void) {
        self.customSection = customSection
        self.onSave = onSave
        self._sectionName = State(initialValue: customSection.name)
        self._sectionColor = State(initialValue: customSection.sectionColor)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#2D2470"), Color(hex: "#0D0D2B")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        nameSection
                        colorSection
                        
                        saveButton
                        cancelButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Section")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Custom section")
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SECTION NAME *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("Section name", text: $sectionName)
                .font(.custom("Inter-Medium", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
                Text("SECTION COLOUR")
                    .font(.custom("Inter-Medium", size: 11))
                    .tracking(1)
                    .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            }
            
            let colors: [(SectionColor, String, Color)] = [
                (.gold, "Gold", Color(hex: "#F5C542")),
                (.burntOrange, "Burnt", Color(hex: "#E07B39")),
                (.emrald, "Emerald", Color(hex: "#6B9B7B")),
                (.sand, "Sand", Color(hex: "#D4923B")),
                (.deepIndigo, "Deep", Color(hex: "#4B5FA8")),
                (.amber, "Amber", Color(hex: "#F59E0B")),
                (.crismon, "Crimson", Color(hex: "#DC5F5F")),
                (.violet, "Violet", Color(hex: "#8B5CF6"))
            ]
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(colors, id: \.0) { color in
                    Button {
                        sectionColor = color.0
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(color.2)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(sectionColor == color.0 ? Color.white : Color.clear, lineWidth: 3)
                                        .padding(-4)
                                )
                            
                            Text(color.1)
                                .font(.custom("Inter-Medium", size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Save Changes")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(Color(hex: "#0D0D2B"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#F5C542"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.custom("Inter-Bold", size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
    
    private func save() {
        customSection.name = sectionName
        customSection.sectionColor = sectionColor
        let context = AppDataContainer.shared.container.mainContext
        try? context.save()
        onSave()
        dismiss()
    }
}
