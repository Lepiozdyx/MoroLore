import SwiftUI

struct LoadingView: View {
    @State private var loading: CGFloat = 0
    
    var body: some View {
        ZStack {
            Image(.icon)
                .resizable()
                .ignoresSafeArea()
                .blur(radius: 10, opaque: true)
            
            Image(.icon)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .scaleEffect(0.9 + (loading * 0.1))
            
            VStack {
                Spacer()
                
                ProgressView()
                    .scaleEffect(1.5)
//                    .colorInvert()
            }
            .padding(.bottom)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                loading = 1
            }
        }
    }
}

#Preview {
    LoadingView()
}
