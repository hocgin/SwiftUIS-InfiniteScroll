import SwiftUI

/// 默认空数据视图。
public struct EmptyTimelineView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("暂无数据")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}
