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
/// 跳转代理（DayScrollProxy）有两种获取方式：
/// - **子视图**用 `@Environment(\.dayScrollProxy)`（自动注入）
/// - **父视图**（如 NavigationStack 的 .toolbar）用 `scrollProxy:` binding 参数传入
///   原因：SwiftUI environment 单向向下，子视图设置的环境值父视图读不到。
public struct InfiniteDayScrollView<Item: Sendable & Identifiable, Content: View>: View {

    @State private var controller: InfiniteScrollController<Item>
    @ViewBuilder private let content: (Date, [Item]) -> Content

    /// 外部传入的 proxy binding，onAppear 时写入，让父视图（如 toolbar）能调用跳转。
    private let scrollProxyBinding: Binding<DayScrollProxy?>?

    /// 基础版：按 DayRange 迭代，无数据源。
    ///
    /// 内部用空数据源走完整管线，避免重复实现。
    /// batchSize 取 range 天数，emptyStrategy 固定 `.showAll`（既然无数据，空日就是常态）。
    public init(
        range: DayRange,
        scrollProxy: Binding<DayScrollProxy?>? = nil,
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
    }

    /// 数据驱动版（默认配置）。
    ///
    /// 默认：anchor=今天、batchSize=30、collapse、stickyHeader、不向前加载。
    public init<Data: DayDataSource>(
        source: Data,
        anchor: Date = Date(),
        scrollProxy: Binding<DayScrollProxy?>? = nil,
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
        scrollProxy: Binding<DayScrollProxy?>? = nil,
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
    }

    /// 完整版（PRD 风格，参数扁平化）。
    ///
    /// 等价于 `init(source:anchor:config:content:)` + `InfiniteScrollConfig(emptyStrategy:batchSize:stickyHeader:forwardLoading:)`。
    public init<Data: DayDataSource>(
        source: Data,
        emptyStrategy: EmptyStrategy = .collapse,
        batchSize: Int = 30,
        stickyHeader: Bool = true,
        forwardLoading: Bool = false,
        anchor: Date = Date(),
        scrollProxy: Binding<DayScrollProxy?>? = nil,
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
    ///
    /// Controller 通过 `scrollCommand` 发起跳转；此处监听命令并写入 scrollPosition，
    /// SwiftUI 自动处理「先渲染目标 day 再滚动」（避免 LazyVStack 未渲染导致 scrollTo 静默失效）。
    @State private var scrollPosition: DayKey?

    public var body: some View {
        ScrollView {
            // pinnedViews 类型是 SwiftUI 内部 PinnedScrollViews，
            // 直接 inline 三元运算符让编译器推断，不显式声明类型名。
            LazyVStack(
                alignment: .leading,
                spacing: 0,
                pinnedViews: controller.config.stickyHeader ? [.sectionHeaders] : []
            ) {
                // 顶部哨兵（仅 forwardLoading）
                if controller.config.forwardLoading {
                    Color.clear
                        .frame(height: 1)
                        .id(ScrollAnchors.top)
                        .onAppear { controller.loadMoreFuture() }
                }

                ForEach(controller.sectionItems) { item in
                    sectionItemView(item)
                }

                // 底部哨兵：高度保持 1pt，依赖 LazyVStack 默认的视口外预渲染触发 onAppear。
                // 之前用 200pt 会让哨兵本身占空间，在内容稀疏时持续可见，导致循环触发。
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
            // 把 proxy 写入外部 binding，让父视图（toolbar 等）能调用跳转。
            // .environment 只向下传递，父视图读不到。
            scrollProxyBinding?.wrappedValue = DayScrollProxy(controller)
            controller.bootstrap()
        }
        .environment(\.dayScrollProxy, DayScrollProxy(controller))
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
