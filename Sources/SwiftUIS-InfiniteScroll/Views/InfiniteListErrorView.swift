import SwiftUI

/// 默认错误视图（带重试）。
public struct InfiniteListErrorView: View {

    private let message: String
    private let retry: () -> Void

    public init(message: String = L10n.Label.loadFailed, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(message)
                .font(.headline)
            Button(L10n.Action.retry) { retry() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
