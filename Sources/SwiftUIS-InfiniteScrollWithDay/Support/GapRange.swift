import Foundation

/// 连续空日折叠后的区间。
///
/// 当 `EmptyStrategy == .collapse` 且连续 ≥ 2 个空日时，由 `CollapseAggregator`
/// 合成单个 `GapRange`，渲染为单张「7 天空档 / 6.16-6.22」卡片，避免列表噪声。
///
/// `Hashable` / `Equatable` 由 start+end 自动合成，可作 ForEach 稳定 ID。
public struct GapRange: Hashable, Sendable, Identifiable {

    /// 区间起始（含），即最早的空日。
    public let start: DayKey

    /// 区间结束（含），即最晚的空日。
    public let end: DayKey

    public init(start: DayKey, end: DayKey) {
        self.start = start
        self.end = end
    }

    /// Identifiable：用 start.daySinceEpoch 做唯一键。
    ///
    /// 由于折叠区间在 days 数组里位置稳定（按时间顺序），start 即可保证全局唯一。
    public var id: Int { start.daySinceEpoch }

    /// 区间内总天数（含首尾）。
    ///
    /// 例：6.16-6.22 共 7 天，count = 7。
    public var count: Int {
        end.days(from: start) + 1
    }
}
