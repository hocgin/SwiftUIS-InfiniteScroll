# 项目背景

## 仓库定位

`SwiftUIS-InfiniteScroll` 是一组 SwiftUI 无限滚动组件库，按数据形态拆分为三个**互不依赖**的 SwiftPM target：

| 模块 | 解决的问题 | 数据形态 |
|---|---|---|
| `SwiftUIS-InfiniteScroll` | 通用游标分页列表（信息流 / 聊天 / 商品列表） | 一维记录 + 下一页游标 |
| `SwiftUIS-InfiniteScrollWithDate` | 多粒度时间轴（按 day / week / month / year 自动分组） | 游标分页记录（记录自带 `date`） |
| `SwiftUIS-InfiniteScrollWithDay` | 按天预知边界的日记 / 时间记录 | 按日期回调 `items(on: day)` |

## 三类典型场景

### 通用列表 — `InfiniteScrollView`

- 信息流（社交 / 视频 / 图文）
- 聊天历史（向下加载更早消息）
- 商品 / 文章列表
- 评论分页

特征：业务模型无日期概念，只需要「下一页游标」即可对接。

### 时间轴 — `InfiniteDateScrollView`

- 操作日志 / 审计轨迹
- 多源聚合的事件流（同一周内不同来源的事件合到一个 week 分组）
- 长跨度时间检索（按月 / 年快速浏览）

特征：后端返回的是一维分页数据，每条记录自带时间戳；前端按所选粒度做局部分组。

### 日记 / 习惯 — `InfiniteDayScrollView`

- 日记 / 复盘 / 习惯追踪
- 时间记录（Time Tracking）
- 财务流水（按天）
- 运动记录

特征：日期是「骨架」，UI 侧负责迭代展开每一天；调用方只回答「某天有哪些记录」。

## 技术栈

- Swift 6（严格并发：`@MainActor` / `Sendable` / `@Observable`）
- SwiftPM 多 target 包管理
- SwiftUI（iOS 17+ / macOS 15+）
- 第三方依赖：仅 `swift-log`
- 国际化：String Catalog（`.xcstrings`），源语言为 `en`，同时提供 `zh-Hans` / `zh-Hant` 翻译；每模块通过 `L10n` 类型安全命名空间（`Label` / `Action` / `Message`）暴露文案

## 设计取舍

### 共性

- **值类型副本修饰符**：`.dateHeaderView {}` / `.emptyView {}` 等限定到具体主组件，返回同类型，链式调用不断类型。不再放在 `extension View` 上，避免跨模块同名歧义。
- **EnvironmentKey 传递自定义能力**：避免主 `init` 参数爆炸。修饰符内部写私有 builder 字段，`body` 中应用 `.environment(key, builder ?? .default)`。
- **@MainActor 状态机**：Controller / Engine / Store 都是 `@MainActor @Observable`，状态读写锁定主线程；Loader / DataSource 协议方法是非隔离 `async throws`，业务方可在任意 actor 实现。
- **iOS 17+ `scrollPosition(id:)`**：用于跳转，避开 `ScrollViewReader.scrollTo` 在未渲染 LazyVStack 元素上失效的问题。
- **onAppear 哨兵**：底部 `Color.clear.frame(height:)` 触发下一页加载，扩大命中区防快滚错过。

### 各模块独有

- **InfiniteScrollView**：FooterState（`none / loading / failed / noMore`）独立于 InfiniteState（首次加载状态），让分页失败可视化和重试解耦。
- **InfiniteDateScrollView**：`TimelineGrouping`（day/week/month/year）+ `showEmptyDays` 控制空分组；`TimelineItem` 协议要求 `id: String` + `date: Date`。
- **InfiniteDayScrollView**：`EmptyStrategy`（`showAll / hideEmpty / collapse`）+ 双向加载（`forwardLoading`）；`DayKey` 基于 UTC 保证跨时区往返一致；`InfiniteDayScrollViewInfiniteScrollProxy` 通过 `scrollProxy:` binding 暴露给父视图（如 toolbar）。

## 选择指南

| 你的需求 | 选 |
|---|---|
| 后端只给我「下一页游标」，数据无日期维度 | InfiniteScrollView |
| 后端给我一维分页数据，每条带时间戳，想按月/周分组展示 | InfiniteDateScrollView |
| 我有「某一天有哪些记录」的查询接口，UI 按天展开 | InfiniteDayScrollView |
| 数据量小、不分页、就是想滚动到某天 | InfiniteDayScrollView（基础版 `range:`） |
