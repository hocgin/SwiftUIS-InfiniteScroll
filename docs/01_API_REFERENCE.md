# API 参考

三个模块独立，可单独 import。

---

# SwiftUIS-InfiniteScroll（通用列表）

## `InfiniteScrollView<Item, Content>`

```swift
public struct InfiniteScrollView<Item: Sendable & Identifiable, Content: View>: View
```

### 初始化

```swift
// 由 loader 构造（推荐）
public init<L: InfiniteLoader>(
    loader: L,
    preloadStrategy: PreloadStrategy = .defaultStrategy,
    @ViewBuilder content: @escaping (Item) -> Content
) where L.Item == Item

// 由外部传入 store（多个视图共享同一 store 时）
public init(
    store: InfiniteStore<Item>,
    @ViewBuilder content: @escaping (Item) -> Content
)
```

### 修饰符（返回 `InfiniteScrollView<Item, Content>`）

```swift
func emptyView<V: View>(@ViewBuilder _ builder: @escaping () -> V) -> Self
func loadingView<L: View>(@ViewBuilder _ builder: @escaping () -> L) -> Self
func errorView<E: View>(
    @ViewBuilder _ builder: @escaping (any Error, @escaping () -> Void) -> E
) -> Self
func footerView<F: View>(
    @ViewBuilder _ builder: @escaping (InfiniteFooterState, @escaping () -> Void) -> F
) -> Self
```

## `InfiniteLoader`

```swift
public protocol InfiniteLoader: Sendable {
    associatedtype Item: Sendable & Identifiable
    func load(nextId: String?) async throws -> Page<Item>
}

// 类型擦除盒
public struct AnyInfiniteLoader<Item: Sendable & Identifiable>: InfiniteLoader {
    public init<L: InfiniteLoader>(_ loader: L) where L.Item == Item
    public init(_ fetch: @Sendable @escaping (String?) async throws -> Page<Item>)
}
```

## `InfiniteStore<Item>`

```swift
@MainActor @Observable
public final class InfiniteStore<Item: Sendable & Identifiable>

public init<L: InfiniteLoader>(loader: L, preloadStrategy: PreloadStrategy = .defaultStrategy)
where L.Item == Item

// 公开状态
public private(set) var items: [Item]
public private(set) var state: InfiniteState            // .idle / .loading / .loaded / .empty / .failed
public private(set) var footerState: InfiniteFooterState // .none / .loading / .failed / .noMore
public private(set) var isRefreshing: Bool
public private(set) var hasMore: Bool
public private(set) var nextId: String?
public private(set) var lastError: (any Error)?

// 操作
public func bootstrap()
public func retry()
public func reloadAsync() async          // 适配 .refreshable
```

## `Page<Item>`

```swift
public struct Page<Item: Sendable>: Sendable {
    public let records: [Item]
    public let nextId: String?
    public let hasMore: Bool
    public init(records: [Item], nextId: String?, hasMore: Bool? = nil)
}
```

## `InfiniteState` / `InfiniteFooterState`

```swift
public enum InfiniteState: Sendable, Equatable {
    case idle, loading, loaded, empty, failed
}

public enum InfiniteFooterState: Sendable, Equatable {
    case none, loading, failed, noMore
}
```

## `PreloadStrategy`

```swift
public enum PreloadStrategy: Sendable, Hashable {
    case fixed(Int)         // 剩余 N 条触发
    case ratio(Double)      // 滚到 X% 触发
    public static let defaultStrategy: PreloadStrategy = .fixed(5)
}
```

## `InfiniteError`

`public protocol InfiniteError: Error, Sendable` —— 业务方可选实现，标记可恢复错误，便于 UI 层区分展示。

---

# SwiftUIS-InfiniteScrollWithDate（多粒度时间轴）

## `InfiniteDateScrollView<Item, Content>`

```swift
public struct InfiniteDateScrollView<Item: TimelineItem, Content: View>: View
```

### 初始化

```swift
// 完整版（传 config）
public init<L: TimelineLoader>(
    loader: L,
    config: TimelineConfig = .init(),
    scrollProxy: Binding<InfiniteScrollProxy?>? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
) where L.Item == Item

// PRD 风格扁平化（参数展开）
public init<L: TimelineLoader>(
    loader: L,
    grouping: TimelineGrouping = .day,
    showEmptyDays: Bool = false,
    preloadThreshold: Int = 5,
    restoreScrollPosition: Bool = false,
    scrollProxy: Binding<InfiniteScrollProxy?>? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
) where L.Item == Item
```

### 修饰符（返回 `InfiniteDateScrollView<Item, Content>`）

```swift
func header<H: View>(
    @ViewBuilder _ builder: @escaping (Date, TimelineGrouping) -> H
) -> Self

func loadingView<L: View>(@ViewBuilder _ builder: @escaping () -> L) -> Self

func errorView<E: View>(
    @ViewBuilder _ builder: @escaping (any Error, @escaping () -> Void) -> E
) -> Self

func emptyView<V: View>(@ViewBuilder _ builder: @escaping () -> V) -> Self
```

## `TimelineLoader`

```swift
public protocol TimelineLoader: Sendable {
    associatedtype Item: TimelineItem
    func loadPage(nextId: String?) async throws -> Page<Item>
}

public struct AnyTimelineLoader<Item: TimelineItem>: TimelineLoader { ... }
```

## `TimelineItem`

```swift
public protocol TimelineItem: Sendable, Identifiable {
    var id: String { get }
    var date: Date { get }
}
```

## `TimelineGrouping`

```swift
public enum TimelineGrouping: Sendable, Hashable {
    case day       // 默认
    case week
    case month
    case year
}
```

## `TimelineConfig`

```swift
public struct TimelineConfig: Sendable, Equatable {
    public let grouping: TimelineGrouping        // 默认 .day
    public let showEmptyDays: Bool               // 默认 false
    public let preloadThreshold: Int             // 默认 5（>=1）
    public let restoreScrollPosition: Bool       // 默认 false
    public init(...)
}
```

## `Page<Item>`

同上（位于 `SwiftUIS-InfiniteScrollWithDate` 模块）。

## `InfiniteScrollProxy`

```swift
public struct InfiniteScrollProxy: @unchecked Sendable {
    @MainActor public func scrollTo(_ date: Date)
}
```

通过 init 参数 `scrollProxy: Binding<InfiniteScrollProxy?>?` 取得：
父视图（如 toolbar）声明 `@State private var proxy: InfiniteScrollProxy?` 传入，在 `.onAppear` 后即可调用 `proxy?.scrollTo(date)`。

---

# SwiftUIS-InfiniteScrollWithDay（按天日记 / 时间记录）

## `InfiniteDayScrollView<Item, Content>`

```swift
public struct InfiniteDayScrollView<Item: Sendable & Identifiable, Content: View>: View
```

### 初始化（4 个）

```swift
// 1. 基础版（无数据源，仅按日迭代）
public init(
    range: DayRange,
    scrollProxy: Binding<DayScrollProxy?>? = nil,
    @ViewBuilder content: @escaping (Date) -> Content
) where Item == PlaceholderItem

// 2. 数据驱动版（默认配置）
public init<Data: DayDataSource>(
    source: Data,
    anchor: Date = Date(),
    scrollProxy: Binding<DayScrollProxy?>? = nil,
    @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
) where Data.Item == Item

// 3. 完整版（传 config）
public init<Data: DayDataSource>(
    source: Data,
    anchor: Date = Date(),
    config: InfiniteScrollConfig,
    scrollProxy: Binding<DayScrollProxy?>? = nil,
    @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
) where Data.Item == Item

// 4. PRD 风格扁平化（参数展开）
public init<Data: DayDataSource>(
    source: Data,
    emptyStrategy: EmptyStrategy = .collapse,
    batchSize: Int = 30,
    stickyHeader: Bool = true,
    forwardLoading: Bool = false,
    anchor: Date = Date(),
    scrollProxy: Binding<DayScrollProxy?>? = nil,
    @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
) where Data.Item == Item
```

### 修饰符（返回 `InfiniteDayScrollView<Item, Content>`）

```swift
func header<H: View>(
    @ViewBuilder _ builder: @escaping (DayHeaderContext) -> H
) -> Self

func emptyView<E: View>(@ViewBuilder _ builder: @escaping () -> E) -> Self

func gapView<G: View>(
    @ViewBuilder _ builder: @escaping (GapRange) -> G
) -> Self

func loadingView<L: View>(@ViewBuilder _ builder: @escaping () -> L) -> Self
```

## `DayDataSource`

```swift
public protocol DayDataSource: Sendable {
    associatedtype Item: Sendable & Identifiable
    func items(on day: Date) async throws -> [Item]
}

public struct AnyDayDataSource<Item: Sendable & Identifiable>: DayDataSource {
    public init<D: DayDataSource>(_ source: D) where D.Item == Item
    public init(_ fetch: @Sendable @escaping (Date) async throws -> [Item])
}

// 内存 mock（测试 / Demo 用）
public struct StaticDayDataSource<Item: Sendable & Identifiable>: DayDataSource {
    public init(storage: [DayKey: [Item]])
    public init(dateKeyed dates: [Date: [Item]])
}
```

## `InfiniteScrollConfig`

```swift
public struct InfiniteScrollConfig: Sendable, Equatable {
    public let batchSize: Int                  // 默认 30
    public let emptyStrategy: EmptyStrategy    // 默认 .collapse
    public let stickyHeader: Bool              // 默认 true
    public let forwardLoading: Bool            // 默认 false
    public init(...)
}
```

## `EmptyStrategy`

```swift
public enum EmptyStrategy: Sendable, Hashable {
    case showAll     // 显示所有日（空日渲染 emptyView）
    case hideEmpty   // 隐藏空日
    case collapse    // 连续 ≥ 2 空日折叠为 GapRange（默认）
}
```

## `DayRange`

```swift
public struct DayRange: Sendable, Hashable {
    public let start: DayKey
    public let end: DayKey

    public static func past(days: Int, anchor: Date = Date()) -> DayRange
    public static func around(center: Date, days: Int) -> DayRange
    public static func between(from: Date, to: Date) -> DayRange
}
```

## `DayScrollProxy`

```swift
public struct DayScrollProxy: @unchecked Sendable {
    @MainActor public func scrollToToday(
        anchor: UnitPoint? = .top, animated: Bool = true
    )
    @MainActor public func scrollTo(
        _ date: Date,
        anchor: UnitPoint? = .top, animated: Bool = true
    )
    @MainActor public func scrollToMonth(
        _ month: Date,
        anchor: UnitPoint? = .top, animated: Bool = true
    )
}
```

通过 init 参数 `scrollProxy: Binding<DayScrollProxy?>?` 暴露给父视图（推荐用法，覆盖 toolbar 场景）。
子视图仍可用 `@Environment(\.dayScrollProxy)`。

## `DayKey`

```swift
public struct DayKey: Hashable, Comparable, Sendable, Identifiable {
    public let daySinceEpoch: Int
    public init(daySinceEpoch: Int)
    public init(date: Date)
    public var referenceDate: Date
    public var id: Int { daySinceEpoch }
    public static var today: DayKey { get }
    public func adding(days: Int) -> DayKey
    public func days(from other: DayKey) -> Int
    public func isSameDay(as other: DayKey) -> Bool
}
```

基于 UTC（仅按 24h 边界切分，不带时区偏移），保证跨时区数据可共享。

## `GapRange`

```swift
public struct GapRange: Hashable, Sendable, Identifiable {
    public let start: DayKey   // 最早（含）
    public let end: DayKey     // 最晚（含）
    public var count: Int { get }
    public var id: Int { get }
}
```

## `DayHeaderContext`

`InfiniteDayScrollView` 的 `.header {}` 闭包入参，包含日期、记录数、是否今天等元信息。

## `PlaceholderItem`

```swift
public struct PlaceholderItem: Sendable, Identifiable {
    public let id: UUID
    public init()
}
```

基础版（无数据源）的占位 Item 类型，让泛型 `Item` 可推断。
