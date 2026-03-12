import SwiftUI
import Observation
import SwiftData

@Observable
class MainViewModel {
    var stories: [StoryModel] = []
    
    func fetch() {
        do {
            let descriptor = FetchDescriptor<StoryModel>()
            let context = AppDataContainer.shared.container.mainContext
            stories = try context.fetch(descriptor)
        } catch {
            print("Fetch stories error: \(error)")
            stories = []
        }
    }
    
    func createStory(title: String, descriptionStory: String, genre: Genre) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = descriptionStory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newStory = StoryModel(
            id: UUID(),
            title: trimmedTitle,
            descriptionStory: trimmedDescription,
            genre: genre
        )
        
        let context = AppDataContainer.shared.container.mainContext
        context.insert(newStory)
        
        do {
            try context.save()
            fetch()
        } catch {
            print("Save story error: \(error)")
        }
    }
    
    func deleteStory(_ story: StoryModel) {
        let context = AppDataContainer.shared.container.mainContext
        context.delete(story)
        
        do {
            try context.save()
            fetch()
        } catch {
            print("Delete story error: \(error)")
        }
    }
}

struct MainView: View {
    @State private var viewModel = MainViewModel()
    @State private var isCreate = false
    @State private var isDeleteAlert = false
    @State private var storyToDelete: StoryModel? = nil
    @State private var selectedStory: StoryModel?
    
    var isSE: Bool { UIScreen.isIphoneSEClassic }
    
    var body: some View {
        NavigationStack {
            BgView {
                VStack {
                    Image(.mainLbl)
                        .resizable().scaledToFit()
                    
                    ZStack(alignment: .bottomTrailing) {
                        if viewModel.stories.isEmpty {
                            VStack {
                                Image(.mainEmpty)
                                    .resizable().scaledToFit().frame(height: 100.fitH).padding()
                                    .frame(maxWidth: .infinity)
                                Spacer()
                            }
                        } else {
                            List {
                                ForEach(viewModel.stories, id: \.id) { story in
                                    NavigationLink(value: story) {
                                        StoryRow(story: story)
                                            .navigationBarBackButtonHidden()
                                            .navigationBarHidden(true)
                                    }
                                    .listRowInsets(EdgeInsets(top: 6.fitH, leading: 16, bottom: 6.fitH, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            storyToDelete = story
                                            isDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            storyToDelete = story
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
                        
                        Button(action: {
                            isCreate = true
                        }) {
                            Image(.plusBtn)
                                .resizable().scaledToFit().frame(height: 120.fitH)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 50.fitH)
                .padding(.vertical, isSE ? 40 : 0)
            }
            .navigationDestination(for: StoryModel.self) { story in
                StoryTabBar(viewModel: StoryTabBarViewModel(story: story))
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.fetch()
        }
        .sheet(isPresented: $isCreate) {
            CreateStoryView(viewModel: viewModel)
        }
        .alert("Delete story?", isPresented: $isDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let storyToDelete {
                    viewModel.deleteStory(storyToDelete)
                }
                storyToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                storyToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct CreateStoryView: View {
    let viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var descriptionStory: String = ""
    @State private var selectedGenre: Genre = .fantasy
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private let backgroundColor = Color(red: 29/255, green: 25/255, blue: 82/255)
    private let accentColor = Color(red: 247/255, green: 227/255, blue: 176/255)
    private let borderColor = Color(red: 122/255, green: 106/255, blue: 67/255)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                header
                
                VStack(alignment: .leading, spacing: 16) {
                    sectionTitle("STORY TITLE *")
                    titleField
                    
                    sectionTitle("STORY DESCRIPTION")
                    descriptionField
                    
                    sectionTitle("CHOOSE A GENRE")
                    genreGrid
                }
                
                Spacer()
                
                saveButton
                cancelButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 24)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Add Your Story")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(accentColor)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(accentColor)
            .tracking(2)
    }
    
    private var titleField: some View {
        TextField("Give your story a title...", text: $title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(accentColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor.opacity(0.6), lineWidth: 1.2)
            )
    }
    
    private var descriptionField: some View {
        TextField("Describe briefly the essence of your story.", text: $descriptionStory, axis: .vertical)
            .lineLimit(4...8)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(accentColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor.opacity(0.6), lineWidth: 1.2)
            )
    }
    
    private var genreGrid: some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
            ForEach(Genre.allCases, id: \.self) { genre in
                let isSelected = selectedGenre == genre
                let textColor = isSelected ? accentColor : Color.white.opacity(0.5)
                let strokeColor = isSelected ? accentColor.opacity(0.9) : Color.white.opacity(0.12)
                
                Button {
                    selectedGenre = genre
                } label: {
                    HStack(spacing: 6) {
                        Text(genre.emoji)
                        Text(genre.title)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(textColor)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .stroke(strokeColor, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            viewModel.createStory(
                title: title,
                descriptionStory: descriptionStory,
                genre: selectedGenre
            )
            dismiss()
        } label: {
            Text("Save Scene")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(canSave ? 1 : 0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(canSave ? 0.15 : 0.08))
                )
        }
        .disabled(!canSave)
        .padding(.top, 6)
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(.top, 6)
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct StoryRow: View {
    let story: StoryModel
    
    private let cardBg = Color(red: 30/255, green: 24/255, blue: 92/255)
    private let cardBorder = Color(red: 196/255, green: 164/255, blue: 72/255)
    private let titleColor = Color.white
    private let textColor = Color.white.opacity(0.6)
    private let pillBg = Color(red: 75/255, green: 54/255, blue: 138/255)
    private let pillBorder = Color(red: 138/255, green: 115/255, blue: 210/255)
    private let accent = Color(red: 245/255, green: 199/255, blue: 72/255)
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(story.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(titleColor)
                
                Text(story.descriptionStory)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(textColor)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    genrePill
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .semibold))
                        Text(story.date.relativeTime)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(textColor)
                }
            }
            
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(cardBorder.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "book")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(accent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1.5)
                )
        )
    }
    
    private var genrePill: some View {
        HStack(spacing: 6) {
            Text(story.genre.title)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color.white.opacity(0.8))
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(pillBg.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(pillBorder.opacity(0.6), lineWidth: 1)
                )
        )
    }
}

private extension Date {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
