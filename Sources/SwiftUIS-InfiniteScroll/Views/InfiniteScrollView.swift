import SwiftUI

/// 通用无限滚动列表主组件。
///
/// 提供：
/// - 游标分页（`load(nextId:) -> Page<Item>`）
/// - 预加载策略（`.fixed(N)` / `.ratio(0.8)`）
/// - 错误重试（首次失败 + 分页失败均不丢数据）
/// - 自定义 Empty / Loading / Error / Footer
///
/// 不依赖任何业务模型（无 Date / Timeline 概念）。
///
/// **下拉刷新默认关闭**：需要时由调用方主动附加：
/// ```swift
/// InfiniteScrollView(store: store) { item in FeedRow(item) }
///     .refreshable { await store.reloadAsync() }
/// ```
///
/// 用法：
/// ```swift
/// let store = InfiniteStore(loader: FeedLoader())
/// InfiniteScrollView(store: store) { item in
///     FeedRow(item)
/// }
/// .listEmptyView { EmptyState() }
/// .listLoadingView { SkeletonView() }
/// .listErrorView { error, retry in ErrorView(error, retry) }
/// ```
public struct InfiniteScrollView<Item: Sendable & Identifiable, Content: View>: View where Item.ID: Sendable {

    @State private var store: InfiniteStore<Item>
    @ViewBuilder private let content: (Item) -> Content
    private let scrollProxyBinding: Binding<InfiniteScrollViewInfiniteScrollProxy<Item>?>?

    /// 自定义能力 builder（由 modifier 设置）。`var` 让副本可修改以支持链式调用。
    private var emptyBuilder: EmptyBuilder?
    private var loadingBuilder: LoadingBuilder?
    private var errorBuilder: ErrorViewBuilder?
    private var footerBuilder: FooterBuilder?

    /// ScrollView 顶部整体 header 视图工厂（由 `.headerView {}` 设置）。`nil` 不渲染。
    private var headerViewBuilder: (() -> AnyView)?

    /// 当前滚动位置（绑定到 ScrollView）。
    @State private var scrollPosition: Item.ID?

    public init<L: InfiniteLoader>(
        loader: L,
        preloadStrategy: PreloadStrategy = .defaultStrategy,
        scrollProxy: Binding<InfiniteScrollViewInfiniteScrollProxy<Item>?>? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) where L.Item == Item {
        let store = InfiniteStore<Item>(loader: loader, preloadStrategy: preloadStrategy)
        self._store = State(initialValue: store)
        self.content = content
        self.scrollProxyBinding = scrollProxy
        self.emptyBuilder = nil
        self.loadingBuilder = nil
        self.errorBuilder = nil
        self.footerBuilder = nil
        self.headerViewBuilder = nil
    }

    /// 直接传入 store（多个视图共享同一 store 时用）。
    public init(
        store: InfiniteStore<Item>,
        scrollProxy: Binding<InfiniteScrollViewInfiniteScrollProxy<Item>?>? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self._store = State(initialValue: store)
        self.content = content
        self.scrollProxyBinding = scrollProxy
        self.emptyBuilder = nil
        self.loadingBuilder = nil
        self.errorBuilder = nil
        self.footerBuilder = nil
        self.headerViewBuilder = nil
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let headerViewBuilder {
                    headerViewBuilder()
                }
                if store.items.isEmpty {
                    // 首次加载 / 空 / 错误：在列表内展示全屏状态。
                    firstScreenState
                } else {
                    ForEach(store.items) { item in
                        content(item)
                            .onAppear { checkPreload(for: item) }
                    }
                    footer
                }
            }
        }
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .onChange(of: store.scrollCommand) { _, command in
            guard let command else { return }
            if command.animated {
                withAnimation(.easeInOut(duration: 0.25)) {
                    scrollPosition = command.id
                }
            } else {
                scrollPosition = command.id
            }
        }
        .onAppear {
            scrollProxyBinding?.wrappedValue = InfiniteScrollViewInfiniteScrollProxy(store)
            store.bootstrap()
        }
        .environment(\.emptyBuilder, emptyBuilder ?? .default)
        .environment(\.loadingBuilder, loadingBuilder ?? .default)
        .environment(\.errorViewBuilder, errorBuilder ?? .default)
        .environment(\.footerBuilder, footerBuilder ?? .default)
    }

    // MARK: - 私有

    @ViewBuilder
    private var firstScreenState: some View {
        switch store.state {
        case .idle, .loading:
            if let builder = loadingBuilder?.builder {
                builder()
            } else {
                InfiniteListLoadingView()
            }
        case .empty:
            if let builder = emptyBuilder?.builder {
                builder()
            } else {
                InfiniteListEmptyView()
            }
        case .failed:
            if let builder = errorBuilder?.builder {
                builder(store.lastError ?? NSError(), { store.retry() })
            } else {
                InfiniteListErrorView { store.retry() }
            }
        case .loaded:
            EmptyView()
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let builder = footerBuilder?.builder {
            builder(store.footerState, { store.retry() })
        } else {
            InfiniteListFooterView(footerState: store.footerState) { store.retry() }
        }
    }

    /// 预加载检查：计算当前 item 之后剩余的数量，命中策略则触发 loadMore。
    private func checkPreload(for item: Item) {
        guard let idx = store.items.firstIndex(where: { $0.id == item.id }) else { return }
        let remaining = store.items.count - idx - 1
        store.checkPreload(remaining: remaining)
    }
}

// MARK: - 修饰符（返回同类型副本，支持链式调用）
//
// 参考 ScalingHeaderScrollView 的实现：modifier 创建 struct 副本，更新对应 builder，
// 返回同类型。这样链式 `.emptyView{}.loadingView{}` 不会断类型。

public extension InfiniteScrollView {

    /// 自定义空数据视图。
    func emptyView<V: View>(
        @ViewBuilder _ builder: @escaping () -> V
    ) -> InfiniteScrollView<Item, Content> {
        var copy = self
        copy.emptyBuilder = EmptyBuilder { AnyView(builder()) }
        return copy
    }

    /// 自定义首次加载骨架视图。
    func loadingView<L: View>(
        @ViewBuilder _ builder: @escaping () -> L
    ) -> InfiniteScrollView<Item, Content> {
        var copy = self
        copy.loadingBuilder = LoadingBuilder { AnyView(builder()) }
        return copy
    }

    /// 自定义错误视图。闭包参数：(error, retry)。
    func errorView<E: View>(
        @ViewBuilder _ builder: @escaping (any Error, @escaping () -> Void) -> E
    ) -> InfiniteScrollView<Item, Content> {
        var copy = self
        copy.errorBuilder = ErrorViewBuilder { error, retry in AnyView(builder(error, retry)) }
        return copy
    }

    /// 自定义底部 footer 视图（加载中 / 失败 / 无更多）。
    func footerView<F: View>(
        @ViewBuilder _ builder: @escaping (InfiniteFooterState, @escaping () -> Void) -> F
    ) -> InfiniteScrollView<Item, Content> {
        var copy = self
        copy.footerBuilder = FooterBuilder { state, retry in AnyView(builder(state, retry)) }
        return copy
    }

    /// 在 ScrollView 内容顶部添加整体 header 视图（随内容滚动，非固定吸顶）。
    /// 与 `.emptyView` / `.loadingView` 不同：它是常驻顶部的单一视图，不参与空/加载状态切换。
    func headerView<H: View>(
        @ViewBuilder _ builder: @escaping () -> H
    ) -> InfiniteScrollView<Item, Content> {
        var copy = self
        copy.headerViewBuilder = { AnyView(builder()) }
        return copy
    }
}
