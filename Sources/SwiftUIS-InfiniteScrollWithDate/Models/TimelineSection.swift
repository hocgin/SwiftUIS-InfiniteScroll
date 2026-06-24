import Foundation

/// 分组后的时间轴片段：一个分组（day/week/month/year）内的所有记录。
///
/// 由 `TimelineEngine` 在收到 Page 后按 `grouping` 聚合得到。
/// 渲染层把它转化为一个 Section（含 header + items）。
public struct TimelineSection<Item: Sendable>: Sendable, Identifiable {

    /// 分组键对应的代表日期（如 day 分组则是当天 0 点；week 则是周一首日）。
    public let date: Date

    /// 该分组内所有记录（按原顺序）。
    public let items: [Item]

    /// 是否为「空日分组」（showEmptyDays=true 时填充的无数据分组）。
    public let isEmptyPlaceholder: Bool

    public init(date: Date, items: [Item], isEmptyPlaceholder: Bool = false) {
        self.date = date
        self.items = items
        self.isEmptyPlaceholder = isEmptyPlaceholder
    }

    /// Identifiable：用 date.timeIntervalSince1970 作为 ID。
    ///
    /// 分组键的 date 已归一（startOfDay / firstOfMonth 等），全分组唯一。
    public var id: TimeInterval { date.timeIntervalSince1970 }
}
