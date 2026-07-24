import SwiftUI
import UIKit

/// Shows the selected POH image with an animated scanning line while the AI
/// analyses it, giving clear feedback that work is in progress.
struct AnalyzingScanView: View {
    let image: UIImage
    var isAnalyzing: Bool

    @State private var scanOffset: CGFloat = -1

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: Theme.cornerRadius))
                .overlay {
                    if isAnalyzing {
                        scanOverlay
                    }
                }
                .overlay(alignment: .bottom) {
                    if isAnalyzing {
                        analyzingLabel
                            .padding(12)
                    }
                }
        }
        .animation(.easeInOut, value: isAnalyzing)
    }

    private var scanOverlay: some View {
        GeometryReader { proxy in
            let height = proxy.size.height

            ZStack(alignment: .top) {
                Theme.accent.opacity(0.10)

                LinearGradient(
                    colors: [.clear, Theme.accent.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                .offset(y: scanOffset * height)
                .blur(radius: 2)
            }
            .clipShape(.rect(cornerRadius: Theme.cornerRadius))
            .onAppear {
                scanOffset = -0.1
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    scanOffset = 1.0
                }
            }
        }
    }

    private var analyzingLabel: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("KI analysiert POH-Tabelle …")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: .capsule)
    }
}
