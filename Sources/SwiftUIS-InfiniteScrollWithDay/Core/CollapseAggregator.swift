import Foundation

/// 把 `[DayModel]` 按 `EmptyStrategy` 聚合为 `[DaySectionItem]` 的纯函数模块。
///
/// 抽离成独立 struct 是为了：
/// 1. 纯函数无副作用，可单元测试，无需 mock DataSource
/// 2. Controller 在 `days` 变更时调用，UI 直接消费结果
/// 3. 三种策略集中在一个文件，未来扩展（如 .compact 折叠到一定阈值）只改这里
public enum CollapseAggregator {

    /// 主入口：按策略聚合。
    ///
    /// - 重要：输入 `days` 必须按 DayKey 降序排列（今天在前）。
    ///   Controller 已保证；如不保证，结果行为未定义。
    public static func aggregate<Item: Sendable>(
        _ days: [DayModel<Item>],
        strategy: EmptyStrategy
    ) -> [DaySectionItem<Item>] {
        switch strategy {
        case .showAll:
            return days.map { .day($0) }
        case .hideEmpty:
            return days.filter { !$0.state.isEmpty }.map { .day($0) }
        case .collapse:
            return collapse(days: days)
        }
    }

    /// Collapse 策略核心算法。
    ///
    /// 规则：
    /// - 连续 ≥ 2 个 empty 且 DayKey 真相邻（差 1 天）→ 合并为单个 `.gap`
    /// - 单个 empty → 保留为 `.day`（与 showAll 等价，避免「就 1 天空也显示折叠卡片」）
    /// - 非 empty（loaded/failed/loading）→ 保留为 `.day`，且打断当前折叠累积
    private static func collapse<Item: Sendable>(
        days: [DayModel<Item>]
    ) -> [DaySectionItem<Item>] {

        var output: [DaySectionItem<Item>] = []
        // 当前正在累积的连续空日区间（start/end 是闭区间两端）。
        var gapStart: DayKey?
        var gapEnd: DayKey?

        func flushGap() {
            guard let rawStart = gapStart, let rawEnd = gapEnd else { return }
            // 归一：start 永远是较早（更小 key），end 永远是较晚（更大 key）。
            // 遍历降序时 rawStart/rawEnd 顺序不固定，需 min/max 处理。
            let start = min(rawStart, rawEnd)
            let end = max(rawStart, rawEnd)
            // 只在 ≥ 2 天时合成 gap；单个空日保留为普通日。
            if end.days(from: start) >= 1 {
                output.append(.gap(GapRange(start: start, end: end)))
            } else {
                // 单天空：直接当 day 渲染，让调用方的 emptyView 处理。
                let singleModel = DayModel<Item>(
                    key: start,
                    day: start.referenceDate,
                    state: .empty
                )
                output.append(.day(singleModel))
            }
            gapStart = nil
            gapEnd = nil
        }

        for model in days {
            if model.state.isEmpty {
                if let existingEnd = gapEnd {
                    // 检查与上一个累积是否真相邻（DayKey 差 1）。
                    // 由于 days 已按 DayKey 降序，model.key < existingEnd。
                    if existingEnd.days(from: model.key) == 1 {
                        gapEnd = model.key
                    } else {
                        // 不相邻：先 flush 旧 gap，再开新 gap。
                        flushGap()
                        gapStart = model.key
                        gapEnd = model.key
                    }
                } else {
                    gapStart = model.key
                    gapEnd = model.key
                }
            } else {
                // 非 empty：先 flush 累积 gap，再追加 day。
                flushGap()
                output.append(.day(model))
            }
        }
        flushGap()
        return output
    }
}
