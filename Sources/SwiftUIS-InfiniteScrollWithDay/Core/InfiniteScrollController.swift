import Foundation
import SwiftUI
import Observation

/// 跳转命令：Controller 发出，View 监听后写入 scrollPosition。
public struct ScrollCommand: Equatable, Sendable {
    public let key: DayKey
    public let anchor: UnitPoint?
    public let animated: Bool
    public let token: Int

    public init(key: DayKey, anchor: UnitPoint?, animated: Bool, token: Int) {
        self.key = key
        self.anchor = anchor
        self.animated = animated
        self.token = token
    }
}

/// Controller 配置：不可变快照，构造后不再修改。
///
/// 抽离为独立 struct 让 init 参数集中、可比较，便于测试。
public struct InfiniteScrollConfig: Sendable, Equatable {

    public let batchSize: Int
    public let emptyStrategy: EmptyStrategy
    public let stickyHeader: Bool
    public let forwardLoading: Bool

    /// 连续多少批全空后停止向下/向上加载。
    ///
    /// 数据耗尽场景的安全网：例如用户只有 60 天数据，剩下全空，
    /// 连续 N 批（默认 5 批 × 30 天 = 150 天空档）后自动停止，避免无限滚动。
    /// 设为 0 禁用此机制（严格无限）。
    public let maxConsecutiveEmptyBatches: Int

    public init(
        batchSize: Int = 30,
        emptyStrategy: EmptyStrategy = .collapse,
        stickyHeader: Bool = true,
        forwardLoading: Bool = false,
        maxConsecutiveEmptyBatches: Int = 5
    ) {
        // batchSize 至少 1，否则永远加载不到任何日期。
        // 不用 precondition：钳制比崩溃更友好，测试也覆盖此分支。
        self.batchSize = max(batchSize, 1)
        self.emptyStrategy = emptyStrategy
        self.stickyHeader = stickyHeader
        self.forwardLoading = forwardLoading
        self.maxConsecutiveEmptyBatches = max(maxConsecutiveEmptyBatches, 0)
    }
}

/// 无限滚动状态机。
///
/// 职责：
/// - 维护有序 `days: [DayModel]`（按 DayKey 降序：今天在前，向下日期递减）
/// - 接收 DataSource 异步结果，更新对应 DayModel.state
/// - 提供 `sectionItems: [DaySectionItem]` 供 ForEach 渲染（按 strategy 聚合）
/// - 通过 onAppear 哨兵触发 `loadMorePast` / `loadMoreFuture`
/// - 暴露 `proxy` 给 InfiniteDayScrollViewInfiniteScrollProxy 做日期定位
///
/// 隔离边界：`@MainActor` 保证所有状态读写都在主线程，跨 actor 仅通过 await DataSource。
@MainActor
@Observable
public final class InfiniteScrollController<Item: Sendable & Identifiable>: DayScrollable {

    // MARK: - 公开状态（@Observable 跟踪）

    /// 有序日期数组。降序排列：今天在前，向下递减。
    public private(set) var days: [DayModel<Item>] = []

    /// 加载状态：过去方向（向下滚加载更早日期）。
    public private(set) var pastState: LoadingState = .idle

    /// 加载状态：未来方向（向上滚加载更晚日期）。
    ///
    /// 仅当 `config.forwardLoading == true` 才有意义。
    public private(set) var futureState: LoadingState = .idle

    /// 是否还有更早数据可加载。
    ///
    /// 当前实现：默认 true（无限）。若需要上限（如最早只到 1970），子类可重写。
    public private(set) var hasMorePast: Bool = true

    /// 是否还有更晚数据可加载（不晚于今天）。
    public private(set) var hasMoreFuture: Bool = true

    // MARK: - 配置与依赖

    public let config: InfiniteScrollConfig
    public let dataSource: AnyDayDataSource<Item>

    /// 初始锚点：决定首批日期范围的中点（默认今天）。
    public let anchor: DayKey

    // MARK: - 私有状态

    /// 已实例化的日期范围（含两端），用于决定下一批扩展方向。
    private var visibleRange: ClosedRange<DayKey>?

    /// 已加载数据缓存：DayKey → items。命中即跳过 async。
    private var cache: [DayKey: [Item]] = [:]

    /// 进行中的单日加载 Task，去重防止重复请求。
    private var loadTokens: [DayKey: Task<Void, Never>] = [:]

    /// 当前 past 批次尚未完成的 DayKey 集合。
    ///
    /// 全部清空时才把 `pastState` 切回 `.loaded`，
    /// 防止 onAppear 在 batch 进行中重复触发新批次。
    private var pendingPastDays: Set<DayKey> = []

    /// 当前 future 批次尚未完成的 DayKey 集合（同上）。
    private var pendingFutureDays: Set<DayKey> = []

    /// 连续全空批次数（past 方向）。达到 config.maxConsecutiveEmptyBatches 时停止。
    private var consecutiveEmptyPastBatches = 0

    /// 连续全空批次数（future 方向）。
    private var consecutiveEmptyFutureBatches = 0

    /// 已 bootstrap 标记，避免重复初始化。
    private var isBootstrapped = false

    /// 跳转命令：InfiniteDayScrollView 监听此字段变化，写入 scrollPosition 触发滚动。
    ///
    /// 用 token 保证连续跳转同一 key 也能触发 onChange。
    public private(set) var scrollCommand: ScrollCommand?

    /// 跳转命令计数器。
    private var scrollToken = 0

    // MARK: - 初始化

    public init(
        dataSource: AnyDayDataSource<Item>,
        anchor: Date = Date(),
        config: InfiniteScrollConfig = .init()
    ) {
        self.dataSource = dataSource
        self.anchor = DayKey(date: anchor)
        self.config = config
        // 默认不允许向未来加载（今天已是上界）。
        self.hasMoreFuture = config.forwardLoading
    }

    // MARK: - 渲染派生

    /// 当前渲染单元（按 strategy 聚合后的结果）。
    ///
    /// UI 层 ForEach 直接消费。读取 days 与 config.emptyStrategy，自动被 @Observable 跟踪。
    public var sectionItems: [DaySectionItem<Item>] {
        CollapseAggregator.aggregate(days, strategy: config.emptyStrategy)
    }

    // MARK: - 生命周期

    /// 初始化首批数据。
    ///
    /// 幂等：重复调用不会重新实例化。
    /// 应在 View 的 .task 或 .onAppear 中调用。
    public func bootstrap() {
        guard !isBootstrapped else { return }
        isBootstrapped = true
        // 首批：从 anchor 向过去 batchSize 天。
        let batch = (0..<config.batchSize).map { offset in
            anchor.adding(days: -offset)
        }
        appendBatch(batch, direction: .past)
        // 若开启未来加载，首批也包含未来。
        if config.forwardLoading {
            let futureBatch = (1...config.batchSize).map { offset in
                anchor.adding(days: offset)
            }
            prependBatch(futureBatch, direction: .future)
        }
    }

    // MARK: - 滚动触发

    /// 加载更早日期（默认方向，向下滚触发）。
    public func loadMorePast() {
        guard pastState != .loading, hasMorePast else { return }
        guard let lowerBound = visibleRange?.lowerBound else { return }
        pastState = .loading
        let batch = (1...config.batchSize).map { offset in
            lowerBound.adding(days: -offset)
        }
        appendBatch(batch, direction: .past)
    }

    /// 加载更晚日期（仅 forwardLoading=true 时启用）。
    public func loadMoreFuture() {
        guard config.forwardLoading else { return }
        guard futureState != .loading, hasMoreFuture else { return }
        guard let upperBound = visibleRange?.upperBound else { return }
        futureState = .loading
        let batch = (1...config.batchSize).map { offset in
            upperBound.adding(days: offset)
        }
        prependBatch(batch, direction: .future)
    }

    /// 重置到初始状态并重新加载首批。
    ///
    /// 用于「下拉刷新」或「配置变更」场景。
    public func reload() {
        // 取消所有进行中 Task。
        for task in loadTokens.values { task.cancel() }
        loadTokens.removeAll()
        cache.removeAll()
        days.removeAll()
        visibleRange = nil
        pendingPastDays.removeAll()
        pendingFutureDays.removeAll()
        consecutiveEmptyPastBatches = 0
        consecutiveEmptyFutureBatches = 0
        pastState = .idle
        futureState = .idle
        hasMorePast = true
        hasMoreFuture = config.forwardLoading
        isBootstrapped = false
        bootstrap()
    }

    // MARK: - 内部：批次插入

    private enum Direction { case past, future }

    /// 把批次追加到 days 尾部（更早日期），并为每天启动加载 Task。
    ///
    /// - 注意：不在此处切 `pastState = .loaded`。state 由 `updateDayState`
    ///   在最后一个 day 加载完成时才切换，避免 onAppear 在 batch 未完成时重复触发。
    private func appendBatch(_ keys: [DayKey], direction: Direction) {
        let newModels = keys.map { key in
            DayModel<Item>(key: key, day: key.referenceDate, state: .loading)
        }
        days.append(contentsOf: newModels)
        updateVisibleRange(with: keys)
        // 跟踪本批未完成 day，全部加载完后才切 state。
        if direction == .past {
            pendingPastDays.formUnion(keys)
        } else {
            pendingFutureDays.formUnion(keys)
        }
        for key in keys {
            startLoad(for: key)
        }
    }

    /// 把批次插入到 days 头部（更晚日期）。
    private func prependBatch(_ keys: [DayKey], direction: Direction) {
        // 反转：keys 是按「越晚越后」排，prepend 时要保持降序（晚在前）。
        let reversed = keys.reversed()
        let newModels = reversed.map { key in
            DayModel<Item>(key: key, day: key.referenceDate, state: .loading)
        }
        days.insert(contentsOf: newModels, at: 0)
        updateVisibleRange(with: keys)
        pendingFutureDays.formUnion(keys)
        for key in keys {
            startLoad(for: key)
        }
    }

    /// 扩展 visibleRange 以覆盖新批次。
    private func updateVisibleRange(with keys: [DayKey]) {
        guard let firstKey = keys.first, let lastKey = keys.last else { return }
        let batchLower = min(firstKey, lastKey)
        let batchUpper = max(firstKey, lastKey)
        if let existing = visibleRange {
            visibleRange = min(existing.lowerBound, batchLower)...max(existing.upperBound, batchUpper)
        } else {
            visibleRange = batchLower...batchUpper
        }
    }

    // MARK: - 内部：单日加载

    /// 启动单日数据加载 Task。
    ///
    /// - 命中缓存：直接写状态，不发 async。
    /// - 未命中：创建 Task 调 dataSource，回写 cache 与 state。
    /// - 去重：若已有 Task 进行中，跳过。
    private func startLoad(for key: DayKey) {
        if let cached = cache[key] {
            updateDayState(.loaded(cached), forKey: key)
            return
        }
        if loadTokens[key] != nil { return }

        // Task 在调用方的 actor（main）启动；内部 await 跨边界到 dataSource 的 actor。
        let dataSource = dataSource
        let task = Task { [weak self] in
            do {
                let items = try await dataSource.items(on: key.referenceDate)
                // 回到 main actor 写状态。
                await MainActor.run {
                    guard let self else { return }
                    self.cache[key] = items
                    let state: DayState<Item> = items.isEmpty ? .empty : .loaded(items)
                    self.updateDayState(state, forKey: key)
                    self.loadTokens[key] = nil
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.updateDayState(.failed, forKey: key)
                    self.loadTokens[key] = nil
                    logger.error("DayScroll load failed for \(key.daySinceEpoch): \(String(describing: error))")
                }
            }
        }
        loadTokens[key] = task
    }

    /// 找到指定 DayKey 的 DayModel 并更新其 state。
    ///
    /// 同时从 `pendingPastDays` / `pendingFutureDays` 移除该 key；
    /// 当对应批次全部完成时切 state 为 `.loaded`，解除 onAppear 短路，
    /// 并检查「连续全空批次」阈值，必要时关闭 hasMorePast/hasMoreFuture。
    private func updateDayState(_ state: DayState<Item>, forKey key: DayKey) {
        // days 按 DayKey 降序，可二分查找；当前规模下线性扫足够。
        guard let index = days.firstIndex(where: { $0.key == key }) else { return }
        days[index].state = state

        pendingPastDays.remove(key)
        pendingFutureDays.remove(key)

        if pendingPastDays.isEmpty, pastState == .loading {
            pastState = .loaded
            evaluatePastEmptiness()
        }
        if pendingFutureDays.isEmpty, futureState == .loading {
            futureState = .loaded
            evaluateFutureEmptiness()
        }
    }

    /// 检查最近一批 past batch 是否全部为空，更新连续空批次计数。
    ///
    /// 若达到 `config.maxConsecutiveEmptyBatches` 阈值，关闭 `hasMorePast`，
    /// 防止数据耗尽后无限加载。
    private func evaluatePastEmptiness() {
        guard config.maxConsecutiveEmptyBatches > 0 else { return }
        guard days.count >= config.batchSize else { return }
        let recentBatch = days.suffix(config.batchSize)
        let allEmpty = recentBatch.allSatisfy { model in
            if case .empty = model.state { return true }
            return false
        }
        if allEmpty {
            consecutiveEmptyPastBatches += 1
            if consecutiveEmptyPastBatches >= config.maxConsecutiveEmptyBatches {
                hasMorePast = false
            }
        } else {
            consecutiveEmptyPastBatches = 0
        }
    }

    /// 同上，future 方向。
    private func evaluateFutureEmptiness() {
        guard config.maxConsecutiveEmptyBatches > 0 else { return }
        guard config.forwardLoading else { return }
        guard days.count >= config.batchSize else { return }
        let recentBatch = days.prefix(config.batchSize)
        let allEmpty = recentBatch.allSatisfy { model in
            if case .empty = model.state { return true }
            return false
        }
        if allEmpty {
            consecutiveEmptyFutureBatches += 1
            if consecutiveEmptyFutureBatches >= config.maxConsecutiveEmptyBatches {
                hasMoreFuture = false
            }
        } else {
            consecutiveEmptyFutureBatches = 0
        }
    }

    // MARK: - DayScrollable

    /// 实现日期定位。供 InfiniteDayScrollViewInfiniteScrollProxy 转发，外部不直接调用。
    ///
    /// - 若目标 key 超出当前 visibleRange：先扩展 days 数组覆盖目标，
    ///   再延后一帧执行 scrollTo（等 LazyVStack 渲染目标视图）。
    /// - 否则直接 scrollTo。
    public func scrollTo(_ key: DayKey, anchor: UnitPoint?, animated: Bool) {
        // 先扩展范围，让目标 day 进入 days 数组。
        ensureRangeContains(key)

        // 发出跳转命令：View 监听 scrollCommand 变化，
        // 写入 scrollPosition，由 ScrollView 自动渲染目标并滚动。
        scrollToken += 1
        scrollCommand = ScrollCommand(key: key, anchor: anchor, animated: animated, token: scrollToken)
    }

    /// 扩展 visibleRange 与 days 数组，使其包含目标 key。
    ///
    /// - 目标早于下界：appendBatch 过去方向的缺失日期。
    /// - 目标晚于上界：prependBatch 未来方向的缺失日期（即使 forwardLoading=false 也强制扩展，
    ///   因为这是用户主动跳转）。
    private func ensureRangeContains(_ target: DayKey) {
        if !isBootstrapped {
            bootstrap()
        }
        guard let range = visibleRange else { return }

        if target < range.lowerBound {
            let lower = target.daySinceEpoch
            let upper = range.lowerBound.daySinceEpoch - 1
            guard lower <= upper else { return }
            // keys 升序 [target, ..., range.lowerBound-1]；days 是降序，反转后追加到尾部。
            let keys = (lower...upper)
                .map { DayKey(daySinceEpoch: $0) }
                .reversed()
            appendBatch(Array(keys), direction: .past)
        } else if target > range.upperBound {
            let lower = range.upperBound.daySinceEpoch + 1
            let upper = target.daySinceEpoch
            guard lower <= upper else { return }
            // keys 升序 [range.upperBound+1, ..., target]；days 是降序，反转后插入到头部。
            let keys = (lower...upper)
                .map { DayKey(daySinceEpoch: $0) }
                .reversed()
            prependBatch(Array(keys), direction: .future)
        }
    }
}
