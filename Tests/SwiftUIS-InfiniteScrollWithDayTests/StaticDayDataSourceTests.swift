import Testing
import Foundation
@testable import SwiftUIS_InfiniteScrollWithDay

/// StaticDayDataSource 行为测试。
@Suite struct StaticDayDataSourceTests {

    private struct Item: Sendable, Identifiable, Equatable {
        let id: Int
    }

    @Test func 命中DayKey返回数据() async throws {
        let key = DayKey(date: Date())
        let items = [Item(id: 1), Item(id: 2)]
        let source = StaticDayDataSource<Item>(storage: [key: items])

        let result = try await source.items(on: Date())
        #expect(result == items)
    }

    @Test func 未命中返回空数组而非抛错() async throws {
        let source = StaticDayDataSource<Item>(storage: [:])
        let result = try await source.items(on: Date())
        #expect(result.isEmpty)
    }

    @Test func dateKeyed构造自动归一() async throws {
        // 用 DayKey 反推 UTC 0 点避免跨天。
        let dayStart = DayKey(daySinceEpoch: 20_000).referenceDate
        let morning = dayStart.addingTimeInterval(8 * 3_600)
        let evening = dayStart.addingTimeInterval(23 * 3_600)

        let source = StaticDayDataSource<Item>(
            dateKeyed: [morning: [Item(id: 99)]]
        )

        let result = try await source.items(on: evening)
        #expect(result.count == 1)
        #expect(result.first?.id == 99)
    }

    @Test func anyDayDataSource类型擦除后行为一致() async throws {
        let key = DayKey(date: Date())
        let original = StaticDayDataSource<Item>(storage: [key: [Item(id: 7)]])
        let erased = AnyDayDataSource(original)

        let result = try await erased.items(on: Date())
        #expect(result.first?.id == 7)
    }
}
