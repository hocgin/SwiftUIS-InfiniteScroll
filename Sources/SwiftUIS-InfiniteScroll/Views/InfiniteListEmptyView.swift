import SwiftUI

/// 默认空数据视图。
public struct InfiniteListEmptyView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("暂无数据")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 64)
    }
}
