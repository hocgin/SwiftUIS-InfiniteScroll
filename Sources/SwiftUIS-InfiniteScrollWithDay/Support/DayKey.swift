import Foundation

/// 一天粒度的日期标识。
///
/// 把任意 `Date` 归一到「UTC 当天」，仅保留「年-月-日（UTC）」语义。
/// 用作 `[DayKey: [Item]]` 缓存键、ForEach 稳定 ID、双向滚动锚点。
///
/// - 设计选择：**基于 UTC，不依赖 calendar**。
///   - 同一 `Date` 永远映射到同一 `DayKey`，`referenceDate` 往返一致。
///   - 跨时区数据可共享（GitHub Activity、Apple Journal 均按 UTC 归档）。
///   - 代价：UTC+8 用户凌晨 0-8 点的「本地今天」与 UTC 不一致。
///     本地化展示由调用方在 View 层用 `DateFormatter` 处理，DayKey 只负责稳定标识。
public struct DayKey: Hashable, Comparable, Sendable, Identifiable {

    /// 自 1970-01-01 UTC 起的天数。
    ///
    /// 比 `Date` 更紧凑：相邻一天差 1，便于 `adding(days:)` 与 `days(from:)` 计算。
    public let daySinceEpoch: Int

    /// Identifiable，复用 daySinceEpoch 即可保证全局唯一。
    public var id: Int { daySinceEpoch }

    /// 用整数天数构造。对外推荐走 `DayKey(date:)`。
    public init(daySinceEpoch: Int) {
        self.daySinceEpoch = daySinceEpoch
    }

    /// 把任意时刻归一到「UTC 当天」。
    ///
    /// - Note: 用 `floor` 而非 `Int()` 截断，避免负秒数（1969 年前）截断到 0 的 bug。
    public init(date: Date) {
        self.daySinceEpoch = Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    /// 反查 Date（UTC 0 点）。
    ///
    /// 仅用于：日志、默认渲染、跨边界传输；UI 显示日期应调用方自行 format。
    public var referenceDate: Date {
        Date(timeIntervalSince1970: TimeInterval(daySinceEpoch) * 86_400)
    }

    // MARK: - Comparable

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        lhs.daySinceEpoch < rhs.daySinceEpoch
    }
}

public extension DayKey {

    /// 今天（UTC）。
    static var today: DayKey { DayKey(date: Date()) }

    /// 偏移 N 天，正数未来，负数过去。
    func adding(days: Int) -> DayKey {
        DayKey(daySinceEpoch: daySinceEpoch + days)
    }

    /// 与另一天的间隔（self - other），正数表示 self 在 other 之后。
    func days(from other: DayKey) -> Int {
        daySinceEpoch - other.daySinceEpoch
    }

    /// 是否同一天。DayKey 本身已归一，直接判等即可；保留便捷方法供调用方语义化。
    func isSameDay(as other: DayKey) -> Bool {
        self == other
    }
}
