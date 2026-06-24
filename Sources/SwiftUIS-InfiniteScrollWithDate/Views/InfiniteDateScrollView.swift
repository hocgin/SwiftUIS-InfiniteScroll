import SwiftUI

/// 按日期分组的无限滚动时间轴主组件。
///
/// 提供：
/// - 游标分页（`loadPage(nextId:) -> Page<Item>`）
/// - 多粒度分组（day/week/month/year）
/// - 空日填充（`showEmptyDays`）
/// - 预加载（`preloadThreshold`）
/// - 自定义 Cell + Header + Loading + Error + Empty
/// - 下拉刷新
/// - 日期跳转（`scrollProxy.scrollTo(date)`）
///
/// 用法：
/// ```swift
/// InfiniteDateScrollView(
///     loader: MyLoader(),
///     config: .init(grouping: .day, showEmptyDays: true, preloadThreshold: 5)
/// ) { item in
///     RecordCell(item)
/// }
/// .dateHeader { date, grouping in MyHeader(date) }
/// .errorView { error, retry in ErrorView(error, retry) }
/// ```
public struct InfiniteDateScrollView<Item: TimelineItem, Content: View>: View {

    @State private var engine: TimelineEngine<Item>
    @ViewBuilder private let content: (Item) -> Content
    private let scrollProxyBinding: Binding<InfiniteScrollProxy?>?

    /// 自定义能力 builder（由 modifier 设置，var 让副本可修改以支持链式）。
    private var headerBuilder: DateHeaderBuilder?
    private var loadingBuilder: LoadingViewBuilder?
    private var errorBuilder: ErrorViewBuilder?
    private var emptyBuilder: EmptyViewBuilder?

    /// 滚动位置（按 section.date.timeIntervalSince1970）。
    @State private var scrollPosition: TimeInterval?

    /// 完整版 init：自定义所有配置。
    public init<L: TimelineLoader>(
        loader: L,
        config: TimelineConfig = .init(),
        scrollProxy: Binding<InfiniteScrollProxy?>? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) where L.Item == Item {
        let engine = TimelineEngine<Item>(loader: loader, config: config)
        self._engine = State(initialValue: engine)
        self.content = content
        self.scrollProxyBinding = scrollProxy
        self.headerBuilder = nil
        self.loadingBuilder = nil
        self.errorBuilder = nil
        self.emptyBuilder = nil
    }

    /// 便捷 init（PRD 风格，参数扁平化）。
    public init<L: TimelineLoader>(
        loader: L,
        grouping: TimelineGrouping = .day,
        showEmptyDays: Bool = false,
        preloadThreshold: Int = 5,
        restoreScrollPosition: Bool = false,
        scrollProxy: Binding<InfiniteScrollProxy?>? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) where L.Item == Item {
        self.init(
            loader: loader,
            config: .init(
                grouping: grouping,
                showEmptyDays: showEmptyDays,
                preloadThreshold: preloadThreshold,
                restoreScrollPosition: restoreScrollPosition
            ),
            scrollProxy: scrollProxy,
            content: content
        )
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(engine.sections) { section in
                    TimelineSectionView(section: section, grouping: engine.config.grouping) { item in
                        content(item)
                            .onAppear { checkPreload(item, in: section) }
                    }
                    .id(section.id)
                }

                if engine.state == .loading && !engine.sections.isEmpty {
                    bottomLoading
                }

                Color.clear
                    .frame(height: 1)
                    .onAppear { engine.loadNextPage() }
            }
        }
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .onChange(of: engine.scrollCommand) { _, command in
            guard let command else { return }
            scrollPosition = command.key.timeIntervalSince1970
        }
        .overlay {
            if engine.sections.isEmpty {
                firstScreenState
            }
        }
        .refreshable {
            engine.reload()
        }
        .onAppear {
            scrollProxyBinding?.wrappedValue = InfiniteScrollProxy(engine)
            engine.bootstrap()
        }
        .environment(\.dateHeaderBuilder, headerBuilder ?? .default)
        .environment(\.loadingBuilder, loadingBuilder ?? .default)
        .environment(\.errorBuilder, errorBuilder ?? .default)
        .environment(\.emptyBuilder, emptyBuilder ?? .default)
    }

    // MARK: - 私有

    @ViewBuilder
    private var firstScreenState: some View {
        switch engine.state {
        case .loading:
            if let builder = loadingBuilder?.builder {
                builder()
            } else {
                LoadingTimelineView()
            }
        case .empty:
            if let builder = emptyBuilder?.builder {
                builder()
            } else {
                EmptyTimelineView()
            }
        case .failed:
            if let builder = errorBuilder?.builder {
                builder(engine.lastError ?? NSError(), { engine.reload() })
            } else {
                ErrorTimelineView { engine.reload() }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var bottomLoading: some View {
        if let builder = loadingBuilder?.builder {
            builder()
        } else {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding()
        }
    }

    private func checkPreload(_ item: Item, in section: TimelineSection<Item>) {
        let threshold = engine.config.preloadThreshold
        guard let itemIdx = section.items.firstIndex(where: { $0.id == item.id }) else { return }
        guard let sectionIdx = engine.sections.firstIndex(where: { $0.id == section.id }) else { return }

        let remainingInCurrent = section.items.count - itemIdx - 1
        let suffixSections = engine.sections[(sectionIdx + 1)...]
        let remainingInSuffix = suffixSections.reduce(0) { $0 + $1.items.count }

        let total = remainingInCurrent + remainingInSuffix
        if total <= threshold {
            engine.loadNextPage()
        }
    }
}

// MARK: - 修饰符（返回同类型副本）

public extension InfiniteDateScrollView {

    /// 自定义日期头。接收 (date, grouping)。
    func header<H: View>(
        @ViewBuilder _ builder: @escaping (Date, TimelineGrouping) -> H
    ) -> InfiniteDateScrollView<Item, Content> {
        var copy = self
        copy.headerBuilder = DateHeaderBuilder { date, grouping in AnyView(builder(date, grouping)) }
        return copy
    }

    /// 自定义骨架加载视图。
    func loadingView<L: View>(
        @ViewBuilder _ builder: @escaping () -> L
    ) -> InfiniteDateScrollView<Item, Content> {
        var copy = self
        copy.loadingBuilder = LoadingViewBuilder { AnyView(builder()) }
        return copy
    }

    /// 自定义错误视图。闭包参数：(error, retry)。
    func errorView<E: View>(
        @ViewBuilder _ builder: @escaping (any Error, @escaping () -> Void) -> E
    ) -> InfiniteDateScrollView<Item, Content> {
        var copy = self
        copy.errorBuilder = ErrorViewBuilder { error, retry in AnyView(builder(error, retry)) }
        return copy
    }

    /// 自定义空数据视图。
    func emptyView<V: View>(
        @ViewBuilder _ builder: @escaping () -> V
    ) -> InfiniteDateScrollView<Item, Content> {
        var copy = self
        copy.emptyBuilder = EmptyViewBuilder { AnyView(builder()) }
        return copy
    }
}
