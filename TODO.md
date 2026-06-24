# TODO

> 详细实施计划见 `~/.claude/plans/lovely-wibbling-pillow.md`。
> 验证：每个阶段结束执行 `swift build`；M1 起额外 `swift test`；M2 起 `open App.xcworkspace` 手测 Demo。

## 进行中

（暂无）

## 已完成

- [x] **SwiftUIS-InfiniteScroll** 模块（基于游标分页的时间轴组件）
  - [x] M0 基础设施：Package.swift 新增 target + product + 测试 target
  - [x] M1 Models 与 Core
    - [x] `Models/Page.swift`：分页结果（records + nextId + hasMore）
    - [x] `Models/TimelineItem.swift`：业务模型协议（id + date）
    - [x] `Models/TimelineSection.swift`：分组结果
    - [x] `Core/TimelineLoader.swift` + `AnyTimelineLoader`：loadPage(nextId:) 协议
    - [x] `Core/TimelineGrouping.swift`：day / week / month / year
    - [x] `Core/TimelineState.swift`：idle / loading / loaded / empty / failed
    - [x] `Core/TimelineConfig.swift`：grouping / showEmptyDays / preloadThreshold / restoreScrollPosition
    - [x] `Core/TimelineEngine.swift`：@Observable @MainActor 状态机 + 分组聚合 + ScrollCommand
    - [x] `Extensions/Date+TimelineGrouping.swift`：分组键 + next/prev 步进
    - [x] 11 个单元测试通过（Date/Page/TimelineEngine）
  - [x] M2 Views 与 Configuration
    - [x] `Views/InfiniteScrollView.swift`：主组件（LazyVStack + Sticky Header + preloadThreshold）
    - [x] `Views/TimelineSectionView.swift`：单分组渲染
    - [x] `Views/DateHeaderView` / `LoadingTimelineView` / `ErrorTimelineView` / `EmptyTimelineView`：默认样式
    - [x] `Configuration/ViewBuilderKeys.swift`：dateHeader/loadingView/errorView/emptyView 四个 EnvironmentKey
    - [x] `.refreshable()` 下拉刷新
  - [x] M3 ScrollToDate 与 Demo
    - [x] `Configuration/InfiniteScrollProxy.swift`：scrollProxy binding + scrollTo(Date)
    - [x] Demo Tab4 演示（MockTimelineLoader + 跳转按钮）
    - [x] 全部 52 个测试通过

## 待办

- [ ] v1.2 高级布局（Timeline Layout / Waterfall Layout / Calendar Integration / Widget Support）

## 已完成

- [x] M0 基础设施（Support 模块）
  - [x] 创建 `Sources/SwiftUIS-InfiniteScrollWithDay/{Support,DataSource,Core,UI}` 四目录
  - [x] `Support/DayKey.swift`：日期标准化（UTC 基） + Comparable + Hashable + Sendable
  - [x] `Support/Calendar+DayOps.swift`：firstDayOfMonth / lastDayOfMonth / dayCount
  - [x] `Support/GapRange.swift`：折叠区间值类型
  - [x] `Support/DayRange.swift`：`.past(days:)` / `.between` / `.around` 描述符
  - [x] `Tests/.../DayKeyTests.swift` 通过

- [x] M1 Core 数据层（无 UI）
  - [x] `DataSource/DayDataSource.swift`：protocol + associatedtype Item
  - [x] `DataSource/AnyDayDataSource.swift`：类型擦除盒
  - [x] `DataSource/StaticDayDataSource.swift`：内存 mock
  - [x] `DataSource/EmptyStrategy.swift`：showAll / hideEmpty / collapse
  - [x] `Core/LoadingState.swift` + `Core/DayState.swift` + `Core/DayModel.swift` + `Core/DaySectionItem.swift`
  - [x] `Core/CollapseAggregator.swift`：连续空日聚合纯函数 + 测试
  - [x] `Core/InfiniteScrollController.swift`：`@Observable @MainActor` 状态机 + 测试
  - [x] 全部 36 个测试通过

- [x] M2 UI 主体（Demo 基础版能滚）
  - [x] `UI/InfiniteDayScrollView.swift`：三 init + ScrollViewReader/LazyVStack 骨架
  - [x] `UI/DaySection.swift`：`Section` + `pinnedViews: [.sectionHeaders]`
  - [x] `UI/LoadingSection.swift`：默认 ProgressView
  - [x] `UI/ScrollAnchors.swift`：sentinel ID 常量
  - [x] `App/Sources/BootView.swift`：Demo Tab1 基础版

- [x] M3 自定义能力（修饰符可注入）
  - [x] `UI/ViewBuilderKeys.swift`：四个 EnvironmentKey builder
  - [x] `UI/GapSection.swift`：collapse 折叠视图
  - [x] `UI/DayScrollProxy.swift`：scrollToToday / scrollTo / scrollToMonth
  - [x] Demo Tab2 数据驱动版（collapse 可见）

- [x] M4 Demo 与测试（完整版 + 全测试绿）
  - [x] Demo Tab3 完整版 + 定位按钮
  - [x] `App/Sources/Mock/MockTimeline.swift`：动态生成压力数据（10k 日期 / 100k 记录）
  - [x] `Tests/.../InfiniteScrollControllerTests.swift` 全绿
  - [x] `DayScrollProxy.scrollTo*` 支持 `animated` 参数（配合 reduceMotion 由调用方决定）

- [x] M5 文档
  - [x] `README.md` API 速查 + 三种用法示例
  - [x] `docs/00_CONTEXT.md` 项目背景
  - [x] `docs/01_API_REFERENCE.md` API 参考
  - [x] `docs/02_ARCHITECTURE.md` 架构设计
  - [x] `docs/03_GUIDES/quick-start.md` 快速入门
  - [x] `docs/04_CHANGELOG.md` v1.0 + v1.1(partial)
  - [x] 归档已完成项
