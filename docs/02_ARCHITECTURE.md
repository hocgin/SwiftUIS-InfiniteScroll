# 架构设计

## 模块划分

```
Sources/SwiftUIS-InfiniteScrollWithDay/
├── Support/      # 纯值类型工具（DayKey/DayRange/GapRange/Calendar+DayOps）
├── DataSource/   # 数据源协议与实现
├── Core/         # 状态机与聚合算法
└── UI/           # SwiftUI 视图
```

## 核心数据流

```
用户滚动
  ↓
LazyVStack 底部哨兵 .onAppear
  ↓
Controller.loadMorePast()
  ↓
扩展 visibleRange，新增 batchSize 个 DayKey 到 days 尾部
  ↓
对每个新 DayKey 启动 Task 调 dataSource.items(on:)
  ↓
异步结果回写 cache + days[i].state
  ↓
sectionItems computed property 重算（@Observable 自动通知）
  ↓
ForEach 刷新对应 DaySection
```

## 关键组件职责

### `InfiniteScrollController<Item>`

`@Observable @MainActor final class`，单一状态源：

- 持有 `days: [DayModel<Item>]`（降序：今天在前）
- 维护 `visibleRange: ClosedRange<DayKey>?` 决定下一批扩展方向
- 内部 `cache: [DayKey: [Item]]` 避免重复请求
- `loadTokens: [DayKey: Task]` 去重 in-flight 请求
- 实现 `DayScrollable` 协议供 `DayScrollProxy` 转发

### `CollapseAggregator`

纯函数，无副作用。把 `[DayModel]` 按 `EmptyStrategy` 聚合为 `[DaySectionItem]`：

- `.showAll`：保留所有日为 `.day`
- `.hideEmpty`：过滤空日
- `.collapse`：连续 ≥ 2 个空日合为单个 `.gap`（GapRange）

### `DaySectionItem`

渲染层联合类型，让 ForEach 元素数量恒定（满足 SwiftUI ForEach 稳定要求）：

```swift
public enum DaySectionItem<Item> {
    case day(DayModel<Item>)     // 正常日（loaded/empty/failed/loading）
    case gap(GapRange)           // 折叠区间
    case loading(DayKey)         // 批次加载占位
}
```

### `InfiniteDayScrollView<Item, Content>`

入口视图，三种 init 共享同一 body：

```swift
ScrollViewReader { proxy in
  ScrollView {
    LazyVStack(pinnedViews: stickyHeader ? [.sectionHeaders] : []) {
      if forwardLoading {
        TopSentinel.onAppear { controller.loadMoreFuture() }
      }
      ForEach(controller.sectionItems) { item in ... }
      BottomSentinel.onAppear { controller.loadMorePast() }
    }
  }
  .environment(\.dayScrollProxy, DayScrollProxy(controller))
}
```

## 并发模型

- Controller 是 `@MainActor`，所有状态读写都在主线程
- DataSource 协议方法是非隔离 `async throws`，可在任意 actor 实现
- 单日加载 Task 内部 `await MainActor.run { ... }` 回到主线程写状态
- 所有跨边界类型都 Sendable：`DayKey`、`[Item]`、`GapRange`

## 触发加载机制

不用 iOS 18+ 的 `scrollPosition` 绑定（避免破坏 iOS 17 兼容）。改用 onAppear 哨兵：

- LazyVStack 末尾插 `Color.clear.frame(height: 200).id(ScrollAnchors.bottom)`
- `.onAppear { controller.loadMorePast() }`
- `loadMore*` 内部用 `forwardState == .loading` 短路防重入

扩大命中区到 200pt 防止快速滚动错过触发。

## 双向加载避免视图跳动

向上插入新日期时，`days.insert(contentsOf:)` 到头部。ForEach 用 DayKey 作 ID（不含 index），位置变化不影响视图身份。可选：插入后立即 `proxy.scrollTo(anchor, anchor: .top)` 锚定回原可视首日。

## 性能考虑

- `LazyVStack` 仅渲染可见 + 缓冲区视图
- `cache` 命中即跳过 async
- `CollapseAggregator` 单次线性扫描，O(n)
- DaySection 提取为独立 struct，SwiftUI 可跳过未变更子树的 body 计算
