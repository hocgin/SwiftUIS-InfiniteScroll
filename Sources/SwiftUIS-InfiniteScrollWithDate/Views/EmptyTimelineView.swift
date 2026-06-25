import SwiftUI

/// 默认空数据视图。
public struct EmptyTimelineView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(L10n.Label.emptyData)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}
