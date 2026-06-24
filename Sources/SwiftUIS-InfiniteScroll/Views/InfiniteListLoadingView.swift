import SwiftUI

/// 默认首次加载骨架视图。
public struct InfiniteListLoadingView: View {

    private let rowCount: Int

    public init(rowCount: Int = 6) {
        self.rowCount = rowCount
    }

    public var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<rowCount, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 120, height: 10)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .redacted(reason: .placeholder)
    }
}
