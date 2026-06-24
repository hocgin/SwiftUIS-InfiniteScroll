# 架构设计

## 总体结构

```
Sources/
├── SwiftUIS-InfiniteScroll/             # 通用列表
│   ├── Core/                            # InfiniteLoader / InfiniteStore / InfiniteState / PreloadStrategy
│   ├── Models/                          # Page
│   ├── Configuration/                   # EnvironmentKey（builder 容器）
│   └── Views/                           # InfiniteScrollView + 4 默认视图
│
├── SwiftUIS-InfiniteScrollWithDate/     # 多粒度时间轴
│   ├── Core/                            # TimelineLoader / TimelineEngine / TimelineConfig / TimelineGrouping / TimelineState
│   ├── Models/                          # Page / TimelineItem / TimelineSection
│   ├── Extensions/                      # Date+TimelineGrouping
│   ├── Configuration/                   # EnvironmentKey + InfiniteScrollProxy
│   └── Views/                           # InfiniteDateScrollView + 默认视图
│
└── SwiftUIS-InfiniteScrollWithDay/      # 按天日记
    ├── Support/                         # DayKey / DayRange / GapRange / Calendar+DayOps
    ├── DataSource/                      # DayDataSource / AnyDayDataSource / StaticDayDataSource / EmptyStrategy
    ├── Core/                            # InfiniteScrollController / CollapseAggregator / DayModel / DaySectionItem
    └── UI/                              # InfiniteDayScrollView + 默认视图 + DayScrollProxy
```

三个模块互不依赖，target 之间不互相 import。

## 共性设计

### 状态机：`@MainActor @Observable`

每个模块都有一个核心状态机：

| 模块 | 状态机 | 角色 |
|---|---|---|
| InfiniteScroll | `InfiniteStore<Item>` | 一维 items + 首次/分页/刷新三态 |
| InfiniteScrollWithDate | `TimelineEngine<Item>` | 游标分页 records + section 重算 |
| InfiniteScrollWithDay | `InfiniteScrollController<Item>` | 双向 day 数组 + 缓存 + 折叠聚合 |

共同模式：
- `@MainActor` 锁定状态读写主线程
- `@Observable` 让 SwiftUI 视图自动追踪
- Loader / DataSource 协议方法是非隔离 `async throws`，可在任意 actor 实现
- 跨边界类型都 `Sendable`：`Item` / `Page<Item>` / `[Item]` / `DayKey` / `GapRange`

### 自定义能力传递：EnvironmentKey + 值类型副本修饰符

```
开发者侧                          body 渲染层
─────────                         ─────────────
.header { ... }                   if let builder = headerBuilder?.builder {
   │                                  builder()
   ▼                              } else {
var copy = self                       默认视图()
copy.headerBuilder = ...          }
   │
   ▼
return copy  // 同类型
   │
   ▼
.environment(\.xxxBuilder, copy.headerBuilder ?? .default)
```

为什么不用 `extension View` + modifier 包装：
- 三个模块都有 `.emptyView` / `.loadingView` / `.errorView` 等同名 modifier
- 通用 View 扩展在跨模块 import 时产生歧义
- 限定到具体主组件 + 返回 `InfiniteXxxScrollView<Item, Content>` 副本，链式不断类型，也无歧义

### 触发加载：onAppear 哨兵

```
LazyVStack {
    if ctrl.config.forwardLoading {
        Color.clear.frame(height: 200).id(top)
            .onAppear { ctrl.loadMoreFuture() }
    }

    ForEach(...) { ... }

    Color.clear.frame(height: 200).id(bottom)
        .onAppear { ctrl.loadMorePast() }
}
```

- 用 `frame(height: 200)` 扩大命中区，防快滚错过
- 状态机内部用 `state == .loading` 短路防重入
- 不依赖 iOS 18+ 的 `scrollPosition` 绑定（保 iOS 17 兼容）

### 跳转：iOS 17+ `scrollPosition(id:)` 双向绑定

`ScrollViewReader.scrollTo` 在 LazyVStack 未渲染的离屏元素上失效。三个模块统一改用：

```swift
@State private var scrollPosition: Key?

ScrollView { ... }
    .scrollPosition(id: $scrollPosition, anchor: .top)
    .onChange(of: ctrl.scrollCommand) { _, command in
        guard let command else { return }
        scrollPosition = command.key
    }
```

状态机暴露 `scrollCommand: ScrollCommand?`，调用方触发跳转时 `scrollCommand = .init(key: ..., token: ...)`，`onChange` 把 key 同步到 `scrollPosition`，SwiftUI 内部完成定位。

### Proxy 暴露给父视图

SwiftUI environment 是单向向下的——子视图设置的环境值父视图读不到。所以 toolbar 这类父视图要触发跳转，必须用 binding 参数：

```swift
// 父视图
@State private var proxy: DayScrollProxy?
InfiniteDayScrollView(..., scrollProxy: $proxy) { ... }

// toolbar
.toolbar {
    Button("回到今天") { proxy?.scrollToToday() }
}
```

三个模块都遵循此约定：
- `InfiniteScrollView` 暂未提供 proxy（通用列表一般不需要日期跳转）
- `InfiniteDateScrollView`：`scrollProxy: Binding<InfiniteScrollProxy?>?`
- `InfiniteDayScrollView`：`scrollProxy: Binding<DayScrollProxy?>?`

---

## 模块独有架构

### InfiniteScroll：双状态分离

```
InfiniteState（整体）       InfiniteFooterState（底部分页）
─────────────              ─────────────
.idle                      .none
.loading（首次）            .loading
.loaded                    .failed（可重试，不丢数据）
.empty                     .noMore
.failed
```

`InfiniteStore` 同时维护两个状态：
- `state` 决定首屏（loading / empty / failed / 正常）
- `footerState` 决定列表底部 footer（loading / failed / noMore）

分离的好处：分页失败时已加载的数据保留，footer 显示重试按钮，不与首屏状态混淆。

### InfiniteScrollWithDate：游标驱动 + 局部分组

```
loadPage(nextId: nil) → Page<Item>(records, nextId, hasMore)
                              │
                              ▼
                       records 按 .date 落入分组
                              │
                              ▼
           TimelineSection(date, items)  ← ForEach
                              │
                              ▼
              TimelineGrouping.day/week/month/year
              决定 date → sectionKey 的归一化规则
```

与 InfiniteScrollWithDay 的关键差异：
- InfiniteScrollWithDate：数据是「一维分页流」，前端按记录的 `date` 局部分组
- InfiniteScrollWithDay：日期是「预先展开的骨架」，前端逐天向数据源要数据

### InfiniteScrollWithDay：双向 + 折叠

```
                     today (anchor)
                         ▲
   future ←──────────────┼─────────────→ past
   loadMoreFuture()      │             loadMorePast()
                         │
                  days: [DayModel]  （降序：今天在前）
                         │
                         ▼
            CollapseAggregator.aggregate(days, strategy:)
                         │
                         ▼
            [DaySectionItem]  ← ForEach
            ├── .day(model)
            ├── .gap(GapRange)
            └── .loading(key)
```

- `days` 数组只存「已确定 state」的日，不预展开未加载的日
- 双向加载时头部 `insert(contentsOf:)` 后用 `scrollPosition` 锚定原可视日避免跳动
- `CollapseAggregator` 是纯函数，按策略聚合为 `[DaySectionItem]`：
  - `.showAll`：保留所有日为 `.day`
  - `.hideEmpty`：过滤空日
  - `.collapse`：连续 ≥ 2 空日合为 `.gap`（GapRange）

### DayKey：UTC-only

```swift
public struct DayKey: Hashable, Comparable, Sendable {
    public let daySinceEpoch: Int   // 自 1970-01-01 UTC 起的天数
}
```

设计取舍：
- 不接受 calendar 参数，避免时区漂移
- `init(date:)` 用 `date.timeIntervalSince1970 / 86_400`（向负无穷取整）算 `daySinceEpoch`
- 跨时区数据可共享（数据库存 `daySinceEpoch` 与本地时区无关）
- 本地化展示由调用方在 View 层用 `DateFormatter` 处理

---

## 并发模型

```
                        ┌─── MainActor ────┐
                        │                  │
                        │  @Observable     │
                        │   Controller     │   ← 状态读写锁主线程
                        │   /Engine/Store  │
                        │                  │
                        └──────────────────┘
                                ▲
                                │ await
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
   (任意 actor)                                 (Sendable 闭包)
   DayDataSource.items(on:)                     AnyXxxLoader 持有的 fetch
   TimelineLoader.loadPage(nextId:)             跨 actor 边界
   InfiniteLoader.load(nextId:)
```

- 协议方法非隔离 `async throws`：实现方可选 actor / struct / class
- 状态机内部 `Task` 调协议方法，结果回写主线程
- 所有跨边界类型 `Sendable`：`Item` / `Page<Item>` / `DayKey` / `GapRange` 等

---

## 性能考虑

- `LazyVStack` 仅渲染可见 + 缓冲区视图
- `cache`（InfiniteScrollWithDay）/ 已加载 items（另两模块）命中即跳过 async
- `CollapseAggregator` 单次线性扫描 O(n)
- 子视图提取为独立 struct：SwiftUI 可跳过未变更子树的 body 计算
- ForEach 用稳定 ID（`DayKey.daySinceEpoch` / `Item.id`）避免身份漂移
