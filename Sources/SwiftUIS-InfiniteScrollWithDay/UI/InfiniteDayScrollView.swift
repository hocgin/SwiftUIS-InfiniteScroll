import SwiftUI

/// 基础版（无数据源）使用的占位 Item 类型。
///
/// 永远不会有数据被加载（StaticDayDataSource 返回空），
/// 仅用于让 `InfiniteDayScrollView<Item, Content>` 的 Item 类型可推断。
public struct PlaceholderItem: Sendable, Identifiable {
    public let id = UUID()
    public init() {}
}

/// 按日期分组的无限滚动主组件。
///
/// 提供三种 init：
/// 1. **基础版** `InfiniteDayScrollView(range:) { day in ... }`：仅按天迭代，无数据源
/// 2. **数据驱动版** `InfiniteDayScrollView(source:) { day, items in ... }`：默认配置
/// 3. **完整版** `InfiniteDayScrollView(source:emptyStrategy:batchSize:...)`：自定义所有
///
/// 修饰符：`.dayHeader {}` / `.emptyDayView {}` / `.gapView {}` / `.loadingView {}`
///
/// 跳转代理（InfiniteDayScrollViewInfiniteScrollProxy）有两种获取方式：
/// - **子视图**用 `@Environment(\.dayScrollProxy)`（自动注入）
/// - **父视图**（如 NavigationStack 的 .toolbar）用 `scrollProxy:` binding 参数传入
///   原因：SwiftUI environment 单向向下，子视图设置的环境值父视图读不到。
public struct InfiniteDayScrollView<Item: Sendable & Identifiable, Content: View>: View {

    @State private var controller: InfiniteScrollController<Item>
    @ViewBuilder private let content: (Date, [Item]) -> Content

    /// 外部传入的 proxy binding，onAppear 时写入，让父视图（如 toolbar）能调用跳转。
    private let scrollProxyBinding: Binding<InfiniteDayScrollViewInfiniteScrollProxy?>?

    /// 自定义能力 builder（由 modifier 设置）。`var` 让副本可修改以支持链式调用。
    private var headerBuilder: DayHeaderViewBuilder?
    private var emptyBuilder: DayEmptyViewBuilder?
    private var gapBuilder: DayGapViewBuilder?
    private var loadingBuilder: DayLoadingViewBuilder?

    /// ScrollView 顶部整体 header 视图工厂（由 `.headerView {}` 设置）。`nil` 不渲染。
    private var headerViewBuilder: (() -> AnyView)?

    /// 基础版：按 DayRange 迭代，无数据源。
    public init(
        range: DayRange,
        scrollProxy: Binding<InfiniteDayScrollViewInfiniteScrollProxy?>? = nil,
        @ViewBuilder content: @escaping (Date) -> Content
    ) where Item == PlaceholderItem {
        let dayCount = max(1, range.end.days(from: range.start) + 1)
        let emptySource = StaticDayDataSource<PlaceholderItem>(storage: [:])
        let controller = InfiniteScrollController<PlaceholderItem>(
            dataSource: AnyDayDataSource(emptySource),
            anchor: range.end.referenceDate,
            config: .init(batchSize: dayCount, emptyStrategy: .showAll)
        )
        self._controller = State(initialValue: controller)
        self.content = { day, _ in content(day) }
        self.scrollProxyBinding = scrollProxy
        self.headerBuilder = nil
        self.emptyBuilder = nil
        self.gapBuilder = nil
        self.loadingBuilder = nil
        self.headerViewBuilder = nil
    }

    /// 数据驱动版（默认配置）。
    public init<Data: DayDataSource>(
        source: Data,
        anchor: Date = Date(),
        scrollProxy: Binding<InfiniteDayScrollViewInfiniteScrollProxy?>? = nil,
        @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
    ) where Data.Item == Item {
        self.init(
            source: source,
            anchor: anchor,
            config: .init(),
            scrollProxy: scrollProxy,
            content: content
        )
    }

    /// 完整版：自定义所有配置。
    public init<Data: DayDataSource>(
        source: Data,
        anchor: Date = Date(),
        config: InfiniteScrollConfig,
        scrollProxy: Binding<InfiniteDayScrollViewInfiniteScrollProxy?>? = nil,
        @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
    ) where Data.Item == Item {
        let controller = InfiniteScrollController<Item>(
            dataSource: AnyDayDataSource(source),
            anchor: anchor,
            config: config
        )
        self._controller = State(initialValue: controller)
        self.content = content
        self.scrollProxyBinding = scrollProxy
        self.headerBuilder = nil
        self.emptyBuilder = nil
        self.gapBuilder = nil
        self.loadingBuilder = nil
        self.headerViewBuilder = nil
    }

    /// 完整版（PRD 风格，参数扁平化）。
    public init<Data: DayDataSource>(
        source: Data,
        emptyStrategy: EmptyStrategy = .collapse,
        batchSize: Int = 30,
        stickyHeader: Bool = true,
        forwardLoading: Bool = false,
        anchor: Date = Date(),
        scrollProxy: Binding<InfiniteDayScrollViewInfiniteScrollProxy?>? = nil,
        @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
    ) where Data.Item == Item {
        self.init(
            source: source,
            anchor: anchor,
            config: InfiniteScrollConfig(
                batchSize: batchSize,
                emptyStrategy: emptyStrategy,
                stickyHeader: stickyHeader,
                forwardLoading: forwardLoading
            ),
            scrollProxy: scrollProxy,
            content: content
        )
    }

    /// 当前滚动位置（绑定到 ScrollView）。
    @State private var scrollPosition: DayKey?

    public var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 0,
                pinnedViews: controller.config.stickyHeader ? [.sectionHeaders] : []
            ) {
                if let headerViewBuilder {
                    headerViewBuilder()
                }
                if controller.config.forwardLoading {
                    Color.clear
                        .frame(height: 1)
                        .id(ScrollAnchors.top)
                        .onAppear { controller.loadMoreFuture() }
                }

                ForEach(controller.sectionItems) { item in
                    sectionItemView(item)
                }

                Color.clear
                    .frame(height: 1)
                    .id(ScrollAnchors.bottom)
                    .onAppear { controller.loadMorePast() }
            }
        }
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .onChange(of: controller.scrollCommand) { _, command in
            guard let command else { return }
            if command.animated {
                withAnimation(.spring(duration: 0.35)) {
                    scrollPosition = command.key
                }
            } else {
                scrollPosition = command.key
            }
        }
        .onAppear {
            scrollProxyBinding?.wrappedValue = InfiniteDayScrollViewInfiniteScrollProxy(controller)
            controller.bootstrap()
        }
        .environment(\.dayHeaderView, headerBuilder ?? .default)
        .environment(\.dayEmptyView, emptyBuilder ?? .default)
        .environment(\.dayGapView, gapBuilder ?? .default)
        .environment(\.dayLoadingView, loadingBuilder ?? .default)
        .environment(\.dayScrollProxy, InfiniteDayScrollViewInfiniteScrollProxy(controller))
    }

    // MARK: - 私有

    @ViewBuilder
    private func sectionItemView(_ item: DaySectionItem<Item>) -> some View {
        switch item {
        case .day(let model):
            DaySection(model: model, sticky: controller.config.stickyHeader) { day, items in
                content(day, items)
            }
            .id(model.key)

        case .gap(let gap):
            GapSection(gap: gap)
                .id(gap.id)

        case .loading:
            LoadingSection()
        }
    }
}

// MARK: - 修饰符（返回同类型副本，支持链式调用）
//
// 参考 ScalingHeaderScrollView 的实现：modifier 创建 struct 副本，更新对应 builder，
// 返回同类型。这样链式 `.dateHeaderView{}.emptyView{}.gapView{}` 不会断类型。

public extension InfiniteDayScrollView {

    /// 自定义日期头。闭包接收 `DayHeaderContext`（含日期、记录数、是否今天等）。
    func dateHeaderView<H: View>(
        @ViewBuilder _ builder: @escaping (DayHeaderContext) -> H
    ) -> InfiniteDayScrollView<Item, Content> {
        var copy = self
        copy.headerBuilder = DayHeaderViewBuilder { context in AnyView(builder(context)) }
        return copy
    }

    /// 自定义空日视图。
    func emptyView<E: View>(
        @ViewBuilder _ builder: @escaping () -> E
    ) -> InfiniteDayScrollView<Item, Content> {
        var copy = self
        copy.emptyBuilder = DayEmptyViewBuilder { AnyView(builder()) }
        return copy
    }

    /// 自定义折叠区间视图。
    func gapView<G: View>(
        @ViewBuilder _ builder: @escaping (GapRange) -> G
    ) -> InfiniteDayScrollView<Item, Content> {
        var copy = self
        copy.gapBuilder = DayGapViewBuilder { gap in AnyView(builder(gap)) }
        return copy
    }

    /// 自定义加载视图。
    func loadingView<L: View>(
        @ViewBuilder _ builder: @escaping () -> L
    ) -> InfiniteDayScrollView<Item, Content> {
        var copy = self
        copy.loadingBuilder = DayLoadingViewBuilder { AnyView(builder()) }
        return copy
    }

    /// 在 ScrollView 内容顶部添加整体 header 视图（随内容滚动，非固定吸顶）。
    /// 与 `.dateHeaderView`（每个日期头）不同：它是整个内容顶部的单一视图。
    func headerView<H: View>(
        @ViewBuilder _ builder: @escaping () -> H
    ) -> InfiniteDayScrollView<Item, Content> {
        var copy = self
        copy.headerViewBuilder = { AnyView(builder()) }
        return copy
    }
}
