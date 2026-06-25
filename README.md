# SwiftUIS-InfiniteScroll

[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue.svg)](https://developer.apple.com/macos/)

> 一组 SwiftUI 无限滚动组件，覆盖「通用列表 / 日期分组时间轴 / 按天分组时间线」三类场景。

本仓库包含三个独立可发布的 SwiftPM 库：

| 模块 | 主组件 | 数据协议 | 适用场景 |
|---|---|---|---|
| **SwiftUIS-InfiniteScroll** | `InfiniteScrollView` | `InfiniteLoader.load(nextId:)` | 通用信息流 / 聊天 / 商品列表 |
| **SwiftUIS-InfiniteScrollWithDate** | `InfiniteDateScrollView` | `TimelineLoader.loadPage(nextId:)` | 按日/周/月/年分组的时间轴 |
| **SwiftUIS-InfiniteScrollWithDay** | `InfiniteDayScrollView` | `DayDataSource.items(on:)` | 按天分组的日记 / 复盘 / 习惯 |

三个模块互不依赖，按需引入。

## 安装

```swift
dependencies: [
    .package(url: "https://github.com/hocgin/SwiftUIS-InfiniteScroll.git", .upToNextMajor(from: "2.0.0"))
]
```

按需选择 target 依赖：

```swift
.target(name: "App", dependencies: [
    .product(name: "SwiftUIS-InfiniteScroll", package: "SwiftUIS-InfiniteScroll"),
    // 或 / 和
    .product(name: "SwiftUIS-InfiniteScrollWithDate", package: "SwiftUIS-InfiniteScroll"),
    .product(name: "SwiftUIS-InfiniteScrollWithDay", package: "SwiftUIS-InfiniteScroll"),
])
```

## 三模块速览

### 1. SwiftUIS-InfiniteScroll — 通用游标分页列表

最基础款，无业务耦合。只要后端能给出「下一页游标」即可对接。

```swift
import SwiftUIS_InfiniteScroll

struct Post: Sendable, Identifiable {
    let id: String
    let title: String
}

struct PostLoader: InfiniteLoader {
    func load(nextId: String?) async throws -> Page<Post> {
        let (records, cursor) = try await api.fetch(after: nextId)
        return Page(records: records, nextId: cursor)
    }
}

InfiniteScrollView(loader: PostLoader()) { post in
    Text(post.title)
}
.emptyView { ContentUnavailableView("空空如也", systemImage: "tray") }
.errorView { error, retry in ErrorView(error, retry: retry) }
.footerView { state, retry in FooterView(state: state, retry: retry) }
```

特性：预加载策略 `.fixed(N)` / `.ratio(0.8)`；首次失败与分页失败均不丢数据；下拉刷新默认关闭（按需附加 `.refreshable`）。

### 2. SwiftUIS-InfiniteScrollWithDate — 多粒度时间轴

按 `day / week / month / year` 自动分组；`Item` 需带 `date` 字段。

```swift
import SwiftUIS_InfiniteScrollWithDate

struct Event: TimelineItem {
    let id: String
    let date: Date
    let title: String
}

struct EventLoader: TimelineLoader {
    func loadPage(nextId: String?) async throws -> Page<Event> {
        let (events, cursor) = try await api.events(after: nextId)
        return Page(records: events, nextId: cursor)
    }
}

InfiniteDateScrollView(loader: EventLoader(), grouping: .month) { event in
    Text(event.title)
}
.dateHeaderView { date, grouping in MonthHeader(date: date, grouping: grouping) }
.errorView { error, retry in ErrorView(error, retry: retry) }
```

特性：游标分页驱动 + 多粒度分组；空日填充（`showEmptyDays`）；`preloadThreshold`；`scrollProxy.scrollTo(date)` 跳转。

### 3. SwiftUIS-InfiniteScrollWithDay — 按天分组的日记 / 时间记录

按天预知边界（与上一款的关键差异：日期是「列骨架」，由组件侧迭代展开，调用方只回答"这一天有哪些记录"）。

```swift
import SwiftUIS_InfiniteScrollWithDay

struct Record: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let title: String
}

struct RecordSource: DayDataSource {
    func items(on day: Date) async throws -> [Record] {
        try await database.records(on: day)
    }
}

InfiniteDayScrollView(source: RecordSource(), emptyStrategy: .collapse) { day, records in
    ForEach(records) { Text($0.title) }
}
.dateHeaderView { ctx in DayHeader(context: ctx) }
.gapView { gap in GapCard(gap) }
```

特性：三种空日策略（`showAll` / `hideEmpty` / `collapse`）；Sticky Header；双向加载（`forwardLoading`）；`InfiniteDayScrollViewInfiniteScrollProxy.scrollToToday / scrollTo / scrollToMonth`。

## 修饰符

三个模块均采用「值类型副本」模式，修饰符限定到对应主组件、返回同类型，链式调用不断类型：

```swift
InfiniteDayScrollView(...)
    .headerView { ... }          // 整体顶部 header（随内容滚动）
    .dateHeaderView { ... }      // 每个日期分组头
    .emptyView { ... }
    .gapView { ... }
    .loadingView { ... }

InfiniteDateScrollView(...)
    .headerView { ... }          // 整体顶部 header（随内容滚动）
    .dateHeaderView { ... }      // 每个分组日期头
    .loadingView { ... }
    .errorView { ... }
    .emptyView { ... }

InfiniteScrollView(...)
    .headerView { ... }          // 整体顶部 header（随内容滚动）
    .emptyView { ... }
    .loadingView { ... }
    .errorView { ... }
    .footerView { ... }
```

修饰符不再放在 `extension View` 上，避免跨模块同名歧义。

## 平台支持

- iOS 17+
- macOS 15+
- Swift 6 严格并发安全

## 文档

- [项目背景](docs/00_CONTEXT.md)
- [API 参考](docs/01_API_REFERENCE.md)
- [架构设计](docs/02_ARCHITECTURE.md)
- [快速入门](docs/03_GUIDES/quick-start.md)
- [更新日志](docs/04_CHANGELOG.md)

## License

MIT
