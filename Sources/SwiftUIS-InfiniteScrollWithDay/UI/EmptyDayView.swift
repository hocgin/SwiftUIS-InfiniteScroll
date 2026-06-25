import SwiftUI

/// 默认空日视图：浅色卡片提示「当天无数据」。
///
/// 用户可通过 `.emptyDayView { ... }` 修饰符替换。
public struct EmptyDayView: View {

    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray")
                .foregroundStyle(.secondary)
            Text(L10n.Label.emptyDay)
                .foregroundStyle(.secondary)
                .font(.callout)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
