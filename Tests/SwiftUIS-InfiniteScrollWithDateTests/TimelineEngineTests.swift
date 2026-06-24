import Testing
import Foundation
@testable import SwiftUIS_InfiniteScrollWithDate

@Suite struct DateTimelineGroupingTests {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    @Test func day粒度归一到当天0点() {
        let mid = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 14))!
        let key = mid.timelineGroupKey(.day, calendar: calendar)
        let day = calendar.component(.day, from: key)
        let hour = calendar.component(.hour, from: key)
        #expect(day == 24)
        #expect(hour == 0)
    }

    @Test func month粒度归一到1日() {
        let mid = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24))!
        let key = mid.timelineGroupKey(.month, calendar: calendar)
        let day = calendar.component(.day, from: key)
        let month = calendar.component(.month, from: key)
        #expect(day == 1)
        #expect(month == 6)
    }

    @Test func year粒度归一到1月1日() {
        let mid = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24))!
        let key = mid.timelineGroupKey(.year, calendar: calendar)
        let month = calendar.component(.month, from: key)
        let day = calendar.component(.day, from: key)
        #expect(month == 1)
        #expect(day == 1)
    }

    @Test func nextDay步进一天() {
        let today = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24))!
        let next = today.nextTimelineGroupStart(.day, calendar: calendar)
        let nextDay = calendar.component(.day, from: next)
        #expect(nextDay == 25)
    }
}

@Suite struct PageTests {

    @Test func hasMore未指定时由nextId推断() {
        let page1 = Page<Int>(records: [1, 2], nextId: "abc")
        #expect(page1.hasMore == true)

        let page2 = Page<Int>(records: [1, 2], nextId: nil)
        #expect(page2.hasMore == false)
    }

    @Test func hasMore显式指定优先() {
        let page = Page<Int>(records: [1], nextId: "abc", hasMore: false)
        #expect(page.hasMore == false)
    }
}

/// 测试用 Item。
private struct MockRecord: TimelineItem, Equatable {
    let id: String
    let date: Date
}

/// 测试用 Loader：按 nextId 游标返回预设 pages。
private struct MockLoader: TimelineLoader, Sendable {
    let pages: [Page<MockRecord>]

    func loadPage(nextId: String?) async throws -> Page<MockRecord> {
        if nextId == nil {
            return pages.first ?? Page(records: [], nextId: nil)
        }
        let idx = pages.firstIndex(where: { $0.nextId == nextId }).map { $0 + 1 } ?? pages.count
        return idx < pages.count ? pages[idx] : Page(records: [], nextId: nil)
    }
}

@MainActor
@Suite struct TimelineEngineTests {

    /// 构造一个简单 loader：按 nextId 游标返回预设 pages。
    private func makeLoader(_ pages: [Page<MockRecord>]) -> MockLoader {
        MockLoader(pages: pages)
    }

    private var counter = 0

    @Test func bootstrap加载首页并按day分组() async {
        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let day2 = day1.addingTimeInterval(86_400)  // +1 天
        let records = [
            MockRecord(id: "a", date: day1),
            MockRecord(id: "b", date: day1),
            MockRecord(id: "c", date: day2),
        ]
        let loader = makeLoader([
            Page(records: records, nextId: nil, hasMore: false)
        ])

        let engine = TimelineEngine<MockRecord>(loader: loader, config: .init(grouping: .day))
        engine.bootstrap()

        await waitForState(engine)

        #expect(engine.state == .loaded)
        #expect(engine.sections.count == 2)
        #expect(engine.sections[0].items.count == 1)
        #expect(engine.sections[1].items.count == 2)
    }

    @Test func showEmptyDays填充空日() async {
        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let day3 = day1.addingTimeInterval(2 * 86_400)
        let records = [
            MockRecord(id: "a", date: day1),
            MockRecord(id: "c", date: day3),
        ]
        let loader = makeLoader([
            Page(records: records, nextId: nil, hasMore: false)
        ])

        let engine = TimelineEngine<MockRecord>(
            loader: loader,
            config: .init(grouping: .day, showEmptyDays: true)
        )
        engine.bootstrap()
        await waitForState(engine)

        #expect(engine.sections.count == 3)
        #expect(engine.sections[1].isEmptyPlaceholder)
        #expect(engine.sections[1].items.isEmpty)
    }

    @Test func loadNextPage追加数据() async {
        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let day2 = day1.addingTimeInterval(-86_400)

        let loader = makeLoader([
            Page(records: [MockRecord(id: "a", date: day1)], nextId: "cursor1", hasMore: true),
            Page(records: [MockRecord(id: "b", date: day2)], nextId: nil, hasMore: false),
        ])

        let engine = TimelineEngine<MockRecord>(loader: loader)
        engine.bootstrap()
        await waitForState(engine)
        #expect(engine.sections.count == 1)

        engine.loadNextPage()
        await waitForState(engine)

        #expect(engine.sections.count == 2)
        #expect(engine.hasMore == false)
    }

    @Test func 加载失败切到failed状态() async {
        struct TestError: Error {}
        let loader = AnyTimelineLoader<MockRecord> { _ in
            throw TestError()
        }

        let engine = TimelineEngine<MockRecord>(loader: loader)
        engine.bootstrap()
        await waitForState(engine)

        #expect(engine.state == .failed)
        #expect(engine.lastError != nil)
    }

    @Test func reload清空状态() async {
        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let loader = makeLoader([
            Page(records: [MockRecord(id: "a", date: day1)], nextId: nil, hasMore: false)
        ])
        let engine = TimelineEngine<MockRecord>(loader: loader)
        engine.bootstrap()
        await waitForState(engine)
        #expect(engine.sections.count == 1)

        engine.reload()
        await waitForState(engine)
        #expect(engine.state != .idle)
    }

    /// 等待 engine 离开 loading 状态（最多 ~1 秒）。
    private func waitForState(_ engine: TimelineEngine<MockRecord>) async {
        for _ in 0..<20 {
            if engine.state != .loading { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
