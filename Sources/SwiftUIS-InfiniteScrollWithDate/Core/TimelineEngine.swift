import Foundation
import Observation
import os

/// 模块级 logger（基于 OSLog）。
private let logger = Logger(subsystem: "com.hocgin.SwiftUIS-InfiniteScroll", category: "TimelineEngine")

/// 跳转命令：Engine 发出，View 监听后写入 scrollPosition。
public struct ScrollCommand: Sendable, Equatable {
    public let key: Date
    public let token: Int

    public init(key: Date, token: Int) {
        self.key = key
        self.token = token
    }
}

/// 时间轴状态机：驱动分页加载 + 分组聚合 + 空日填充。
///
/// 隔离边界：`@MainActor` 保证状态读写都在主线程。
/// Loader 协议方法是非隔离 `async throws`，可在任意 actor 实现。
@MainActor
@Observable
public final class TimelineEngine<Item: TimelineItem>: InfiniteScrollable {

    // MARK: - 公开状态

    /// 已聚合的分组列表（按 date 降序：最新在前）。
    public private(set) var sections: [TimelineSection<Item>] = []

    /// 当前加载状态。
    public private(set) var state: TimelineState = .idle

    /// 是否还有更多数据可加载。
    public private(set) var hasMore: Bool = true

    /// 最近一次错误（state == .failed 时非 nil）。
    public private(set) var lastError: Error?

    // MARK: - 配置与依赖

    public let config: TimelineConfig
    public let loader: AnyTimelineLoader<Item>

    /// 用于分组计算的日历。默认 .current，跨时区场景可显式注入。
    public let calendar: Calendar

    // MARK: - 私有

    /// 所有已加载记录（按加载顺序，未分组）。
    private var records: [Item] = []

    /// 下一页游标。
    private var nextId: String?

    /// 进行中的加载 Task，去重。
    private var loadTask: Task<Void, Never>?

    /// 是否已 bootstrap。
    private var isBootstrapped = false

    // MARK: - 初始化

    public init<L: TimelineLoader>(
        loader: L,
        config: TimelineConfig = .init(),
        calendar: Calendar = .current
    ) where L.Item == Item {
        self.loader = AnyTimelineLoader(loader)
        self.config = config
        self.calendar = calendar
    }

    /// 直接用类型擦除的 Loader 构造（测试 / Demo 场景）。
    public init(
        loader: AnyTimelineLoader<Item>,
        config: TimelineConfig = .init(),
        calendar: Calendar = .current
    ) {
        self.loader = loader
        self.config = config
        self.calendar = calendar
    }

    // MARK: - 生命周期

    // MARK: - InfiniteScrollable

    /// 滚动到指定日期所属分组：计算分组键，发送 scrollCommand。
    public func scrollToDate(_ date: Date) {
        let key = date.timelineGroupKey(config.grouping, calendar: calendar)
        scrollToken += 1
        scrollCommand = ScrollCommand(key: key, token: scrollToken)
    }

    /// 跳转命令（供 View 监听写入 scrollPosition）。
    public private(set) var scrollCommand: ScrollCommand?

    /// 命令计数器，保证连续跳转同一分组也触发 onChange。
    private var scrollToken = 0

    /// 首次加载。幂等。
    public func bootstrap() {
        guard !isBootstrapped else { return }
        isBootstrapped = true
        loadNextPage()
    }

    /// 加载下一页（如果还有）。
    public func loadNextPage() {
        guard state != .loading, hasMore else { return }
        if loadTask != nil { return }

        state = .loading
        let cursor = nextId
        let loader = loader

        // Task 继承当前 actor（@MainActor），body 内已在主线程。
        // 不再用 MainActor.run（避免重复调度与潜在死锁）。
        loadTask = Task { [weak self] in
            do {
                let page = try await loader.loadPage(nextId: cursor)
                guard let self else { return }
                self.records.append(contentsOf: page.records)
                self.nextId = page.nextId
                self.hasMore = page.hasMore
                self.sections = self.aggregate(self.records)
                self.lastError = nil
                self.state = self.records.isEmpty ? .empty : .loaded
                self.loadTask = nil
            } catch {
                guard let self else { return }
                self.lastError = error
                self.state = .failed
                self.loadTask = nil
                logger.error("TimelineEngine load failed: \(String(describing: error))")
            }
        }
    }

    /// 重置并重新加载首页（下拉刷新场景）。
    public func reload() {
        loadTask?.cancel()
        loadTask = nil
        records.removeAll()
        sections.removeAll()
        nextId = nil
        hasMore = true
        lastError = nil
        state = .idle
        isBootstrapped = true
        loadNextPage()
    }

    // MARK: - 聚合

    /// 把 records 按 config.grouping 聚合为 sections（含可选空日填充）。
    ///
    /// - Parameter allRecords: 全部已加载记录
    /// - Returns: 按 date 降序的 sections
    private func aggregate(_ allRecords: [Item]) -> [TimelineSection<Item>] {
        // 1. 按分组键聚合
        var grouped: [Date: [Item]] = [:]
        for record in allRecords {
            let key = record.date.timelineGroupKey(config.grouping, calendar: calendar)
            grouped[key, default: []].append(record)
        }

        // 2. 按日期降序
        let sortedKeys = grouped.keys.sorted(by: >)

        // 3. 构造 sections
        var sections: [TimelineSection<Item>] = []
        for key in sortedKeys {
            if let items = grouped[key] {
                sections.append(TimelineSection(date: key, items: items, isEmptyPlaceholder: false))
            }
        }

        // 4. 可选：空日填充
        if config.showEmptyDays {
            sections = fillEmptyGroups(sections)
        }

        return sections
    }

    /// 在相邻 sections 之间插入空 section，让分组在时间上连续。
    ///
    /// 例：day 粒度下 [6.24, 6.22] → [6.24, 6.23(empty), 6.22]。
    ///
    /// - 重要：sections 是降序（最新在前），所以 cursor 从 current 往过去方向步进。
    private func fillEmptyGroups(_ sections: [TimelineSection<Item>]) -> [TimelineSection<Item>] {
        guard sections.count >= 2 else { return sections }

        var result: [TimelineSection<Item>] = []
        for (index, section) in sections.enumerated() {
            result.append(section)
            guard index + 1 < sections.count else { continue }

            let current = section.date
            let next = sections[index + 1].date
            // 从 current 的前一组开始，往过去方向步进，直到 <= next。
            var cursor = current.prevTimelineGroupStart(config.grouping, calendar: calendar)
            while cursor > next {
                result.append(TimelineSection(date: cursor, items: [], isEmptyPlaceholder: true))
                cursor = cursor.prevTimelineGroupStart(config.grouping, calendar: calendar)
            }
        }
        return result
    }
}
