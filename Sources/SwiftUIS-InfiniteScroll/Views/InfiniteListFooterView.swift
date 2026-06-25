import SwiftUI

/// 默认底部状态视图（加载中 / 失败 / 无更多）。
public struct InfiniteListFooterView: View {

    private let footerState: InfiniteFooterState
    private let retry: () -> Void

    public init(footerState: InfiniteFooterState, retry: @escaping () -> Void) {
        self.footerState = footerState
        self.retry = retry
    }

    @ViewBuilder
    public var body: some View {
        switch footerState {
        case .none:
            EmptyView()

        case .loading:
            HStack(spacing: 8) {
                Spacer()
                ProgressView()
                Text(L10n.Label.loading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 16)

        case .failed:
            Button(action: retry) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text(L10n.Label.loadFailedWithHint)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

        case .noMore:
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text(L10n.Label.noMore)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
    }
}
