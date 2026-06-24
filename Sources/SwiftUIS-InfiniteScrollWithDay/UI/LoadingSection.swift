import SwiftUI

/// 加载视图：默认 ProgressView，可被 `.loadingView {}` 修饰符覆盖。
///
/// 用于：
/// - 某个 DayModel.state == .loading 时的占位
/// - 批次加载时的顶部/底部哨兵附近
public struct LoadingSection: View {

    /// 自定义加载视图（来自 EnvironmentKey）。
    @Environment(\.dayLoadingView) private var loadingView

    public init() {}

    public var body: some View {
        // 默认 ProgressView；调用方可通过 .loadingView 替换。
        if let builder = loadingView.builder {
            builder()
        } else {
            ProgressView()
                .controlSize(.regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }
}
