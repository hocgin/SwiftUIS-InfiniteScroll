import SwiftUI

/// 默认折叠区间视图：显示「N 天空档 / start - end」。
///
/// 用户可通过 `.gapView { gap in ... }` 修饰符替换。
public struct GapSection: View {

    private let gap: GapRange

    public init(gap: GapRange) {
        self.gap = gap
    }

    public var body: some View {
        VStack(spacing: 4) {
            Text("\(gap.count) 天空档")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(gap.start.referenceDate, format: .dateTime.month(.abbreviated).day())
                Text("~")
                Text(gap.end.referenceDate, format: .dateTime.month(.abbreviated).day())
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
