import Foundation
import SwiftUIS_InfiniteScrollWithDay

/// 演示用压力数据源：按需生成记录，不预存内存。
///
/// 用 daySinceEpoch 做伪随机种子决定当天是否有数据及数量。
/// 默认配置：10000 天范围内、平均 10 条/天 → 总记录约 100k。
struct MockTimeline: DayDataSource {

    /// 单条记录：极简字段，保证内存占用低。
    struct Record: Sendable, Identifiable {
        let id: Int  // daySinceEpoch * 1000 + index
        let title: String
        let detail: String
    }

    /// 平均每天记录数。每 3 天中有 1 天有数据。
    let recordsPerDay: Int

    init(recordsPerDay: Int = 10) {
        self.recordsPerDay = recordsPerDay
    }

    func items(on day: Date) async throws -> [Record] {
        let key = DayKey(date: day)
        // 用 daySinceEpoch 取模决定有无数据：每 3 天中 1 天有。
        if key.daySinceEpoch % 3 != 0 {
            return []
        }
        // 实际数量 = recordsPerDay ± 2，用 daySinceEpoch 做抖动。
        let jitter = key.daySinceEpoch % 5 - 2  // -2...2
        let count = max(0, recordsPerDay + jitter)
        return (0..<count).map { index in
            Record(
                id: key.daySinceEpoch * 1000 + index,
                title: "记录 #\(index + 1) @ day \(key.daySinceEpoch)",
                detail: "Day offset: \(key.days(from: DayKey.today))"
            )
        }
    }
}
