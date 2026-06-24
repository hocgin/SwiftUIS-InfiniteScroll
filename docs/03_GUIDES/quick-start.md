# 快速入门

三个模块独立，按需选择对应章节。

## 安装

`Package.swift`：

```swift
dependencies: [
    .package(url: "https://github.com/hocgin/SwiftUIS-InfiniteScroll.git", .upToNextMajor(from: "2.0.0"))
],

targets: [
    .target(name: "App", dependencies: [
        .product(name: "SwiftUIS-InfiniteScroll", package: "SwiftUIS-InfiniteScroll"),
        // 或 / 和：
        .product(name: "SwiftUIS-InfiniteScrollWithDate", package: "SwiftUIS-InfiniteScroll"),
        .product(name: "SwiftUIS-InfiniteScrollWithDay", package: "SwiftUIS-InfiniteScroll"),
    ])
]
```

> Swift 模块名连字符在 import 时变为下划线：
> - `SwiftUIS-InfiniteScroll` → `import SwiftUIS_InfiniteScroll`
> - `SwiftUIS-InfiniteScrollWithDate` → `import SwiftUIS_InfiniteScrollWithDate`
> - `SwiftUIS-InfiniteScrollWithDay` → `import SwiftUIS_InfiniteScrollWithDay`

---

# 一、SwiftUIS-InfiniteScroll

## 1. 实现 Loader

```swift
import SwiftUIS_InfiniteScroll

struct Post: Sendable, Identifiable {
    let id: String
    let title: String
}

struct PostLoader: InfiniteLoader {
    func load(nextId: String?) async throws -> Page<Post> {
        let (records, cursor) = try await API.fetchPosts(after: nextId)
        return Page(records: records, nextId: cursor)
    }
}
```

## 2. 渲染

```swift
struct FeedView: View {
    var body: some View {
        InfiniteScrollView(loader: PostLoader()) { post in
            Text(post.title)
                .padding()
        }
        .emptyView {
            ContentUnavailableView("暂无内容", systemImage: "tray")
        }
        .loadingView {
            ProgressView().frame(maxWidth: .infinity).padding()
        }
        .errorView { error, retry in
            VStack {
                Text(error.localizedDescription)
                Button("重试", action: retry)
            }
        }
        .footerView { state, retry in
            FooterView(state: state, retry: retry)
        }
    }
}
```

## 3. 自定义预加载策略

```swift
InfiniteScrollView(loader: loader, preloadStrategy: .ratio(0.8)) { post in
    PostCard(post)
}
```

## 4. 下拉刷新

默认关闭。需要时显式附加：

```swift
InfiniteScrollView(loader: loader) { ... }
    .refreshable { await store.reloadAsync() }
```

（用 store 形式的 init 时刷新更自然：`store: store`，然后 `await store.reloadAsync()`）

---

# 二、SwiftUIS-InfiniteScrollWithDate

## 1. 实现 Loader + Item

```swift
import SwiftUIS_InfiniteScrollWithDate

struct Event: TimelineItem {
    let id: String
    let date: Date
    let title: String
}

struct EventLoader: TimelineLoader {
    func loadPage(nextId: String?) async throws -> Page<Event> {
        let (events, cursor) = try await API.fetchEvents(after: nextId)
        return Page(records: events, nextId: cursor)
    }
}
```

## 2. 渲染（按月分组）

```swift
struct TimelineView: View {
    var body: some View {
        InfiniteDateScrollView(loader: EventLoader(), grouping: .month) { event in
            Text(event.title)
                .padding()
        }
        .header { date, grouping in
            MonthHeader(date: date)
        }
        .errorView { error, retry in
            ErrorView(error: error, retry: retry)
        }
    }
}
```

切换粒度：把 `grouping: .month` 改为 `.day / .week / .year`。

## 3. 跳转到指定日期

```swift
struct TimelineScreen: View {
    @State private var proxy: InfiniteScrollProxy?

    var body: some View {
        NavigationStack {
            InfiniteDateScrollView(
                loader: EventLoader(),
                grouping: .day,
                scrollProxy: $proxy
            ) { event in
                EventRow(event)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("今天") { proxy?.scrollTo(Date()) }
                }
            }
        }
    }
}
```

---

# 三、SwiftUIS-InfiniteScrollWithDay

## 1. 基础版（无数据源）

适合：纯迭代日期，不需要异步数据。

```swift
import SwiftUIS_InfiniteScrollWithDay

struct CalendarStrip: View {
    var body: some View {
        InfiniteDayScrollView(range: .past(days: 90)) { day in
            Text(day, format: .dateTime.month().day())
                .padding()
        }
    }
}
```

## 2. 数据驱动版

```swift
struct Record: Sendable, Identifiable {
    let id = UUID()
    let date: Date
    let title: String
}

struct RecordDatabase: DayDataSource {
    func items(on day: Date) async throws -> [Record] {
        try await DB.records(on: day)
    }
}

struct TimelineView: View {
    var body: some View {
        InfiniteDayScrollView(source: RecordDatabase()) { day, records in
            ForEach(records) { Text($0.title).padding(.vertical, 2) }
        }
    }
}
```

默认：anchor=今天、batchSize=30、collapse 策略、stickyHeader、不向前加载。

## 3. 完整版 + 自定义

```swift
InfiniteDayScrollView(
    source: source,
    emptyStrategy: .collapse,
    batchSize: 50,
    stickyHeader: true,
    forwardLoading: false
) { day, records in
    ForEach(records) { RecordRow($0) }
}
.header { ctx in
    HStack {
        Text(ctx.date, format: .dateTime.month().day())
            .font(.headline)
        Spacer()
        Text("\(ctx.itemCount) 条")
            .font(.caption).foregroundStyle(.secondary)
    }
    .padding()
    .background(.thinMaterial)
}
.emptyView {
    ContentUnavailableView("无记录", systemImage: "tray")
}
.gapView { gap in
    VStack {
        Text("\(gap.count) 天空档")
        Text("\(gap.start.referenceDate, format: .dateTime.month().day()) ~ \(gap.end.referenceDate, format: .dateTime.month().day())")
    }
    .padding()
}
.loadingView {
    ProgressView().frame(maxWidth: .infinity).padding()
}
```

## 4. 跳转

```swift
struct TimelineScreen: View {
    @State private var proxy: DayScrollProxy?

    var body: some View {
        NavigationStack {
            InfiniteDayScrollView(
                source: RecordDatabase(),
                scrollProxy: $proxy
            ) { day, records in
                ForEach(records) { RecordRow($0) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("回到今天") { proxy?.scrollToToday() }
                }
            }
        }
    }
}
```

`DayScrollProxy` API：
- `scrollToToday(animated:)`
- `scrollTo(_:anchor:animated:)`
- `scrollToMonth(_:anchor:animated:)`

## 5. 三种空日策略

```swift
.showAll    // 每天都显示，空日渲染 emptyView
.hideEmpty  // 完全跳过空日，列表更紧凑
.collapse   // 连续 ≥ 2 空日折叠为 GapRange，单空日保留（推荐默认）
```

---

## 下一步

- [API 参考](../01_API_REFERENCE.md) — 完整类型签名
- [架构设计](../02_ARCHITECTURE.md) — 内部机制
- [项目背景](../00_CONTEXT.md) — 模块选择指南
- Demo App（`App/Sources/BootView.swift`）— 三模块完整示例
