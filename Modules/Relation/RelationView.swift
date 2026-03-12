import SwiftUI
import SwiftData
import UIKit
import Foundation

extension RelationshipModel {
    func getCharacterA(from characters: [CharacterModel]) -> CharacterModel? {
        characters.first { $0.id == characterAId }
    }
    
    func getCharacterB(from characters: [CharacterModel]) -> CharacterModel? {
        characters.first { $0.id == characterBId }
    }
}

struct RelationView: View {
    let story: StoryModel

    @State private var relationships: [RelationshipModel] = []
    @State private var characters: [CharacterModel] = []
    @State private var editingRelationship: RelationshipModel?
    @State private var showEditor = false
    @State private var showDetail = false
    @State private var selectedRelation: RelationshipModel?
    @State private var viewMode: ViewMode = .map

    enum ViewMode {
        case map
        case list
    }

    init(story: StoryModel) {
        self.story = story
    }

    var body: some View {
        VStack(spacing: 0) {
            modeSwitcher
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if viewMode == .map {
                mapView
            } else {
                listView
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showEditor) { [editingRelationship] in
            AddEditRelationshipView(
                story: story,
                characters: characters,
                editingRelationship: editingRelationship,
                onSave: {
                    loadData()
                }
            )
        }
        .sheet(isPresented: $showDetail) { [selectedRelation] in
            if let relation = selectedRelation,
               let charA = relation.getCharacterA(from: characters),
               let charB = relation.getCharacterB(from: characters) {
                RelationshipDetailView(
                    relationship: relation,
                    characterA: charA,
                    characterB: charB,
                    onEdit: {
                        editingRelationship = relation
                        showDetail = false
                        showEditor = true
                    },
                    onDelete: {
                        deleteRelationship(relation)
                        showDetail = false
                    }
                )
            }
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            Button {
                viewMode = .map
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Map View")
                        .font(.custom("Inter-Bold", size: 16))
                }
                .foregroundColor(viewMode == .map ? Color(hex: "#0D0D2B") : Color.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewMode == .map ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#F5C542"), Color(hex: "#E0A800")]),
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button {
                viewMode = .list
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16, weight: .semibold))
                    Text("List View")
                        .font(.custom("Inter-Bold", size: 16))
                }
                .foregroundColor(viewMode == .list ? Color(hex: "#0D0D2B") : Color.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewMode == .list ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#F5C542"), Color(hex: "#E0A800")]),
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(Color(hex: "#1A1650").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var mapView: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    diagramView
                        .padding(.top, 12)
                    
                    legendView
                        .padding(.bottom, 100)
                }
            }

            VStack {
                Spacer()
                addButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
    }

    private var diagramView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1650").opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#F5C542").opacity(0.15), lineWidth: 1)
                )

            if relationships.isEmpty {
                VStack(spacing: 12) {
                    Text("No relationships yet")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                    Text("Create connections between characters")
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                GeometryReader { geo in
                    ZStack {
                        ForEach(relationships) { relation in
                            lineBetween(relation: relation, size: geo.size)
                        }

                        ForEach(nodeModels) { node in
                            nodeView(node: node, size: geo.size)
                                .onTapGesture {
                                    if let relation = relationships.first(where: {
                                        $0.characterAId == node.character.id || $0.characterBId == node.character.id
                                    }) {
                                        selectedRelation = relation
                                        showDetail = true
                                    }
                                }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(height: 480)
        .padding(.horizontal, 20)
    }

    private var nodeModels: [CharacterNode] {
        var uniqueIds = Set<UUID>()
        var unique: [CharacterModel] = []
        
        for relation in relationships {
            if let charA = relation.getCharacterA(from: characters), !uniqueIds.contains(charA.id) {
                unique.append(charA)
                uniqueIds.insert(charA.id)
            }
            if let charB = relation.getCharacterB(from: characters), !uniqueIds.contains(charB.id) {
                unique.append(charB)
                uniqueIds.insert(charB.id)
            }
        }
        
        return unique.enumerated().map { idx, c in
            CharacterNode(
                id: c.id,
                character: c,
                initial: String(c.name.prefix(1)).uppercased(),
                point: nodePoint(index: idx, total: max(unique.count, 1))
            )
        }
    }

    private func nodePoint(index: Int, total: Int) -> CGPoint {
        let preset: [CGPoint] = [
            CGPoint(x: 0.50, y: 0.20),
            CGPoint(x: 0.20, y: 0.65),
            CGPoint(x: 0.80, y: 0.65)
        ]
        if index < preset.count { return preset[index] }
        
        let angle = Double(index) * (2 * .pi / Double(max(total, 1)))
        return CGPoint(x: 0.5 + 0.3 * cos(angle), y: 0.5 + 0.3 * sin(angle))
    }

    private func lineBetween(relation: RelationshipModel, size: CGSize) -> some View {
        guard let charA = relation.getCharacterA(from: characters),
              let charB = relation.getCharacterB(from: characters) else {
            return AnyView(EmptyView())
        }
        
        let aNode = nodeModels.first { $0.character.id == charA.id }
        let bNode = nodeModels.first { $0.character.id == charB.id }

        return AnyView(Group {
            if let a = aNode, let b = bNode {
                let color = colorForRelation(relation)
                let isDashed = relation.relationLevel < 50

                ZStack {
                    Path { path in
                        let p1 = CGPoint(x: a.point.x * size.width, y: a.point.y * size.height)
                        let p2 = CGPoint(x: b.point.x * size.width, y: b.point.y * size.height)
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, dash: isDashed ? [8, 6] : []))

                    let midX = (a.point.x + b.point.x) / 2 * size.width
                    let midY = (a.point.y + b.point.y) / 2 * size.height

                    Text(iconForRelation(relation))
                        .font(.system(size: 20))
                        .position(x: midX, y: midY)
                }
            }
        })
    }

    private func colorForRelation(_ relation: RelationshipModel) -> Color {
        if relation.relationLevel < 34 { return Color(hex: "#EF4444") }
        if relation.relationLevel < 67 { return Color(hex: "#F5C542") }
        return Color(hex: "#10B981")
    }

    private func iconForRelation(_ relation: RelationshipModel) -> String {
        switch relation.relationType {
        case .mentor: return "🌿"
        case .rival: return "⚔️"
        case .love: return "✨"
        case .family: return "🌙"
        case .ally: return "🤝"
        case .enemy: return "🔥"
        case .custom: return "🔗"
        }
    }

    private func nodeView(node: CharacterNode, size: CGSize) -> some View {
        let x = node.point.x * size.width
        let y = node.point.y * size.height

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(nodeColor(for: node).opacity(0.15))
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(nodeColor(for: node))
                    .frame(width: 48, height: 48)

                Text(node.initial)
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
            }

            Text(node.character.name)
                .font(.custom("Inter-Medium", size: 13))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .position(x: x, y: y)
    }

    private func nodeColor(for node: CharacterNode) -> Color {
        let connected = relationships.filter {
            $0.characterAId == node.character.id || $0.characterBId == node.character.id
        }
        let avg = connected.isEmpty ? 50 : connected.map(\.relationLevel).reduce(0, +) / connected.count
        if avg < 34 { return Color(hex: "#EF4444") }
        if avg < 67 { return Color(hex: "#F5C542") }
        return Color(hex: "#10B981")
    }

    private var legendView: some View {
        HStack(spacing: 24) {
            legendItem(color: Color(hex: "#EF4444"), title: "Conflict")
            legendItem(color: Color(hex: "#F5C542"), title: "Neutral")
            legendItem(color: Color(hex: "#10B981"), title: "Harmony")
        }
        .padding(.horizontal, 20)
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var addButton: some View {
        Button {
            editingRelationship = nil
            showEditor = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                Text("Add Relationship")
                    .font(.custom("Inter-Bold", size: 16))
            }
            .foregroundColor(Color(hex: "#F5C542"))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "#F5C542").opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var listView: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if relationships.isEmpty {
                        VStack(spacing: 12) {
                            Text("No relationships yet")
                                .font(.custom("Inter-Bold", size: 16))
                                .foregroundColor(.white)
                            Text("Create connections between characters")
                                .font(.custom("Inter-Regular", size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(relationships) { relation in
                            if let charA = relation.getCharacterA(from: characters),
                               let charB = relation.getCharacterB(from: characters) {
                                relationListCard(relation, charA: charA, charB: charB)
                                    .onTapGesture { [relation] in
                                        selectedRelation = relation
                                        showDetail = true
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }

            VStack {
                Spacer()
                addButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
    }

    private func relationListCard(_ relation: RelationshipModel, charA: CharacterModel, charB: CharacterModel) -> some View {
        let gradientColors = gradientForRelation(relation)
        
        return VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text(iconForRelation(relation))
                        .font(.system(size: 28))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(relation.relationType.rawValue.capitalized)
                        .font(.custom("Inter-Bold", size: 15))
                        .foregroundColor(Color(hex: "#10B981"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#10B981").opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Spacer()
                }

                HStack(spacing: 12) {
                    characterBubble(
                        name: charA.name,
                        initial: String(charA.name.prefix(1)),
                        color: Color(hex: "#F5C542")
                    )

                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)

                    characterBubble(
                        name: charB.name,
                        initial: String(charB.name.prefix(1)),
                        color: nodeColor(for: CharacterNode(
                            id: charB.id,
                            character: charB,
                            initial: "",
                            point: .zero
                        ))
                    )

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Intensity")
                            .font(.custom("Inter-Medium", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(intensityTextFor(relation))
                            .font(.custom("Inter-Bold", size: 13))
                            .foregroundColor(colorForRelation(relation))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#EF4444"),
                                            Color(hex: "#F59E0B"),
                                            Color(hex: "#F5C542"),
                                            Color(hex: "#86EFAC"),
                                            Color(hex: "#10B981")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: CGFloat(relation.relationLevel) / 100 * geo.size.width, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                if let desc = relation.relationDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            .padding(20)
        }
        .background(Color(hex: "#1A1650").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func characterBubble(name: String, initial: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initial.uppercased())
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(color)
                )

            Text(name)
                .font(.custom("Inter-Bold", size: 15))
                .foregroundColor(.white)
        }
    }

    private func gradientForRelation(_ relation: RelationshipModel) -> [Color] {
        let level = relation.relationLevel
        if level < 34 {
            return [Color(hex: "#EF4444"), Color(hex: "#DC2626")]
        } else if level < 67 {
            return [Color(hex: "#F59E0B"), Color(hex: "#F5C542")]
        } else {
            return [Color(hex: "#10B981"), Color(hex: "#059669")]
        }
    }

    private func intensityTextFor(_ relation: RelationshipModel) -> String {
        let level = relation.relationLevel
        if level < 34 { return "Tense" }
        if level < 67 { return "Neutral" }
        return "Warm"
    }

    private func loadData() {
        let context = AppDataContainer.shared.container.mainContext
        let storyId = story.id
        
        let relationshipDescriptor = FetchDescriptor<RelationshipModel>(
            predicate: #Predicate { $0.storyId == storyId }
        )
        relationships = (try? context.fetch(relationshipDescriptor)) ?? []
        
        let characterDescriptor = FetchDescriptor<CharacterModel>(
            predicate: #Predicate { $0.storyId == storyId }
        )
        characters = (try? context.fetch(characterDescriptor)) ?? []
    }

    private func deleteRelationship(_ relationship: RelationshipModel) {
        let context = AppDataContainer.shared.container.mainContext
        context.delete(relationship)
        try? context.save()
        loadData()
    }
}

struct CharacterNode: Identifiable {
    let id: UUID
    let character: CharacterModel
    let initial: String
    let point: CGPoint
}

struct RelationshipDetailView: View {
    let relationship: RelationshipModel
    let characterA: CharacterModel
    let characterB: CharacterModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private var intensityColor: Color {
        let v = relationship.relationLevel
        if v < 34 { return Color(hex: "#EF4444") }
        if v < 67 { return Color(hex: "#F5C542") }
        return Color(hex: "#10B981")
    }
    
    private var intensityLabel: String {
        let v = relationship.relationLevel
        if v < 34 { return "Conflict" }
        if v < 67 { return "Neutral" }
        return "Harmony"
    }
    
    private var relationIcon: String {
        switch relationship.relationType {
        case .mentor: return "🌿"
        case .rival: return "⚔️"
        case .love: return "✨"
        case .family: return "🌙"
        case .ally: return "🤝"
        case .enemy: return "🔥"
        case .custom: return "🔗"
        }
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
                        charactersSection
                        typeSection
                        intensitySection
                        
                        if let desc = relationship.relationDescription, !desc.isEmpty {
                            descriptionSection(desc)
                        }
                        
                        actionButtons
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
                Text("Relationship Details")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                Text("View connection between characters")
                    .font(.custom("Inter-Regular", size: 13))
                    .foregroundColor(Color.white.opacity(0.5))
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
    
    private var charactersSection: some View {
        HStack(spacing: 16) {
            characterCard(name: characterA.name, initial: String(characterA.name.prefix(1)))
            
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#F5C542"))
            
            characterCard(name: characterB.name, initial: String(characterB.name.prefix(1)))
        }
    }
    
    private func characterCard(name: String, initial: String) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "#F5C542").opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(initial.uppercased())
                        .font(.custom("Inter-Bold", size: 24))
                        .foregroundColor(Color(hex: "#F5C542"))
                )
            
            Text(name)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "#1A1650").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RELATIONSHIP TYPE")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            HStack(spacing: 12) {
                Text(relationIcon)
                    .font(.system(size: 32))
                
                Text(relationship.relationType.rawValue.capitalized)
                    .font(.custom("Inter-Bold", size: 18))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(hex: "#1A1650").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INTENSITY")
                    .font(.custom("Inter-Medium", size: 11))
                    .tracking(1)
                    .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
                Spacer()
                Text("\(intensityLabel) · \(relationship.relationLevel)")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(intensityColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#EF4444"),
                                    Color(hex: "#F59E0B"),
                                    Color(hex: "#F5C542"),
                                    Color(hex: "#86EFAC"),
                                    Color(hex: "#10B981")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                    
                    Circle()
                        .fill(intensityColor)
                        .frame(width: 24, height: 24)
                        .shadow(color: intensityColor.opacity(0.5), radius: 8, x: 0, y: 2)
                        .position(x: (CGFloat(relationship.relationLevel) / 100) * geo.size.width, y: geo.size.height / 2)
                }
            }
            .frame(height: 24)
        }
    }
    
    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            Text(text)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onEdit()
            } label: {
                Text("Edit Relationship")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#6B5AED"), Color(hex: "#5246C9")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            
            Button {
                onDelete()
            } label: {
                Text("Delete Relationship")
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(Color(hex: "#EF4444"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "#EF4444").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

struct AddEditRelationshipView: View {
    let story: StoryModel
    let characters: [CharacterModel]
    let editingRelationship: RelationshipModel?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var characterA: CharacterModel?
    @State private var characterB: CharacterModel?
    @State private var relationType: RelationType = .ally
    @State private var relationLevel: Double = 50
    @State private var relationDescription: String = ""

    @State private var showPickerA = false
    @State private var showPickerB = false

    init(story: StoryModel, characters: [CharacterModel], editingRelationship: RelationshipModel? = nil, onSave: @escaping () -> Void) {
        self.story = story
        self.characters = characters
        self.editingRelationship = editingRelationship
        self.onSave = onSave
    }

    private var availableCharactersForA: [CharacterModel] {
        if let b = characterB {
            return characters.filter { $0.id != b.id }
        }
        return characters
    }

    private var availableCharactersForB: [CharacterModel] {
        if let a = characterA {
            return characters.filter { $0.id != a.id }
        }
        return characters
    }

    private var canSave: Bool {
        guard let a = characterA, let b = characterB else { return false }
        return a.id != b.id
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
                        characterSelectField(
                            title: "CHARACTER A *",
                            value: characterA?.name ?? "",
                            placeholder: "Select character"
                        ) {
                            showPickerA = true
                        }

                        characterSelectField(
                            title: "CHARACTER B *",
                            value: characterB?.name ?? "",
                            placeholder: "Select character"
                        ) {
                            showPickerB = true
                        }

                        relationTypeSection

                        intensitySection

                        descriptionSection

                        saveButton
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .dismissKeyboardOnTap()
        .onAppear {
            fillFromModel()
        }
        .sheet(isPresented: $showPickerA) {
            CharacterPickerSheet(
                title: "Character A",
                story: story,
                excludeId: characterB?.id,
                selected: characterA
            ) { picked in
                characterA = picked
            }
        }
        .sheet(isPresented: $showPickerB) {
            CharacterPickerSheet(
                title: "Character B",
                story: story,
                excludeId: characterA?.id,
                selected: characterB
            ) { picked in
                characterB = picked
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(editingRelationship == nil ? "Add Relationship" : "Edit Relationship")
                        .font(.custom("Inter-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    Text("Define a connection between characters")
                        .font(.custom("Inter-Regular", size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
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
    }

    private func characterSelectField(title: String, value: String, placeholder: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))

            Button(action: action) {
                HStack {
                    Text(value.isEmpty ? placeholder : value)
                        .font(.custom("Inter-Medium", size: 15))
                        .foregroundColor(value.isEmpty ? Color.white.opacity(0.3) : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var relationTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RELATIONSHIP TYPE")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))

            let items: [(RelationType, String)] = [
                (.mentor, "🌿"), (.rival, "⚔️"), (.love, "✨"), (.family, "🌙"),
                (.ally, "🤝"), (.enemy, "🔥"), (.custom, "🔗")
            ]

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(items, id: \.0) { item in
                    typeButton(type: item.0, icon: item.1)
                }
            }
        }
    }

    private func typeButton(type: RelationType, icon: String) -> some View {
        let selected = relationType == type
        return Button {
            relationType = type
        } label: {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 28))
                Text(type.rawValue.capitalized)
                    .font(.custom("Inter-Medium", size: 11))
                    .lineLimit(1)
            }
            .foregroundColor(selected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                selected ?
                Color(hex: "#3D3680").opacity(0.8) :
                Color(hex: "#1A1650").opacity(0.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("INTENSITY")
                    .font(.custom("Inter-Medium", size: 11))
                    .tracking(1)
                    .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
                Spacer()
                Text("\(intensityLabel) · \(Int(relationLevel))")
                    .font(.custom("Inter-Bold", size: 14))
                    .foregroundColor(intensityColor)
            }

            HStack {
                Label("Conflict", systemImage: "xmark")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundColor(Color(hex: "#EF4444").opacity(0.7))
                Spacer()
                Label("Neutral", systemImage: "diamond")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundColor(Color(hex: "#F5C542").opacity(0.7))
                Spacer()
                Label("Harmony", systemImage: "checkmark")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundColor(Color(hex: "#10B981").opacity(0.7))
            }
            .labelStyle(.iconOnly)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#EF4444"),
                                Color(hex: "#F59E0B"),
                                Color(hex: "#F5C542"),
                                Color(hex: "#86EFAC"),
                                Color(hex: "#10B981")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)

                Circle()
                    .fill(intensityColor)
                    .frame(width: 24, height: 24)
                    .shadow(color: intensityColor.opacity(0.5), radius: 8, x: 0, y: 2)
                    .offset(x: sliderXPosition)
            }
            .frame(height: 32)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateSliderValue(with: value.location.x)
                    }
            )
        }
    }

    private var sliderXPosition: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 40
        return (relationLevel / 100) * (screenWidth - 24)
    }

    private func updateSliderValue(with xPosition: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width - 40
        let clampedX = min(max(0, xPosition), screenWidth - 24)
        relationLevel = (clampedX / (screenWidth - 24)) * 100
    }

    private var intensityLabel: String {
        let v = Int(relationLevel)
        if v < 34 { return "Conflict" }
        if v < 67 { return "Neutral" }
        return "Harmony"
    }

    private var intensityColor: Color {
        let v = Int(relationLevel)
        if v < 34 { return Color(hex: "#EF4444") }
        if v < 67 { return Color(hex: "#F5C542") }
        return Color(hex: "#10B981")
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))

            TextField("Describe this relationship...", text: $relationDescription, axis: .vertical)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.white)
                .padding(16)
                .frame(minHeight: 100, alignment: .topLeading)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(editingRelationship == nil ? "Save Relationship" : "Update Relationship")
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

    private func fillFromModel() {
        guard let relation = editingRelationship else { return }
        characterA = characters.first { $0.id == relation.characterAId }
        characterB = characters.first { $0.id == relation.characterBId }
        relationType = relation.relationType
        relationLevel = Double(relation.relationLevel)
        relationDescription = relation.relationDescription ?? ""
    }

    private func save() {
        guard let a = characterA, let b = characterB, a.id != b.id else { return }

        let text = relationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = text.isEmpty ? nil : text

        let context = AppDataContainer.shared.container.mainContext

        if let relation = editingRelationship {
            relation.storyId = story.id
            relation.characterAId = a.id
            relation.characterBId = b.id
            relation.relationType = relationType
            relation.relationLevel = Int(relationLevel.rounded())
            relation.relationDescription = finalDescription
        } else {
            let model = RelationshipModel(
                storyId: story.id,
                characterAId: a.id,
                characterBId: b.id,
                relationLevel: Int(relationLevel.rounded()),
                relationType: relationType,
                relationDescription: finalDescription
            )
            context.insert(model)
        }

        try? context.save()
        onSave()
        dismiss()
    }
}

struct CharacterPickerSheet: View {
    let title: String
    let story: StoryModel
    let excludeId: UUID?
    let selected: CharacterModel?
    let onSelect: (CharacterModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var items: [CharacterModel] = []

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
                        
                        Text("No Characters Available")
                            .font(.custom("Inter-Bold", size: 18))
                            .foregroundColor(.white)
                        
                        Text("Add characters first")
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    List(items) { item in
                        Button {
                            onSelect(item)
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.name)
                                    .foregroundColor(.white)
                                Spacer()
                                if item.id == selected?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#F5C542"))
                                }
                            }
                        }
                        .listRowBackground(Color(hex: "#1A1650").opacity(0.4))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#F5C542"))
                }
            }
        }
        .onAppear {
            loadCharacters()
        }
    }
    
    private func loadCharacters() {
        let context = AppDataContainer.shared.container.mainContext
        let storyId = story.id
        
        let predicate = #Predicate<CharacterModel> { character in
            character.storyId == storyId
        }
        
        var descriptor = FetchDescriptor<CharacterModel>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.name)]
        
        let allCharacters = (try? context.fetch(descriptor)) ?? []
        
        // Фильтруем по excludeId если нужно
        if let excludeId = excludeId {
            items = allCharacters.filter { $0.id != excludeId }
        } else {
            items = allCharacters
        }
    }
}

// MARK: - Keyboard Dismissal Extension
extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

extension Color {
    init(hex: String) {
        let raw = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&int)
        let r, g, b: UInt64
        switch raw.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 255; g = 255; b = 255
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
