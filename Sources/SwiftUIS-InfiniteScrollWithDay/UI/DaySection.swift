import SwiftUI

/// 单日渲染单元：Sticky Header + 当日内容。
///
/// 内部根据 `DayModel.state` 切换：
/// - `.loaded(items)` → 调用 content 闭包
/// - `.empty` → 调用 emptyDayView（或默认）
/// - `.loading` → LoadingSection
/// - `.failed` → 重试按钮（点击触发 reload）
///
/// Sticky 行为由父 LazyVStack 的 `pinnedViews: [.sectionHeaders]` 决定。
/// 这里只负责把 header 与 content 放进 `Section`。
public struct DaySection<Item: Sendable & Identifiable, Content: View>: View {

    private let model: DayModel<Item>
    private let content: (Date, [Item]) -> Content
    private let sticky: Bool

    @Environment(\.dayHeaderView) private var headerBuilder
    @Environment(\.dayEmptyView) private var emptyBuilder

    public init(
        model: DayModel<Item>,
        sticky: Bool,
        @ViewBuilder content: @escaping (Date, [Item]) -> Content
    ) {
        self.model = model
        self.sticky = sticky
        self.content = content
    }

    public var body: some View {
        if sticky {
            stickySection
        } else {
            flatSection
        }
    }

    // MARK: - Sticky（pinned）

    private var stickySection: some View {
        Section {
            contentView
        } header: {
            headerView
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }

    // MARK: - Flat（非 pinned）

    private var flatSection: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
    }

    // MARK: - 子视图

    @ViewBuilder
    private var headerView: some View {
        if let builder = headerBuilder.builder {
            builder(model.day)
        } else {
            DayHeader(date: model.day)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch model.state {
        case .loading:
            LoadingSection()
        case .empty:
            if let builder = emptyBuilder.builder {
                builder()
            } else {
                EmptyDayView()
            }
        case .loaded(let items):
            content(model.day, items)
        case .failed:
            FailedRetryHint()
        }
    }
}

/// 失败重试提示（默认）。
///
/// 不内置重试逻辑（重试需访问 Controller），仅作为占位。
/// 用户若需重试，可在自定义修饰符里用 EnvironmentObject / @Environment 拿到 Controller。
public struct FailedRetryHint: View {

    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text("加载失败")
                .foregroundStyle(.secondary)
                .font(.callout)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
