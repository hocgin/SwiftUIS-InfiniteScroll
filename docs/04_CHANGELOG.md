# 更新日志

## v2.2.0 - 2026-06-26

### 新增

#### 顶部整体 header 修饰符 `.headerView {}`

三个主组件（`InfiniteScrollView` / `InfiniteDateScrollView` / `InfiniteDayScrollView`）均新增 `.headerView { }` 修饰符，用于在 `ScrollView` 内容顶部添加一个整体 header 视图。

- 与 `.dateHeaderView`（每个日期/分组头，数量多个）不同：`.headerView` 是整个内容顶部的**单一**视图
- 随内容一起滚动（非固定吸顶）；常驻显示，不参与空/加载状态切换
- 沿用「值类型副本」模式：内部 `headerViewBuilder` 在主组件 body 直接渲染，不走 EnvironmentKey（无需传递给子视图）

```swift
InfiniteScrollView(loader: FeedLoader()) { item in FeedRow(item) }
    .headerView { FeedListHeader() }
```

## v2.1.0 - 2026-06-25

### 重大变更

#### 日期头修饰符重命名

- **breaking**：`InfiniteDateScrollView` 与 `InfiniteDayScrollView` 的日期头修饰符 `.header` 改名为 `.dateHeaderView`
  - 旧：`.header { ctx in ... }`
  - 新：`.dateHeaderView { ctx in ... }`
  - 原因：`.header` 语义过宽，限定为 `.dateHeaderView` 后与 `.emptyView` / `.loadingView` 等修饰符命名风格统一，并避免跨模块同名歧义
  - 内部存储属性 `headerBuilder` 命名保留不变

## v2.0.0 - 2026-06-25

### 重大变更

仓库重命名为 `SwiftUIS-InfiniteScroll`，组织为三个互不依赖的 SwiftPM target。

#### 新增模块：`SwiftUIS-InfiniteScroll`

通用游标分页列表，无业务模型耦合。

- `InfiniteScrollView<Item, Content>` 主组件（2 个 init：loader / store）
- `InfiniteLoader` 协议 + `AnyInfiniteLoader` + `load(nextId:) -> Page<Item>`
- `InfiniteStore<Item>`（@MainActor @Observable）：双状态分离
  - `state`：首次加载状态（idle / loading / loaded / empty / failed）
  - `footerState`：底部分页状态（none / loading / failed / noMore）
- `PreloadStrategy`：`.fixed(N)` / `.ratio(0.8)`，默认 `.fixed(5)`
- 默认视图：`InfiniteListEmptyView` / `InfiniteListLoadingView` / `InfiniteListErrorView` / `InfiniteListFooterView`
- 修饰符：`.emptyView` / `.loadingView` / `.errorView` / `.footerView`
- **下拉刷新默认关闭**：按需附加 `.refreshable { await store.reloadAsync() }`
- 设计：分页失败不丢数据，footer 显示重试按钮

#### 新增模块：`SwiftUIS-InfiniteScrollWithDate`

按 day / week / month / year 自动分组的时间轴；游标分页驱动。

- `InfiniteDateScrollView<Item, Content>` 主组件（2 个 init：完整版 / PRD 扁平化）
- `TimelineLoader` 协议 + `AnyTimelineLoader` + `loadPage(nextId:) -> Page<Item>`
- `TimelineItem` 协议：`id: String` + `date: Date`
- `TimelineGrouping`：`day / week / month / year`（默认 day）
- `TimelineConfig`：grouping / showEmptyDays / preloadThreshold / restoreScrollPosition
- `TimelineEngine<Item>`（@MainActor @Observable）：状态机
- `InfiniteDateScrollViewInfiniteScrollProxy`：`scrollTo(date)` 跳转
- `scrollProxy: Binding<InfiniteDateScrollViewInfiniteScrollProxy?>?`：暴露给父视图（toolbar）
- 修饰符：`.header` / `.loadingView` / `.errorView` / `.emptyView`

#### `SwiftUIS-InfiniteScrollWithDay`（原 v1.0 模块，本次保留）

按天分组的日记 / 时间记录。

- API 保持兼容
- 修饰符名变更（见下）

#### 修饰符重构（影响全部三个模块）

- **breaking**：从 `extension View` 改为限定到具体主组件
  - 旧：`extension View { func dayHeader(...) -> some View }`
  - 新：`extension InfiniteDayScrollView { func header(...) -> InfiniteDayScrollView<Item, Content> }`
- **breaking**：删除前缀（`dayHeader` → `header`，`emptyDayView` → `emptyView`）
- **breaking**：删除别名（`listEmptyView` / `listLoadingView` / `listErrorView` / `listFooterView`）
- 采用「值类型副本」模式（参考 ScalingHeaderScrollView）：`var copy = self; copy.xxxBuilder = ...; return copy`，保持链式调用类型一致
- 解决问题：跨模块同名 modifier 在 import 后产生歧义

#### 跳转 Proxy 类型重命名（三模块统一约定）

为避免跨模块 import 时跳转代理同名歧义，三模块统一采用 `<主组件>InfiniteScrollProxy` 命名：

- **breaking**：`SwiftUIS-InfiniteScrollWithDate.InfiniteScrollProxy` → `InfiniteDateScrollViewInfiniteScrollProxy`
- **breaking**：`SwiftUIS-InfiniteScrollWithDay.DayScrollProxy` → `InfiniteDayScrollViewInfiniteScrollProxy`
- 新增 `SwiftUIS-InfiniteScroll.InfiniteScrollViewInfiniteScrollProxy<Item>`（按 id 跳转，泛型保留 Item 类型）

注：`InfiniteDayScrollView` 的 environment key path `\.dayScrollProxy` 与协议 `DayScrollable` 命名保留不变，仅 public 类型重命名。

### 迁移指南（v1 → v2）

```swift
// v1
InfiniteDayScrollView(source: src) { ... }
    .dayHeader { Header($0) }
    .emptyDayView { EmptyView() }
    .gapView { GapView($0) }

// v2
InfiniteDayScrollView(source: src) { ... }
    .header { ctx in Header(ctx) }      // 入参改 DayHeaderContext
    .emptyView { EmptyView() }
    .gapView { GapView($0) }
```

跳转 Proxy 类型重命名：

```swift
// v1 / 旧 v2.0
@State private var dateProxy: InfiniteScrollProxy?
@State private var dayProxy: DayScrollProxy?

// v2
@State private var dateProxy: InfiniteDateScrollViewInfiniteScrollProxy?
@State private var dayProxy: InfiniteDayScrollViewInfiniteScrollProxy?
```

### 性能

- LazyVStack + onAppear 哨兵触发增量加载
- 三个模块的状态机均 `@MainActor @Observable`
- 跳转用 iOS 17+ `scrollPosition(id:)` 双向绑定（替代失效的 `ScrollViewReader.scrollTo`）

### 平台

- iOS 17+
- macOS 15+
- Swift 6 严格并发安全

### 国际化

三模块统一接入 String Catalog（`.xcstrings`），源语言为 `en`，同时提供 `zh-Hans` 与 `zh-Hant` 翻译：

- 每个模块新增 `L10n` 类型安全命名空间（`Label` / `Action` / `Message`），统一通过 `String(localized:defaultValue:bundle:comment:)` 加 `.module` bundle 引用文案，移除硬编码 String 字面量；`defaultValue` 采用英文作为开发期通用基准
- `SwiftUIS-InfiniteScroll`：7 条（emptyData / loading / loadFailed / loadFailedWithHint / noMore / retry / loadFailedGeneric）
- `SwiftUIS-InfiniteScrollWithDate`：4 条（emptyData / emptySection / loadFailed / retry）
- `SwiftUIS-InfiniteScrollWithDay`：4 条（emptyDay / loadFailed / gapSeparator / `gapDays(_:)` 含复数形式）

### 测试

- 63 个单元测试覆盖三模块核心逻辑
  - `DayKey` / `Calendar+DayOps` / `DayRange` / `GapRange`
  - `CollapseAggregator` 三策略
  - `StaticDayDataSource` / `AnyDayDataSource`
  - `InfiniteScrollController` bootstrap / loadMorePast / loadMoreFuture / retry
  - `InfiniteStore` bootstrap / loadMore / preload / retry / 分页失败不丢数据
  - `TimelineEngine` bootstrap / loadNextPage / preloadThreshold / retry / showEmptyDays

---

## v1.0.0 - 2026-06-24

### 初始版本（仅 `SwiftUIS-InfiniteScrollWithDay`）

- 核心：`InfiniteDayScrollView<Item, Content>` 主组件
  - 基础版 init：`InfiniteDayScrollView(range:) { day in ... }`
  - 数据驱动版 init：`InfiniteDayScrollView(source:) { day, items in ... }`
  - 完整版 init：自定义 batchSize / emptyStrategy / stickyHeader / forwardLoading
- 数据源：`DayDataSource` 协议 + `AnyDayDataSource` + `StaticDayDataSource`
- 状态：`LoadingState` / `DayState<Item>` / `DayModel<Item>` / `DaySectionItem<Item>`
- 算法：`CollapseAggregator` 三策略聚合（showAll / hideEmpty / collapse）
- 控制器：`InfiniteScrollController<Item>`（@Observable @MainActor）
- 视图：`DaySection` / `GapSection` / `LoadingSection` / `DayHeader` / `EmptyDayView`
- 工具：`DayKey`（UTC 基） / `DayRange` / `GapRange` / `Calendar+DayOps`
- 定位：`InfiniteDayScrollViewInfiniteScrollProxy`（scrollToToday / scrollTo / scrollToMonth）
- 修饰符（旧名）：`.dayHeader` / `.emptyDayView` / `.gapView` / `.loadingView`

### 性能

- LazyVStack + onAppear 哨兵触发增量加载
- 缓存命中跳过 async
- ForEach 稳定 ID（DayKey.daySinceEpoch）

### 平台

- iOS 17+
- macOS 15+
- Swift 6 严格并发安全

### 测试

- 36 个单元测试覆盖 DayKey / Calendar+DayOps / DayRange / GapRange / StaticDayDataSource / AnyDayDataSource / CollapseAggregator / InfiniteScrollController

---

## v1.1.0 (partial) - 2026-06-24

### 新增（部分 v1.1 内容）

- `collapse` 折叠策略（推荐默认）
- 双向加载（`forwardLoading: true` 启用向上加载更晚日期）
- 月份快速跳转（`InfiniteDayScrollViewInfiniteScrollProxy.scrollToMonth`）
- `InfiniteScrollConfig` 集中配置

### 待实现（剩余 v1.1 + v1.2）

- 日期选择器集成
- Timeline Layout
- Waterfall Layout
- Calendar Integration
- Widget Support
