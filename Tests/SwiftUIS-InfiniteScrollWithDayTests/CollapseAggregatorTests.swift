import Testing
import Foundation
@testable import SwiftUIS_InfiniteScrollWithDay

/// CollapseAggregator 三种策略的聚合行为测试。
@Suite struct CollapseAggregatorTests {

    /// 测试用 Item：Sendable + Identifiable。
    private struct Item: Sendable, Identifiable, Equatable {
        let id: Int
    }

    // MARK: - 输入构造

    private func makeModel(_ daySinceEpoch: Int, state: DayState<Item>) -> DayModel<Item> {
        DayModel(
            key: DayKey(daySinceEpoch: daySinceEpoch),
            day: DayKey(daySinceEpoch: daySinceEpoch).referenceDate,
            state: state
        )
    }

    private func loaded(_ day: Int) -> DayModel<Item> {
        makeModel(day, state: .loaded([Item(id: day)]))
    }

    private func emptyDay(_ day: Int) -> DayModel<Item> {
        makeModel(day, state: .empty)
    }

    // MARK: - 空数组

    @Test func 空数组三种策略都返回空() {
        let days: [DayModel<Item>] = []
        #expect(CollapseAggregator.aggregate(days, strategy: .showAll).isEmpty)
        #expect(CollapseAggregator.aggregate(days, strategy: .hideEmpty).isEmpty)
        #expect(CollapseAggregator.aggregate(days, strategy: .collapse).isEmpty)
    }

    // MARK: - showAll

    @Test func showAll保留所有日() {
        let days = [loaded(100), emptyDay(99), loaded(98)]
        let result = CollapseAggregator.aggregate(days, strategy: .showAll)
        #expect(result.count == 3)
        // 都是 .day
        let allDays = result.allSatisfy {
            if case .day = $0 { return true }
            return false
        }
        #expect(allDays, "showAll 应全部为 .day")
    }

    // MARK: - hideEmpty

    @Test func hideEmpty过滤空日() {
        let days = [loaded(100), emptyDay(99), emptyDay(98), loaded(97)]
        let result = CollapseAggregator.aggregate(days, strategy: .hideEmpty)
        #expect(result.count == 2)
        // 全是 loaded
        for case .day(let model) in result {
            if case .loaded = model.state { continue }
            Issue.record("hideEmpty 结果应只含 loaded")
        }
    }

    // MARK: - collapse

    @Test func collapse连续空日合并为单个gap() {
        // 100(loaded) 99-95(empty×5) 94(loaded)
        let days = [
            loaded(100), emptyDay(99), emptyDay(98), emptyDay(97),
            emptyDay(96), emptyDay(95), loaded(94)
        ]
        let result = CollapseAggregator.aggregate(days, strategy: .collapse)
        // 应为：[day, gap, day]
        #expect(result.count == 3)

        guard case .day(let first) = result[0],
              case .gap(let gap) = result[1],
              case .day(let last) = result[2] else {
            Issue.record("collapse 结果结构错误")
            return
        }
        #expect(first.key.daySinceEpoch == 100)
        // GapRange 语义：start = 最早（95），end = 最晚（99）
        #expect(gap.start.daySinceEpoch == 95)
        #expect(gap.end.daySinceEpoch == 99)
        #expect(gap.count == 5)
        #expect(last.key.daySinceEpoch == 94)
    }

    @Test func collapse单空日保留为day() {
        let days = [loaded(100), emptyDay(99), loaded(98)]
        let result = CollapseAggregator.aggregate(days, strategy: .collapse)
        // 单空日不折叠：[day, day(empty), day]
        #expect(result.count == 3)
        let allDays = result.allSatisfy {
            if case .day = $0 { return true }
            return false
        }
        #expect(allDays, "单空日应保留为 .day")
    }

    @Test func collapse不相邻空日不合为一个gap() {
        // 100(empty) 97(empty) 之间有 99 98 缺失
        let days = [emptyDay(100), emptyDay(97)]
        let result = CollapseAggregator.aggregate(days, strategy: .collapse)
        // 两段不相邻单空日，各自保留为 day
        #expect(result.count == 2)
    }

    @Test func collapse首尾都为空日() {
        let days = [emptyDay(100), emptyDay(99), loaded(98), emptyDay(97), emptyDay(96)]
        let result = CollapseAggregator.aggregate(days, strategy: .collapse)
        // [gap(100-99), day(98), gap(97-96)]
        #expect(result.count == 3)
        if case .gap(let g1) = result[0] {
            #expect(g1.count == 2)
        } else {
            Issue.record("首部 gap 缺失")
        }
        if case .gap(let g2) = result[2] {
            #expect(g2.count == 2)
        } else {
            Issue.record("尾部 gap 缺失")
        }
    }

    @Test func collapse全空日() {
        let days = (0...4).map { emptyDay(100 - $0) }
        let result = CollapseAggregator.aggregate(days, strategy: .collapse)
        // 单个 gap 覆盖 5 天
        #expect(result.count == 1)
        if case .gap(let gap) = result[0] {
            #expect(gap.count == 5)
        } else {
            Issue.record("全空日应合并为单 gap")
        }
    }
}
