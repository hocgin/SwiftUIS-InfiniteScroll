import SwiftUI

/// 默认折叠区间视图：显示「N 天空档 / start - end」。
///
/// 通过 `@Environment(\.dayGapView)` 读取自定义 builder，未提供时走此默认实现。
/// 用户可用 `.gapView { gap in ... }` 修饰符完全替换。
public struct GapSection: View {

    private let gap: GapRange

    @Environment(\.dayGapView) private var gapBuilder

    public init(gap: GapRange) {
        self.gap = gap
    }

    public var body: some View {
        if let builder = gapBuilder.builder {
            builder(gap)
        } else {
            defaultBody
        }
    }

    /// 默认样式：圆角卡片 + 灰色背景。
    private var defaultBody: some View {
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
