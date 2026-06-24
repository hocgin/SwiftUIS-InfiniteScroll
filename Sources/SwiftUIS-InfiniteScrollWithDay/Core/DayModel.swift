import Foundation

/// 单日渲染模型。
///
/// Controller 维护 `[DayModel<Item>]` 数组（按 DayKey 降序：今天在前）。
/// 此模型同时承载：
/// - 渲染稳定 ID（DayKey）
/// - 显示锚点（Date，含具体时刻供 format）
/// - 加载状态（DayState）
public struct DayModel<Item: Sendable>: Sendable, Identifiable {

    /// 当天归一键。Identifiable ID。
    public let key: DayKey

    /// 当天参考日期（UTC 0 点）。
    ///
    /// 仅用于 format（"6 月 24 日"），不参与比较。
    public let day: Date

    /// 加载状态。
    public var state: DayState<Item>

    public init(key: DayKey, day: Date, state: DayState<Item>) {
        self.key = key
        self.day = day
        self.state = state
    }

    public var id: DayKey { key }
}
