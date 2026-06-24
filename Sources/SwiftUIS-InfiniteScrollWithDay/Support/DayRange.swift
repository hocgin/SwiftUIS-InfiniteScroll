import Foundation

/// 用户声明的日期范围描述符。
///
/// 仅用于 `InfiniteDayScrollView` 基础版的初始锚点：
/// - `.past(days:)`：从今天起向前 N 天（最常用）
/// - `.around(center:days:)`：以某天为中心向两侧扩展
/// - `.between(from:to:)`：显式指定两端
///
/// 实际数据加载仍由 Controller 按 batchSize 增量推进；DayRange 只决定首批 seed。
public struct DayRange: Sendable, Hashable {

    /// 内部表示：start/end 双 DayKey。
    ///
    /// 公共构造器统一映射到此表示，避免 enum associated value 透出到外部。
    public let start: DayKey
    public let end: DayKey

    /// 从今天起向前 N 天（默认锚点为今天）。
    ///
    /// 例：`.past(days: 365)` → start = 今天-365d, end = 今天。
    public static func past(days: Int, anchor: Date = Date()) -> DayRange {
        let today = DayKey(date: anchor)
        return DayRange(start: today.adding(days: -days), end: today)
    }

    /// 以某天为中心，向两侧各扩展 days 天。
    public static func around(center: Date, days: Int) -> DayRange {
        let centerKey = DayKey(date: center)
        return DayRange(start: centerKey.adding(days: -days), end: centerKey.adding(days: days))
    }

    /// 显式指定两端（自动排序保证 start ≤ end）。
    public static func between(from start: Date, to end: Date) -> DayRange {
        let startKey = DayKey(date: start)
        let endKey = DayKey(date: end)
        if startKey <= endKey {
            return DayRange(start: startKey, end: endKey)
        } else {
            return DayRange(start: endKey, end: startKey)
        }
    }

    /// 把区间展开为有序 DayKey 数组（降序，今天在前）。
    ///
    /// 用于基础版 init：把声明范围一次性铺成 ForEach 数据源。
    /// 注意：仅在「基础版（无 DataSource）」使用；数据驱动版由 Controller 增量产出。
    public func descendingKeys() -> [DayKey] {
        guard start <= end else { return [] }
        let count = end.days(from: start) + 1
        return (0..<count).reversed().map { offset in
            start.adding(days: offset)
        }
    }
}
