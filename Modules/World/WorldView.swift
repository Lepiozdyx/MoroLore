import SwiftUI
import SwiftData
import Observation

@Observable
class WorldViewModel {
    var worldContainer: WorldContainerModel?
    var categories: [WorldCategoryModel] = []
    
    private let context = AppDataContainer.shared.container.mainContext
    private let storyId: UUID
    
    init(storyId: UUID) {
        self.storyId = storyId
    }
    
    func loadData() {
        loadContainer()
    }
    
    private func loadContainer() {
        let descriptor = FetchDescriptor<WorldContainerModel>(
            predicate: #Predicate { $0.storyId == storyId }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            worldContainer = existing
            categories = existing.categories
        } else {
            let newContainer = WorldContainerModel(storyId: storyId, categories: [])
            context.insert(newContainer)
            try? context.save()
            worldContainer = newContainer
            categories = []
        }
    }
    
    func addCategory(_ category: WorldCategoryModel) {
        guard let container = worldContainer else { return }
        container.categories.append(category)
        try? context.save()
        loadContainer()
    }
    
    func addElement(_ element: WorldCategoryEllementModel, to category: WorldCategoryModel) {
        category.ellements.append(element)
        try? context.save()
        loadContainer()
    }
}

struct WorldView: View {
    @State private var viewModel: WorldViewModel
    @State private var expandedCategories: Set<UUID> = []
    @State private var expandedElements: Set<UUID> = []
    @State private var showAddCategory = false
    @State private var showAddElement = false
    @State private var selectedCategory: WorldCategoryModel?
    
    init(story: StoryModel) {
        _viewModel = State(initialValue: WorldViewModel(storyId: story.id))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#2D2470"), Color(hex: "#0D0D2B")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if viewModel.categories.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView { category in
                viewModel.addCategory(category)
            }
        }
        .sheet(isPresented: $showAddElement) { [selectedCategory] in
            if let category = selectedCategory {
                AddElementView(categoryName: category.name) { element in
                    viewModel.addElement(element, to: category)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "#10B981").opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color(hex: "#10B981").opacity(0.15), lineWidth: 1)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "globe")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(hex: "#10B981").opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text("No world elements yet.")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                Text("Build your universe —\nlocations, lore, politics, and\nhistory.")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showAddCategory = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Add World Element")
                        .font(.custom("Inter-Bold", size: 16))
                }
                .foregroundColor(Color(hex: "#0D0D2B"))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color(hex: "#F5C542"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.id) { category in
                    categoryCard(category)
                }
                
                addCategoryButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
    
    private func categoryCard(_ category: WorldCategoryModel) -> some View {
        let isExpanded = expandedCategories.contains(category.id)
        let gradient = gradientForCategory(category.name)
        
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if isExpanded {
                        expandedCategories.remove(category.id)
                    } else {
                        expandedCategories.insert(category.id)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(category.name.uppercased())
                            .font(.custom("Inter-Bold", size: 20))
                            .foregroundColor(Color(hex: "#0D0D2B"))
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#0D0D2B").opacity(0.6))
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("\(category.ellements.count) elements")
                        .font(.custom("Inter-Medium", size: 14))
                        .foregroundColor(Color(hex: "#0D0D2B").opacity(0.7))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: gradient),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(category.ellements, id: \.id) { element in
                        elementCard(element, categoryColor: gradient[0])
                    }
                    
                    addElementButton(category: category, color: gradient[0])
                }
                .padding(20)
                .background(Color(hex: "#1A1650").opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func elementCard(_ element: WorldCategoryEllementModel, categoryColor: Color) -> some View {
        let isExpanded = expandedElements.contains(element.id)
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                if isExpanded {
                    expandedElements.remove(element.id)
                } else {
                    expandedElements.insert(element.id)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 12, height: 12)
                    
                    Text(element.title)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(element.descriptionModel)
                            .font(.custom("Inter-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let notes = element.storyNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Note:")
                                    .font(.custom("Inter-Medium", size: 12))
                                    .foregroundColor(categoryColor.opacity(0.8))
                                
                                Text(notes)
                                    .font(.custom("Inter-Regular", size: 13))
                                    .italic()
                                    .foregroundColor(categoryColor.opacity(0.9))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#0D0D2B").opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(categoryColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func addElementButton(category: WorldCategoryModel, color: Color) -> some View {
        Button {
            selectedCategory = category
            showAddElement = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("Add \(category.name) Entry")
                    .font(.custom("Inter-Bold", size: 15))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var addCategoryButton: some View {
        Button {
            showAddCategory = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text("Add World Category")
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
    
    private func gradientForCategory(_ name: String) -> [Color] {
        let lowercased = name.lowercased()
        if lowercased.contains("location") || lowercased.contains("place") {
            return [Color(hex: "#F59E0B"), Color(hex: "#F5C542")]
        } else if lowercased.contains("culture") || lowercased.contains("society") {
            return [Color(hex: "#E0A800"), Color(hex: "#F5C542")]
        } else if lowercased.contains("magic") || lowercased.contains("power") {
            return [Color(hex: "#8B5CF6"), Color(hex: "#A78BFA")]
        } else if lowercased.contains("history") || lowercased.contains("lore") {
            return [Color(hex: "#6B9B7B"), Color(hex: "#86EFAC")]
        } else {
            return [Color(hex: "#4B5FA8"), Color(hex: "#6B7BC2")]
        }
    }
}

struct AddCategoryView: View {
    let onSave: (WorldCategoryModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    
    private let suggestions = ["Locations", "Culture", "Magic System", "History", "Politics", "Technology", "Religion", "Creatures"]
    
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
                        
                        saveButton
                        cancelButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Add World Category")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                Text("Create a new category for your world")
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
            Text("CATEGORY NAME *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("e.g. Locations, Magic System...", text: $name)
                .font(.custom("Inter-Medium", size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            name = suggestion
                        } label: {
                            Text(suggestion)
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
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Add Category")
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
        !name.isEmpty
    }
    
    private func save() {
        let context = AppDataContainer.shared.container.mainContext
        let category = WorldCategoryModel(name: name, ellements: [])
        context.insert(category)
        try? context.save()
        onSave(category)
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AddElementView: View {
    let categoryName: String
    let onSave: (WorldCategoryEllementModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var storyNotes: String = ""
    
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
                        notesField
                        
                        saveButton
                        cancelButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add \(categoryName) Entry")
                    .font(.custom("Inter-Bold", size: 20))
                    .foregroundColor(.white)
                
                Text(categoryName)
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
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TITLE *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("Enter title...", text: $title)
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
            Text("DESCRIPTION *")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("Describe this element...", text: $descriptionText, axis: .vertical)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.white)
                .padding(16)
                .frame(minHeight: 100, alignment: .topLeading)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#5246C9").opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STORY NOTES (OPTIONAL)")
                .font(.custom("Inter-Medium", size: 11))
                .tracking(1.2)
                .foregroundColor(Color(hex: "#F3D6A4").opacity(0.7))
            
            TextField("Add notes for your story...", text: $storyNotes, axis: .vertical)
                .font(.custom("Inter-Regular", size: 14))
                .foregroundColor(.white)
                .padding(16)
                .frame(minHeight: 80, alignment: .topLeading)
                .background(Color(hex: "#1A1650").opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#5246C9").opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Save Entry")
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
        !title.isEmpty && !descriptionText.isEmpty
    }
    
    private func save() {
        let context = AppDataContainer.shared.container.mainContext
        let notes = storyNotes.isEmpty ? nil : storyNotes
        let element = WorldCategoryEllementModel(
            title: title,
            descriptionModel: descriptionText,
            storyNotes: notes
        )
        context.insert(element)
        try? context.save()
        onSave(element)
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
