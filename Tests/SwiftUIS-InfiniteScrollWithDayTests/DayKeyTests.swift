import Testing
import Foundation
@testable import SwiftUIS_InfiniteScrollWithDay

/// DayKey 日期标准化与算术测试。
///
/// 覆盖：归一性、Comparable、加减、跨天边界、月份对齐。
@Suite struct DayKeyTests {

    // MARK: - 标准化

    @Test func 同一日的不同时刻归一为相同DayKey() {
        // 用 DayKey 反推 UTC 0 点，避免硬编码秒数导致跨天。
        let dayStart = DayKey(daySinceEpoch: 20_000).referenceDate
        let morning = dayStart.addingTimeInterval(6 * 3_600)
        let evening = dayStart.addingTimeInterval(23 * 3_600)

        let morningKey = DayKey(date: morning)
        let eveningKey = DayKey(date: evening)

        #expect(morningKey == eveningKey, "UTC 同一天的不同时刻应归一到同一 DayKey")
        #expect(morningKey.daySinceEpoch == 20_000)
    }

    @Test func 跨天相邻时刻归一为不同DayKey() {
        let dayStart = DayKey(daySinceEpoch: 20_000).referenceDate
        let dayBeforeMidnight = dayStart.addingTimeInterval(23 * 3_600 + 59 * 60)
        let dayAfterMidnight = dayStart.addingTimeInterval(24 * 3_600)

        let beforeKey = DayKey(date: dayBeforeMidnight)
        let afterKey = DayKey(date: dayAfterMidnight)

        #expect(beforeKey != afterKey)
        #expect(beforeKey < afterKey)
    }

    // MARK: - Comparable

    @Test func 比较运算遵循时间顺序() {
        let earlier = DayKey(daySinceEpoch: 20_000)
        let later = DayKey(daySinceEpoch: 20_010)

        #expect(earlier < later)
        #expect(later > earlier)
        #expect(earlier != later)
        #expect(earlier == DayKey(daySinceEpoch: 20_000))
    }

    // MARK: - 算术

    @Test func addingDays正负方向都正确() {
        let today = DayKey(daySinceEpoch: 20_000)
        #expect(today.adding(days: 5).daySinceEpoch == 20_005)
        #expect(today.adding(days: -5).daySinceEpoch == 19_995)
        #expect(today.adding(days: 0) == today)
    }

    @Test func daysFrom计算两天间隔() {
        let start = DayKey(daySinceEpoch: 20_000)
        let end = DayKey(daySinceEpoch: 20_010)

        #expect(end.days(from: start) == 10)
        #expect(start.days(from: end) == -10)
        #expect(start.days(from: start) == 0)
    }

    // MARK: - Identifiable

    @Test func id与daySinceEpoch一致保证唯一() {
        let key = DayKey(daySinceEpoch: 20_123)
        #expect(key.id == 20_123)
    }

    // MARK: - referenceDate 往返

    @Test func referenceDate往返一致() {
        let key = DayKey(daySinceEpoch: 20_000)
        let date = key.referenceDate
        let back = DayKey(date: date)
        #expect(back == key)
    }
}

/// Calendar+DayOps 月份算术测试。
@Suite struct CalendarDayOpsTests {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    @Test func firstDayOfMonth取月首() {
        let mid = calendar.date(from: DateComponents(year: 2026, month: 6, day: 24))!
        let first = calendar.firstDayOfMonth(for: mid)
        let firstDate = first.referenceDate
        let firstDay = calendar.component(.day, from: firstDate)
        #expect(firstDay == 1)
    }

    @Test func lastDayOfMonth取月末() {
        let mid = calendar.date(from: DateComponents(year: 2026, month: 2, day: 10))!
        let last = calendar.lastDayOfMonth(for: mid)
        let lastDate = last.referenceDate
        let lastDay = calendar.component(.day, from: lastDate)
        // 2026 年 2 月 28 天（非闰年）
        #expect(lastDay == 28)
    }

    @Test func dayCount统计跨度() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 6, day: 22))!
        #expect(calendar.dayCount(from: start, to: end) == 6)
    }
}

/// DayRange 描述符与展开测试。
@Suite struct DayRangeTests {

    @Test func pastDays生成正确的降序序列() {
        let anchor = Date(timeIntervalSince1970: 0)
        let range = DayRange.past(days: 7, anchor: anchor)
        let keys = range.descendingKeys()

        #expect(keys.count == 8)  // 含端点：今天 - 7d ... 今天
        #expect(keys.first == range.end)
        #expect(keys.last == range.start)
        #expect(keys.first!.days(from: keys.last!) == 7)
    }

    @Test func between自动排序保证start不晚于end() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = Date(timeIntervalSince1970: 1_500_000)
        let range = DayRange.between(from: end, to: start)  // 反向传

        #expect(range.start <= range.end)
    }

    @Test func around向两侧对称扩展() {
        let center = Date(timeIntervalSince1970: 0)
        let range = DayRange.around(center: center, days: 3)

        #expect(range.end.days(from: range.start) == 6)
        #expect(range.start.adding(days: 3) == DayKey(date: center))
    }
}

/// GapRange 折叠区间测试。
@Suite struct GapRangeTests {

    @Test func count包含首尾() {
        let start = DayKey(daySinceEpoch: 20_000)
        let end = DayKey(daySinceEpoch: 20_006)
        let gap = GapRange(start: start, end: end)

        #expect(gap.count == 7)
        #expect(gap.id == 20_000)
    }

    @Test func 单天gap计数为1() {
        let key = DayKey(daySinceEpoch: 20_000)
        let gap = GapRange(start: key, end: key)
        #expect(gap.count == 1)
    }
}
