import Foundation

/// 空日期（当天无数据）的展示策略。
///
/// 影响 `CollapseAggregator` 如何把 `DayModel` 聚合为 `DaySectionItem`。
/// 默认 `.collapse`（PRD 推荐），最贴合「日记 / 时间线」直觉。
public enum EmptyStrategy: Sendable, Hashable {

    /// 显示所有日期，包括空日。
    ///
    /// 适合：时间记录、柳比歇夫时间管理法、日记——空日也要让用户感知「连续性」。
    case showAll

    /// 隐藏所有空日。
    ///
    /// 适合：消息流、活动流——只关心有事件的天。
    case hideEmpty

    /// 折叠连续空日（≥2 天）为单个 `GapRange` 视图。
    ///
    /// 适合：默认推荐——既不噪声也不丢连续性。
    case collapse
}
