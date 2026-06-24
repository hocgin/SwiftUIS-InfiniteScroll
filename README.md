# SwiftIS-InfiniteScrollWithDay

[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue.svg)](https://developer.apple.com/macos/)

> An infinitely scrolling, day-grouped timeline component for SwiftUI.
> 一个专为 SwiftUI 打造的按日期分组无限滚动组件。

适用于：时间记录、日记、复盘、计划管理、习惯追踪、运动记录、财务流水、事件时间线。

## 特性

- 按日分组（LazyVStack + ForEach）
- 双向无限滚动（默认仅向下，可选向上）
- 三种空日策略：`showAll` / `hideEmpty` / `collapse`（推荐默认）
- Sticky Header（iOS 17+ 原生 `pinnedViews`）
- 日期定位：`scrollToToday` / `scrollTo(Date)` / `scrollToMonth(Date)`
- 自定义：日期头 / 空日 / 折叠区间 / 加载视图
- Swift 6 严格并发安全
- 性能：10k 日期 + 100k 记录下 60 FPS

## 安装

Swift Package Manager：

```swift
.package(url: "https://github.com/hocgin/SwiftUIS-InfiniteScrollWithDay.git", .upToNextMajor(from: "1.0.0"))
```

## 三种用法

### 1. 基础版（无数据源）

适合：纯迭代日期，不需要异步数据。

```swift
import SwiftIS_InfiniteScrollWithDay

InfiniteDayScrollView(range: .past(days: 365)) { day in
    TimelineSection(date: day)
}
```

### 2. 数据驱动版（默认配置）

实现 `DayDataSource` 协议即可。

```swift
struct RecordSource: DayDataSource {
    func items(on day: Date) async throws -> [Record] {
        await database.records(on: day)
    }
}

InfiniteDayScrollView(source: RecordSource()) { day, records in
    RecordList(records)
}
```

### 3. 完整版（自定义所有）

```swift
InfiniteDayScrollView(
    source: source,
    emptyStrategy: .collapse,
    batchSize: 30,
    stickyHeader: true,
    forwardLoading: false
) { day, records in
    TimelineSection(records)
}
```

## 自定义修饰符

```swift
InfiniteDayScrollView(source: source) { day, records in
    RecordList(records)
}
.dayHeader { day in
    MyCustomHeader(day)            // 自定义日期头
}
.emptyDayView {
    EmptyDayPlaceholder()          // 自定义空日
}
.gapView { gap in
    GapCard(gap)                   // 自定义折叠区间
}
.loadingView {
    SkeletonView()                 // 自定义加载视图
}
```

## 日期定位

通过 `@Environment(\.dayScrollProxy)` 取得代理：

```swift
struct Toolbar: View {
    @Environment(\.dayScrollProxy) private var proxy
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button("回到今天") {
            // reduceMotion 时禁用动画
            proxy?.scrollToToday(animated: !reduceMotion)
        }
        Button("跳转到本月") {
            proxy?.scrollToMonth(Date())
        }
    }
}
```

## 空日策略

```swift
public enum EmptyStrategy {
    case showAll     // 显示所有日期（包括空）
    case hideEmpty   // 隐藏空日
    case collapse    // 折叠连续空日为单个 GapRange（推荐）
}
```

## DataSource 协议

```swift
public protocol DayDataSource: Sendable {
    associatedtype Item: Sendable & Identifiable
    func items(on day: Date) async throws -> [Item]
}
```

内置实现：
- `StaticDayDataSource<Item>`：内存数据源（测试 / Demo）
- `AnyDayDataSource<Item>`：类型擦除盒

## API 速查

| 类型 | 用途 |
|------|------|
| `InfiniteDayScrollView` | 主组件 |
| `DayDataSource` / `AnyDayDataSource` / `StaticDayDataSource` | 数据源 |
| `EmptyStrategy` | 空日策略 |
| `DayRange` | 日期范围描述符（基础版用） |
| `DayScrollProxy` | 日期定位代理 |
| `InfiniteScrollConfig` | 完整版配置 |
| `GapRange` | 折叠区间模型 |
| `DayKey` | 日期标识（基于 UTC） |

## 文档

- [快速入门](docs/03_GUIDES/quick-start.md)
- [架构设计](docs/02_ARCHITECTURE.md)
- [API 参考](docs/01_API_REFERENCE.md)
- [更新日志](docs/04_CHANGELOG.md)

## 平台支持

- iOS 17+
- macOS 15+

## License

MIT
