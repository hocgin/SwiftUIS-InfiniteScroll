import Foundation

/// 日期分组辅助：把任意 Date 归一到分组键。
public extension Date {

    /// 按指定粒度返回分组键（归一到分组首日 0 点）。
    ///
    /// - day: 当天 0 点
    /// - week: 本周首日 0 点（按 calendar.firstWeekday）
    /// - month: 本月 1 日 0 点
    /// - year: 本年 1 月 1 日 0 点
    func timelineGroupKey(
        _ grouping: TimelineGrouping,
        calendar: Calendar = .current
    ) -> Date {
        switch grouping {
        case .day:
            return calendar.startOfDay(for: self)

        case .week:
            // yearForWeekOfYear + weekOfYear 唯一确定一周。
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
            return calendar.date(from: components) ?? calendar.startOfDay(for: self)

        case .month:
            let components = calendar.dateComponents([.year, .month], from: self)
            return calendar.date(from: components) ?? calendar.startOfDay(for: self)

        case .year:
            let components = calendar.dateComponents([.year], from: self)
            return calendar.date(from: components) ?? calendar.startOfDay(for: self)
        }
    }

    /// 计算同粒度下的「下一个」分组首日（往未来方向）。
    ///
    /// 例：day 粒度下，6 月 24 日 → 6 月 25 日。
    func nextTimelineGroupStart(
        _ grouping: TimelineGrouping,
        calendar: Calendar = .current
    ) -> Date {
        let component: Calendar.Component
        switch grouping {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        return calendar.date(byAdding: component, value: 1, to: self) ?? self
    }

    /// 计算同粒度下的「上一个」分组首日（往过去方向）。
    ///
    /// 用于降序 sections 的空日填充：从当前组往过去方向步进直到遇到下一个真实 section。
    func prevTimelineGroupStart(
        _ grouping: TimelineGrouping,
        calendar: Calendar = .current
    ) -> Date {
        let component: Calendar.Component
        switch grouping {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        return calendar.date(byAdding: component, value: -1, to: self) ?? self
    }
}
