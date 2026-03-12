import SwiftUI
import Observation

@Observable
class StoryTabBarViewModel {
    var story: StoryModel
    var selectedTab: StoryTabs = .characters
    
    init(story: StoryModel) {
        self.story = story
    }
}

enum StoryTabs: String, CaseIterable {
    case characters, relations, plot, world
}

struct StoryTabBar: View {
    @Bindable var viewModel: StoryTabBarViewModel
    var isSE: Bool { UIScreen.isIphoneSEClassic }
    
    private let backgroundColor = Color(red: 12/255, green: 10/255, blue: 43/255)
    private let accent = Color(red: 245/255, green: 199/255, blue: 72/255)
    private let inactive = Color.white.opacity(0.4)
    private let subtitleColor = Color.white.opacity(0.35)
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        BgView {
            VStack(spacing: 0) {
                navBar
                
                switch viewModel.selectedTab {
                case .characters:
                    CharactersView(story: viewModel.story)
                case .relations:
                    RelationView(story: viewModel.story)
                case .plot:
                    PlotView(story: viewModel.story)
                case .world:
                    WorldView(story: viewModel.story)
                }
                
                tabBar
                    .padding(.bottom, isSE ? 16 : 0)
            }
            .padding(.vertical, isSE ? 50 : 0)
        }
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
    }
    
    private var navBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accent)
                    Text("All Stories")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                }
            }
            
            Text(viewModel.story.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
            
            Text(viewModel.story.genre.title.uppercased())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(subtitleColor)
                .tracking(2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50.fitH)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var tabBar: some View {
        HStack(spacing: 16) {
            tabButton(.characters, icon: "person.2")
            tabButton(.relations, icon: "point.3.filled.connected.trianglepath.dotted")
            tabButton(.plot, icon: "doc.text")
            tabButton(.world, icon: "globe")
        }
        .padding(12.fitH)
        .background(backgroundColor.opacity(0.95))
        .padding(.bottom, 19.fitH)
    }
    
    private func tabButton(_ tab: StoryTabs, icon: String) -> some View {
        let isSelected = viewModel.selectedTab == tab
        
        return Button {
            viewModel.selectedTab = tab
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? accent : Color.white.opacity(0.05))
                        .frame(width: 56, height: 56)
                        .shadow(color: isSelected ? accent.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.black : inactive)
                }
                
                Text(tab.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? accent : inactive)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private extension StoryTabs {
    var title: String {
        switch self {
        case .characters: return "Characters"
        case .relations: return "Relations"
        case .plot: return "Plot"
        case .world: return "World"
        }
    }
}
