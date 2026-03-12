import Foundation
import Combine

@MainActor
final class AppStateManager: ObservableObject {
    
    enum AppState {
        case request
        case support
        case loading
    }
    
    @Published private(set) var appState: AppState = .request
    let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    convenience init() {
        self.init(networkManager: NetworkManager())
    }
    
    func stateRequest() {
        Task { @MainActor in
            do {
                if networkManager.loreURL != nil {
                    appState = .support
                    return
                }
                
                let shouldShowWebView = try await networkManager.checkInitialURL()
                
                if shouldShowWebView {
                    appState = .support
                } else {
                    appState = .loading
                }
                
            } catch {
                appState = .loading
            }
        }
    }
}
