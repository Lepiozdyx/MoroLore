import SwiftUI

struct OnboardView: View {
    var onEnd: () -> Void
    @State var state: OnboardState = .first
    var isSE: Bool { UIScreen.isIphoneSEClassic }

    var body: some View {
        BgView {
            VStack {
                if isSE {
                    Image(state.rawValue)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .padding(.top)
                } else {
                    Image(state.rawValue)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                
                Spacer()
                
                Button(action: {
                    switch state {
                    case .first:
                        state = .second
                    case .second:
                        state = .third
                    case .third:
                        state = .fourth
                    case .fourth:
                        onEnd()
                    }
                }) {
                    if state == .first || state == .second {
                        Image(.nextBtn)
                            .resizable().scaledToFit().padding()
                    } else {
                        Image(.startBtn)
                            .resizable().scaledToFit().padding()
                    }
                }
                .padding(.bottom, 50.fitH)
            }
            .padding(.top, 50.fitH)
        }
    }
}

enum OnboardState: String, CaseIterable {
    case first, second, third, fourth
}
