import SwiftUI

struct BgView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Image(.bg)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
                content
        }
    }
}
