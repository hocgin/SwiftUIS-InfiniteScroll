import Foundation

/// 月份粒度的算术与查询，配合 `DayKey` 使用。
///
/// 抽离出独立扩展是为了让 Controller / Proxy 在做月份跳转时不必每次重建 Calendar，
/// 也避免在协议签名里泄漏 Calendar 依赖。
public extension Calendar {

    /// 取「当月第 1 天」的 DayKey。
    ///
    /// 用于 scrollToMonth 等 API：定位到某月即跳转到该月首日。
    func firstDayOfMonth(for date: Date) -> DayKey {
        let components = dateComponents([.year, .month], from: date)
        guard let firstOfMonth = self.date(from: components) else {
            return DayKey(date: date)
        }
        return DayKey(date: firstOfMonth)
    }

    /// 取「当月最后 1 天」的 DayKey。
    func lastDayOfMonth(for date: Date) -> DayKey {
        guard let interval = range(of: .day, in: .month, for: date) else {
            return DayKey(date: date)
        }
        var components = dateComponents([.year, .month], from: date)
        components.day = interval.count
        guard let lastDay = self.date(from: components) else {
            return DayKey(date: date)
        }
        return DayKey(date: lastDay)
    }

    /// 计算两日期间相隔天数（含起止），向下取整。
    ///
    /// 用于 GapRange 渲染时显示「N 天空档」。
    func dayCount(from start: Date, to end: Date) -> Int {
        let startDay = startOfDay(for: start)
        let endDay = startOfDay(for: end)
        let seconds = endDay.timeIntervalSince(startDay)
        return Int(seconds / 86_400)
    }
}
