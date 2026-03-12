import SwiftUI

struct AppContentView: View {
    
    @StateObject private var manager = AppStateManager()
        
    var body: some View {
        Group {
            switch manager.appState {
            case .request:
                LoadingView()
                
            case .support:
                if let url = manager.networkManager.loreURL {
                    WKWebViewManager(
                        url: url,
                        webManager: manager.networkManager
                    )
                } else {
                    WKWebViewManager(
                        url: NetworkManager.initialURL,
                        webManager: manager.networkManager
                    )
                }
                
            case .loading:
                LoadingScreen()
                    .preferredColorScheme(.light)
            }
        }
        .onAppear {
            manager.stateRequest()
        }
    }
}

#Preview {
    AppContentView()
}
