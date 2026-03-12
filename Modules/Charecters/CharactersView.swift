import SwiftUI
import SwiftData
import Observation

@Observable
class CharactersViewModel {
    var storyId: UUID
    var characters: [CharacterModel] = []
    
    init(story: StoryModel) {
        self.storyId = story.id
    }
    
    func fetch() {
        do {
            let storyId = self.storyId
            let descriptor = FetchDescriptor<CharacterModel>(
                predicate: #Predicate { $0.storyId == storyId },
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            let context = AppDataContainer.shared.container.mainContext
            characters = try context.fetch(descriptor)
        } catch {
            print("Fetch characters error: \(error)")
            characters = []
        }
    }
    
    func delete(_ character: CharacterModel) {
        let context = AppDataContainer.shared.container.mainContext
        context.delete(character)
        do {
            try context.save()
            fetch()
        } catch {
            print("Delete character error: \(error)")
        }
    }
}

@Observable
class CreateCharacterViewModel {
    var storyId: UUID
    var editingCharacter: CharacterModel?
    
    var name: String = ""
    var role: Role = .main
    var age: String = ""
    var origin: String = ""
    var traits: String = ""
    var motivation: String = ""
    var internalConflict: String = ""
    var secret: String = ""
    var status: Status = .alive
    var notes: String = ""
    
    init(story: StoryModel, character: CharacterModel? = nil) {
        self.storyId = story.id
        self.editingCharacter = character
        
        if let character {
            name = character.name
            role = character.role
            age = character.age == 0 ? "" : "\(character.age)"
            origin = character.origin
            traits = character.traits ?? ""
            motivation = character.motivation ?? ""
            internalConflict = character.internalConflict ?? ""
            secret = character.secret ?? ""
            status = character.status
            notes = character.notes ?? ""
        }
    }
    
    func save() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOrigin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        let ageValue = Int(age.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let context = AppDataContainer.shared.container.mainContext
        
        if let editingCharacter {
            editingCharacter.name = trimmedName
            editingCharacter.role = role
            editingCharacter.age = ageValue
            editingCharacter.origin = trimmedOrigin
            editingCharacter.traits = traits.trimmedOrNil
            editingCharacter.motivation = motivation.trimmedOrNil
            editingCharacter.internalConflict = internalConflict.trimmedOrNil
            editingCharacter.secret = secret.trimmedOrNil
            editingCharacter.status = status
            editingCharacter.notes = notes.trimmedOrNil
        } else {
            let model = CharacterModel(
                storyId: storyId,
                name: trimmedName,
                role: role,
                age: ageValue,
                origin: trimmedOrigin,
                traits: traits.trimmedOrNil,
                motivation: motivation.trimmedOrNil,
                internalConflict: internalConflict.trimmedOrNil,
                secret: secret.trimmedOrNil,
                status: status,
                notes: notes.trimmedOrNil
            )
            context.insert(model)
        }
        
        do {
            try context.save()
            return true
        } catch {
            print("Save character error: \(error)")
            return false
        }
    }
}

struct CharactersView: View {
    let story: StoryModel
    @State private var viewModel: CharactersViewModel
    @State private var isCreate = false
    @State private var editCharacter: CharacterModel?
    @State private var expandedId: UUID?
    
    @State private var isDeleteAlert = false
    @State private var characterToDelete: CharacterModel?
    
    private let cardBg = Color(red: 30/255, green: 24/255, blue: 92/255)
    private let cardBorder = Color(red: 196/255, green: 164/255, blue: 72/255)
    private let textColor = Color.white.opacity(0.7)
    private let accent = Color(red: 245/255, green: 199/255, blue: 72/255)
    
    init(story: StoryModel) {
        self.story = story
        _viewModel = State(initialValue: CharactersViewModel(story: story))
    }
    
    var body: some View {
        VStack {
            if viewModel.characters.isEmpty {
                Spacer()
                Image("chEmpty")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 190.fitH)
                Spacer()
            } else {
                List {
                    ForEach(viewModel.characters, id: \.id) { character in
                        characterRow(character, isExpanded: expandedId == character.id)
                            .listRowInsets(EdgeInsets(top: 6.fitH, leading: 16, bottom: 6.fitH, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editCharacter = character
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    characterToDelete = character
                                    isDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            
            addButton
                .padding(.horizontal, 16)
                .padding(.top, 12.fitH)
                .padding(.bottom, 16.fitH)
        }
        .onAppear {
            viewModel.fetch()
        }
        .sheet(isPresented: $isCreate) {
            CreateCharacterView(viewModel: CreateCharacterViewModel(story: story)) {
                viewModel.fetch()
            }
        }
        .sheet(item: $editCharacter) { character in
            CreateCharacterView(viewModel: CreateCharacterViewModel(story: story, character: character)) {
                viewModel.fetch()
            }
        }
        .alert("Delete character?", isPresented: $isDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let characterToDelete {
                    viewModel.delete(characterToDelete)
                }
                characterToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                characterToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func characterRow(_ character: CharacterModel, isExpanded: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(roleColor(character.role))
                                .frame(width: 44, height: 44)
                            Text(character.name.firstLetter)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(character.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 8) {
                                rolePill(character.role)
                                Text("Age \(character.age)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(textColor)
                                Text("• \(character.origin)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(textColor)
                            }
                        }
                        
                        Spacer()
                    }
                    HStack {
                        statusPill(character.status)
                            .padding(.leading, 50.fitW)
                        Spacer()
                    }
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedId = isExpanded ? nil : character.id
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(textColor)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 12) {
                    if let traits = character.traits, !traits.isEmpty {
                        sectionTitle("TRAITS")
                        sectionText(traits)
                    }
                    
                    if let motivation = character.motivation, !motivation.isEmpty {
                        sectionTitle("MOTIVATION")
                        sectionText(motivation)
                    }
                    
                    if let internalConflict = character.internalConflict, !internalConflict.isEmpty {
                        sectionTitle("INTERNAL CONFLICT")
                        sectionText(internalConflict)
                    }
                    
                    if let secret = character.secret, !secret.isEmpty {
                        sectionTitle("SECRET")
                        sectionText("🔒 \(secret)")
                    }
                    
                    if let notes = character.notes, !notes.isEmpty {
                        sectionTitle("NOTES")
                        sectionText(notes)
                    }
                    
                    HStack {
                        Spacer()
                    }
                }
                .frame(alignment: .leading)
                .padding(14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1.5)
                )
        )
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(accent.opacity(0.7))
            .tracking(2)
    }
    
    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(accent)
    }
    
    private func traitsWrap(_ traits: String) -> some View {
        let items = traits
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .stroke(accent.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }
    
    private var addButton: some View {
        Button {
            isCreate = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add Character")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(0.8), lineWidth: 1.5)
            )
        }
    }
    
    private func rolePill(_ role: Role) -> some View {
        Text(role.title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(roleTextColor(role))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(roleBg(role).opacity(0.2))
            )
    }
    
    private func statusPill(_ status: Status) -> some View {
        Text(status.title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(statusTextColor(status))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(statusBg(status).opacity(0.2))
            )
    }
    
    private func roleColor(_ role: Role) -> Color {
        switch role {
        case .main: return Color(red: 245/255, green: 199/255, blue: 72/255)
        case .supporting: return Color(red: 59/255, green: 210/255, blue: 168/255)
        case .antagonist: return Color(red: 236/255, green: 88/255, blue: 88/255)
        case .other: return Color(red: 141/255, green: 120/255, blue: 255/255)
        }
    }
    
    private func roleBg(_ role: Role) -> Color {
        roleColor(role)
    }
    
    private func roleTextColor(_ role: Role) -> Color {
        roleColor(role)
    }
    
    private func statusBg(_ status: Status) -> Color {
        switch status {
        case .alive: return Color(red: 53/255, green: 210/255, blue: 140/255)
        case .missing: return Color(red: 255/255, green: 206/255, blue: 87/255)
        case .changed: return Color(red: 117/255, green: 160/255, blue: 255/255)
        case .revealed: return Color(red: 245/255, green: 108/255, blue: 199/255)
        }
    }
    
    private func statusTextColor(_ status: Status) -> Color {
        statusBg(status)
    }
}

struct CreateCharacterView: View {
    @Bindable var viewModel: CreateCharacterViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onSaved: () -> Void
    
    private let backgroundColor = Color(red: 29/255, green: 25/255, blue: 82/255)
    private let accentColor = Color(red: 247/255, green: 227/255, blue: 176/255)
    private let borderColor = Color(red: 122/255, green: 106/255, blue: 67/255)
    
    private let roleColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    private let statusColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    
                    sectionTitle("NAME *")
                    inputField("Character name...", text: $viewModel.name)
                    
                    sectionTitle("ROLE")
                    roleGrid
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("AGE")
                            inputField("e.g. 24", text: $viewModel.age, keyboard: .numberPad)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("ORIGIN")
                            inputField("e.g. Medina", text: $viewModel.origin)
                        }
                    }
                    
                    sectionTitle("TRAITS")
                    inputField("Add a trait...", text: $viewModel.traits)
                    
                    sectionTitle("MOTIVATION")
                    inputField("What drives this character?", text: $viewModel.motivation, axis: .vertical, lines: 3...6)
                    
                    sectionTitle("INTERNAL CONFLICT")
                    inputField("What inner struggle does this character face?", text: $viewModel.internalConflict, axis: .vertical, lines: 3...6)
                    
                    sectionTitle("SECRET")
                    inputField("What are they hiding?", text: $viewModel.secret, axis: .vertical, lines: 2...5)
                    
                    sectionTitle("STATUS")
                    statusGrid
                    
                    sectionTitle("NOTES (OPTIONAL)")
                    inputField("Any additional notes...", text: $viewModel.notes, axis: .vertical, lines: 3...6)
                    
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.editingCharacter == nil ? "Add Character" : "Edit Character")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(accentColor)
                Text("Shape your story's cast")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(accentColor)
            .tracking(2)
    }
    
    private func inputField(
        _ placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        axis: Axis = .horizontal,
        lines: ClosedRange<Int> = 1...1
    ) -> some View {
        TextField(placeholder, text: text, axis: axis)
            .lineLimit(lines)
            .submitLabel(.done)
            .keyboardType(keyboard)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.85))
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor.opacity(0.5), lineWidth: 1)
                    )
            )
    }
    
    private var roleGrid: some View {
        LazyVGrid(columns: roleColumns, alignment: .leading, spacing: 10) {
            ForEach(Role.allCases, id: \.self) { role in
                let isSelected = viewModel.role == role
                Button {
                    viewModel.role = role
                } label: {
                    Text(role.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? accentColor : Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(isSelected ? accentColor.opacity(0.9) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var statusGrid: some View {
        LazyVGrid(columns: statusColumns, alignment: .leading, spacing: 10) {
            ForEach(Status.allCases, id: \.self) { status in
                let isSelected = viewModel.status == status
                Button {
                    viewModel.status = status
                } label: {
                    Text(status.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? statusText(status) : Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(isSelected ? statusText(status).opacity(0.9) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            if viewModel.save() {
                onSaved()
                dismiss()
            }
        } label: {
            Text(viewModel.editingCharacter == nil ? "Save Character" : "Update Character")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(canSave ? 1 : 0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(canSave ? 0.12 : 0.06))
                )
        }
        .disabled(!canSave)
        .padding(.top, 6)
    }
    
    private var canSave: Bool {
        !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func statusText(_ status: Status) -> Color {
        switch status {
        case .alive: return Color(red: 53/255, green: 210/255, blue: 140/255)
        case .missing: return Color(red: 255/255, green: 206/255, blue: 87/255)
        case .changed: return Color(red: 117/255, green: 160/255, blue: 255/255)
        case .revealed: return Color(red: 245/255, green: 108/255, blue: 199/255)
        }
    }
}

private extension Role {
    var title: String {
        switch self {
        case .main: return "Main"
        case .supporting: return "Supporting"
        case .antagonist: return "Antagonist"
        case .other: return "Other"
        }
    }
}

private extension Status {
    var title: String {
        switch self {
        case .alive: return "Alive"
        case .missing: return "Missing"
        case .changed: return "Changed"
        case .revealed: return "Revealed"
        }
    }
}

private extension String {
    var firstLetter: String {
        guard let first = self.first else { return "" }
        return String(first).uppercased()
    }
    
    var trimmedOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                content
                    .alignmentGuide(.leading) { dimension in
                        if (width + dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        width += dimension.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
        .frame(minHeight: 0)
    }
}
