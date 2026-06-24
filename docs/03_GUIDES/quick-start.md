# 快速入门

## 安装

在 Xcode 中：File → Add Package Dependencies，输入仓库 URL。

或在 `Package.swift` 中：

```swift
dependencies: [
    .package(url: "https://github.com/hocgin/SwiftUIS-InfiniteScrollWithDay.git", .upToNextMajor(from: "1.0.0"))
]
```

## 第一个例子

### 1. 基础版（5 分钟上手）

适合：纯按日期迭代，不需要异步数据。

```swift
import SwiftUI
import SwiftIS_InfiniteScrollWithDay

struct TimelineView: View {
    var body: some View {
        InfiniteDayScrollView(range: .past(days: 90)) { day in
            VStack(alignment: .leading) {
                Text("Day: \(day.formatted(date: .abbreviated, time: .omitted))")
                    .font(.headline)
                Text("Your content here")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

运行后即可看到过去 90 天的列表，日期头吸顶。

### 2. 数据驱动版（推荐生产用法）

定义你的数据模型和数据源：

```swift
struct Record: Sendable, Identifiable {
    let id = UUID()
    let title: String
    let date: Date
}

struct RecordDatabase: DayDataSource {
    func items(on day: Date) async throws -> [Record] {
        // 替换为你的实际数据查询
        try await fetchRecords(from: day)
    }
}
```

使用：

```swift
struct TimelineView: View {
    var body: some View {
        InfiniteDayScrollView(source: RecordDatabase()) { day, records in
            VStack(alignment: .leading) {
                ForEach(records) { record in
                    Text(record.title)
                }
            }
            .padding()
        }
    }
}
```

默认配置：anchor=今天、batchSize=30、collapse 策略、stickyHeader、不向前加载。

### 3. 完整版 + 自定义

```swift
InfiniteDayScrollView(
    source: source,
    anchor: Date(),                       // 初始锚点（默认今天）
    config: .init(
        batchSize: 50,
        emptyStrategy: .collapse,
        stickyHeader: true,
        forwardLoading: false
    )
) { day, records in
    RecordList(records)
}
.dayHeader { day in
    HStack {
        Text(day, format: .dateTime.month().day())
            .font(.headline)
        Spacer()
        Text(day, format: .dateTime.weekday(.wide))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(.thinMaterial)
}
.emptyDayView {
    ContentUnavailableView(
        "无记录",
        systemImage: "tray"
    )
}
.gapView { gap in
    VStack {
        Text("\(gap.count) 天空档")
        Text("\(gap.start.referenceDate, format: .dateTime.month().day()) ~ \(gap.end.referenceDate, format: .dateTime.month().day())")
    }
    .padding()
}
.loadingView {
    ProgressView()
        .frame(maxWidth: .infinity)
        .padding()
}
```

## 日期定位

```swift
struct TimelineToolbar: View {
    @Environment(\.dayScrollProxy) private var proxy

    var body: some View {
        HStack {
            Button("回到今天") { proxy?.scrollToToday() }
            Button("本月") { proxy?.scrollToMonth(Date()) }
            Button("3 月前") {
                proxy?.scrollTo(Date().addingTimeInterval(-90 * 86_400))
            }
        }
    }
}
```

把 `TimelineToolbar` 嵌套在 `InfiniteDayScrollView` 内（或通过 environment 传递），即可调用定位 API。

## 三种空日策略对比

```swift
.showAll    // 每天都显示，空日渲染 emptyDayView
.hideEmpty  // 完全跳过空日，列表更紧凑
.collapse   // 连续 ≥ 2 个空日折叠为 GapRange，单空日保留（默认推荐）
```

## 下一步

- 阅读 [API 参考](../01_API_REFERENCE.md) 了解所有类型
- 阅读 [架构设计](../02_ARCHITECTURE.md) 了解内部机制
- 查看 Demo App（`App/Sources/BootView.swift`）三个完整示例
