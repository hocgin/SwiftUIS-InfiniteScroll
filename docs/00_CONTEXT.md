# 项目背景

## 定位

`SwiftUIS-InfiniteScrollWithDay` 是一个 SwiftUI 库，提供按日期分组的无限滚动组件 `InfiniteDayScrollView`。

## 解决的问题

开发者构建「时间线」类应用（日记、时间记录、复盘等）时，需要重复处理：

- 日期分页与无限加载
- 日期分组渲染
- 空日期展示（隐藏 / 折叠）
- 日期定位（跳转到今天 / 某月）
- Sticky Header
- 滚动状态维护

本库把这些通用逻辑封装为一个稳定、可组合的组件，开发者只需提供数据即可。

## 适用场景

- 时间记录（Time Tracking）
- 日记（Journal）
- 复盘（Review）
- 计划管理（Planning）
- 习惯追踪（Habit Tracker）
- 运动记录（Fitness Log）
- 财务流水（Expense Tracker）
- 事件时间线（Timeline）

## 技术栈

- Swift 6（严格并发）
- SwiftPM 包管理
- SwiftUI（iOS 17+ / macOS 15+）
- 无第三方 UI 依赖（仅 swift-log）

## 设计取舍

- **DayKey 基于 UTC**：保证 `referenceDate` 往返一致，跨时区数据可共享。本地化展示由调用方在 View 层用 `DateFormatter` 处理。
- **基础版独立 Item 类型**：用 `PlaceholderItem` 占位，让 `InfiniteDayScrollView<Item, Content>` 在基础版可推断为 `Item == PlaceholderItem`。
- **类型擦除 DataSource**：`AnyDayDataSource<Item>` 让 Controller / View 持有具体 Item，不暴露 associatedtype。
- **EnvironmentKey 传递修饰符**：`.dayHeader {}` / `.emptyDayView {}` 等避免主 init 参数爆炸。
- **onAppear 哨兵触发加载**：iOS 17+ 原生 API，避免依赖 iOS 18 的 `scrollPosition` 绑定。
