import Testing
import Foundation
import SwiftUI
@testable import SwiftUIS_InfiniteScrollWithDay

/// InfiniteScrollController 状态机测试。
///
/// Controller 是 @MainActor，所有测试用 @MainActor 注解。
@MainActor
@Suite struct InfiniteScrollControllerTests {

    private struct Item: Sendable, Identifiable, Equatable {
        let id: Int
    }

    /// 同步立即返回的 mock。
    private func makeSource(_ storage: [DayKey: [Item]]) -> AnyDayDataSource<Item> {
        AnyDayDataSource(StaticDayDataSource(storage: storage))
    }

    // MARK: - bootstrap

    @Test func bootstrap按batchSize实例化首批() {
        // 用 UTC 锚点避免本地时区导致 daySinceEpoch 偏移。
        let anchorKey = DayKey.today
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            anchor: anchorKey.referenceDate,
            config: .init(batchSize: 5)
        )

        #expect(ctrl.days.isEmpty)
        ctrl.bootstrap()

        #expect(ctrl.days.count == 5)
        // 顺序：anchor 在前，向下递减。用相对差比较，避免依赖具体 daySinceEpoch。
        let first = ctrl.days[0].key
        #expect(first == anchorKey)
        #expect(ctrl.days[1].key == first.adding(days: -1))
        #expect(ctrl.days[4].key == first.adding(days: -4))
    }

    @Test func bootstrap幂等() {
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            config: .init(batchSize: 3)
        )
        ctrl.bootstrap()
        let countAfterFirst = ctrl.days.count
        ctrl.bootstrap()
        ctrl.bootstrap()
        #expect(ctrl.days.count == countAfterFirst)
    }

    // MARK: - loadMorePast

    @Test func loadMorePast扩展下界() async {
        let anchorKey = DayKey.today
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            anchor: anchorKey.referenceDate,
            config: .init(batchSize: 5)
        )
        ctrl.bootstrap()
        // 初始下界：anchor - 4
        let firstLower = ctrl.days.last!.key
        #expect(firstLower == anchorKey.adding(days: -4))

        ctrl.loadMorePast()
        #expect(ctrl.days.count == 10)
        // 扩展后下界：firstLower - 5
        #expect(ctrl.days.last?.key == firstLower.adding(days: -5))

        // 等待 batch 完成：空数据源 Task 立即返回，但需让 MainActor.run 跑完。
        // 通过多次 yield 让 unstructured Task 调度执行。
        var attempts = 0
        while ctrl.pastState == .loading && attempts < 50 {
            await Task.yield()
            attempts += 1
        }
        #expect(ctrl.pastState == .loaded, "batch 完成后 pastState 应切回 .loaded")
    }

    @Test func 重复loadMorePast被短路() async {
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            config: .init(batchSize: 3)
        )
        ctrl.bootstrap()
        // 等首批 batch 完成。
        var attempts = 0
        while ctrl.pastState == .loading && attempts < 50 {
            await Task.yield()
            attempts += 1
        }

        let countBefore = ctrl.days.count
        ctrl.loadMorePast()
        let countAfter1 = ctrl.days.count
        // batch 进行中，第二次调用应被 pastState == .loading 短路。
        ctrl.loadMorePast()
        let countAfter2 = ctrl.days.count
        #expect(countAfter1 == countBefore + 3)
        #expect(countAfter2 == countAfter1, "batch 进行中时 loadMorePast 应被短路")
    }

    // MARK: - loadMoreFuture

    @Test func loadMoreFuture在forwardLoading关闭时无效() {
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            config: .init(batchSize: 3, forwardLoading: false)
        )
        ctrl.bootstrap()
        ctrl.loadMoreFuture()
        // 不应增加任何日。
        #expect(ctrl.days.count == 3)
    }

    @Test func loadMoreFuture在forwardLoading开启时扩展上界() {
        let anchorKey = DayKey.today
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            anchor: anchorKey.referenceDate,
            config: .init(batchSize: 3, forwardLoading: true)
        )
        ctrl.bootstrap()
        // bootstrap 先 append past 3 天（anchor, anchor-1, anchor-2），再 prepend future 3 天（anchor+1/+2/+3）
        // days 排序（降序）：anchor+3, anchor+2, anchor+1, anchor, anchor-1, anchor-2
        #expect(ctrl.days.count == 6)
        #expect(ctrl.days.first?.key == anchorKey.adding(days: 3))
        #expect(ctrl.days.last?.key == anchorKey.adding(days: -2))

        ctrl.loadMoreFuture()
        #expect(ctrl.days.count == 9)
        #expect(ctrl.days.first?.key == anchorKey.adding(days: 6))
    }

    // MARK: - sectionItems

    @Test func sectionItems按策略聚合() {
        let anchor = DayKey(daySinceEpoch: 1_000)
        // 仅 1000 与 998 有数据；999 为空。
        let storage: [DayKey: [Item]] = [
            anchor: [Item(id: 0)],
            anchor.adding(days: -2): [Item(id: 1)]
        ]
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource(storage),
            anchor: anchor.referenceDate,
            config: .init(batchSize: 3, emptyStrategy: .collapse)
        )
        ctrl.bootstrap()

        // 等待异步完成（同步 mock 实际立即返回，但 Task 调度需 yield）。
        // 这里直接断言最终状态。
        // 由于 Task 内 await MainActor.run 已完成，sectionItems 应反映 loaded/empty。
        let items = ctrl.sectionItems
        // 3 天：loaded, empty, loaded
        // collapse 下，单 empty 不折叠，保留为 .day
        #expect(items.count == 3)
    }

    // MARK: - config 前置条件

    @Test func batchSize小于1被钳制为1() {
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            config: .init(batchSize: 0)
        )
        ctrl.bootstrap()
        #expect(ctrl.days.count == 1)
    }

    // MARK: - 连续空批次停止

    @Test func 连续全空批次达阈值后停止加载() async {
        // 空数据源：每批必然全空。
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            config: .init(batchSize: 3, maxConsecutiveEmptyBatches: 2)
        )
        ctrl.bootstrap()
        // 等首批完成。
        var attempts = 0
        while ctrl.pastState == .loading && attempts < 50 {
            await Task.yield()
            attempts += 1
        }

        // 第一批全空：consecutiveEmptyPastBatches = 1
        ctrl.loadMorePast()
        attempts = 0
        while ctrl.pastState == .loading && attempts < 50 {
            await Task.yield()
            attempts += 1
        }
        // 第二批全空：consecutiveEmptyPastBatches = 2 → hasMorePast = false
        ctrl.loadMorePast()
        attempts = 0
        while ctrl.pastState == .loading && attempts < 50 {
            await Task.yield()
            attempts += 1
        }
        #expect(ctrl.hasMorePast == false, "连续 2 批全空后应停止向下加载")

        // 再调用 loadMorePast 应被 guard 拦截。
        let countBefore = ctrl.days.count
        ctrl.loadMorePast()
        #expect(ctrl.days.count == countBefore, "hasMorePast=false 后不应再扩展")
    }

    @Test func maxConsecutiveEmptyBatches为0时禁用停止逻辑() async {
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            config: .init(batchSize: 3, maxConsecutiveEmptyBatches: 0)
        )
        ctrl.bootstrap()
        var attempts = 0
        while ctrl.pastState == .loading && attempts < 50 {
            await Task.yield()
            attempts += 1
        }
        // 即使全空，hasMorePast 应保持 true（禁用阈值检查）。
        #expect(ctrl.hasMorePast)
    }

    // MARK: - 跳转扩展

    @Test func 跳转到过去日期会扩展visibleRange() {
        let anchorKey = DayKey.today
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            anchor: anchorKey.referenceDate,
            config: .init(batchSize: 5)
        )
        ctrl.bootstrap()
        // 初始范围：[anchor-4, anchor]
        let initialCount = ctrl.days.count

        // 跳转到 100 天前（远超首批 batchSize=5）
        let target = anchorKey.adding(days: -100)
        ctrl.scrollTo(target, anchor: .top, animated: false)

        // days 应扩展包含 target
        #expect(ctrl.days.count > initialCount)
        #expect(ctrl.days.contains { $0.key == target })
        // 扩展后最小 key 应 <= target（visibleRange 下界已覆盖目标）
        #expect(ctrl.days.last!.key <= target)
    }

    @Test func 跳转到已加载日期不重复扩展() {
        let anchorKey = DayKey.today
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            anchor: anchorKey.referenceDate,
            config: .init(batchSize: 5)
        )
        ctrl.bootstrap()
        let initialCount = ctrl.days.count

        // 跳转到 anchor-2（在首批范围内）
        ctrl.scrollTo(anchorKey.adding(days: -2), anchor: .top, animated: false)

        // days 数量不变
        #expect(ctrl.days.count == initialCount)
    }

    @Test func 跳转发出scrollCommand供View监听() {
        let anchorKey = DayKey.today
        let ctrl = InfiniteScrollController<Item>(
            dataSource: makeSource([:]),
            anchor: anchorKey.referenceDate,
            config: .init(batchSize: 5)
        )
        ctrl.bootstrap()

        // 跳转前无命令
        #expect(ctrl.scrollCommand == nil)

        let target = anchorKey.adding(days: -10)
        ctrl.scrollTo(target, anchor: .top, animated: true)

        // 跳转后命令已发出
        let command = ctrl.scrollCommand
        #expect(command != nil)
        #expect(command?.key == target)
        #expect(command?.animated == true)
        let firstToken = command?.token

        // 再次跳转同一目标，token 应递增（保证 onChange 触发）
        ctrl.scrollTo(target, anchor: .top, animated: false)
        #expect(ctrl.scrollCommand?.token != firstToken)
        #expect(ctrl.scrollCommand?.animated == false)
    }
}
