# 更新日志

## v1.0.0 - 2026-06-24

### 新增

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
- 定位：`DayScrollProxy`（scrollToToday / scrollTo / scrollToMonth）
- 修饰符：`.dayHeader` / `.emptyDayView` / `.gapView` / `.loadingView`

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
- 月份快速跳转（`DayScrollProxy.scrollToMonth`）
- `InfiniteScrollConfig` 集中配置

### 待实现（剩余 v1.1 + v1.2）

- 日期选择器集成
- Timeline Layout
- Waterfall Layout
- Calendar Integration
- Widget Support
