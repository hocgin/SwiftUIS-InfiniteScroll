# API 参考

## 主组件

### `InfiniteDayScrollView<Item, Content>`

按日期分组的无限滚动视图。

```swift
public struct InfiniteDayScrollView<
    Item: Sendable & Identifiable,
    Content: View
>: View
```

#### 初始化

```swift
// 1. 基础版（无数据源）
public init(
    range: DayRange,
    @ViewBuilder content: @escaping (Date) -> Content
) where Item == PlaceholderItem

// 2. 数据驱动版（默认配置）
public init<Data: DayDataSource>(
    source: Data,
    anchor: Date = Date(),
    @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
) where Data.Item == Item

// 3. 完整版
public init<Data: DayDataSource>(
    source: Data,
    anchor: Date = Date(),
    config: InfiniteScrollConfig,
    @ViewBuilder content: @escaping (Date, [Data.Item]) -> Content
) where Data.Item == Item
```

---

## 配置

### `InfiniteScrollConfig`

```swift
public struct InfiniteScrollConfig: Sendable, Equatable {
    public let batchSize: Int                // 默认 30
    public let emptyStrategy: EmptyStrategy  // 默认 .collapse
    public let stickyHeader: Bool            // 默认 true
    public let forwardLoading: Bool          // 默认 false

    public init(
        batchSize: Int = 30,
        emptyStrategy: EmptyStrategy = .collapse,
        stickyHeader: Bool = true,
        forwardLoading: Bool = false
    )
}
```

### `EmptyStrategy`

```swift
public enum EmptyStrategy: Sendable, Hashable {
    case showAll     // 显示所有日期（包括空）
    case hideEmpty   // 隐藏空日
    case collapse    // 折叠连续空日为单个 GapRange（默认）
}
```

### `DayRange`

```swift
public struct DayRange: Sendable, Hashable {
    public let start: DayKey
    public let end: DayKey

    public static func past(days: Int, anchor: Date = Date()) -> DayRange
    public static func around(center: Date, days: Int) -> DayRange
    public static func between(from: Date, to: Date) -> DayRange
}
```

---

## 数据源

### `DayDataSource`

```swift
public protocol DayDataSource: Sendable {
    associatedtype Item: Sendable & Identifiable
    func items(on day: Date) async throws -> [Item]
}
```

### `AnyDayDataSource<Item>`

类型擦除盒。

```swift
public init<D: DayDataSource>(_ source: D) where D.Item == Item
public init(_ fetch: @Sendable @escaping (Date) async throws -> [Item])
```

### `StaticDayDataSource<Item>`

内存数据源（测试 / Demo 用）。

```swift
public init(storage: [DayKey: [Item]])
public init(dateKeyed dates: [Date: [Item]])
```

---

## 日期定位

### `DayScrollProxy`

通过 `@Environment(\.dayScrollProxy)` 取得。

```swift
public struct DayScrollProxy {
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

---

## 自定义修饰符

```swift
extension View {
    func dayHeader<H: View>(@ViewBuilder _ b: @escaping (Date) -> H) -> some View
    func emptyDayView<E: View>(@ViewBuilder _ b: @escaping () -> E) -> some View
    func gapView<G: View>(@ViewBuilder _ b: @escaping (GapRange) -> G) -> some View
    func loadingView<L: View>(@ViewBuilder _ b: @escaping () -> L) -> some View
}
```

---

## 底层类型

### `DayKey`

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

### `GapRange`

```swift
public struct GapRange: Hashable, Sendable, Identifiable {
    public let start: DayKey  // 最早（含）
    public let end: DayKey    // 最晚（含）

    public var count: Int { get }
    public var id: Int { get }
}
```

### `PlaceholderItem`

基础版（无数据源）使用的占位 Item 类型。

```swift
public struct PlaceholderItem: Sendable, Identifiable {
    public let id: UUID
    public init()
}
```
