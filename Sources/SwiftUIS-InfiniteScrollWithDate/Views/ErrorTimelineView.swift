import SwiftUI

/// 默认错误视图（带重试按钮）。
public struct ErrorTimelineView: View {

    private let retry: () -> Void

    public init(retry: @escaping () -> Void) {
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text(L10n.Label.loadFailed)
                .font(.headline)
            Button(L10n.Action.retry) { retry() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
