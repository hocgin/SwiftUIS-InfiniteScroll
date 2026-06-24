import SwiftUI

/// 默认骨架加载视图。
public struct LoadingTimelineView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3) { _ in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 40, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 12)
                }
            }
        }
        .padding()
        .redacted(reason: .placeholder)
    }
}
