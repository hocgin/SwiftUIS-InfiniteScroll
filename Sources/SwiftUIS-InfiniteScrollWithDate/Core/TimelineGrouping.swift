import Foundation

/// 分组粒度。
///
/// 决定 `TimelineEngine` 如何把 records 聚合为 sections。
public enum TimelineGrouping: Sendable, Hashable {

    /// 按日（默认）。同一天（按 calendar.startOfDay）的记录归为一组。
    case day

    /// 按周（按 calendar 的 firstWeekday 设置）。
    case week

    /// 按月。
    case month

    /// 按年。
    case year
}
