import Foundation

/// 自定义日期头的上下文。
///
/// 传递给 `.dayHeader { context in ... }` 的闭包，提供当天信息，
/// 让调用方能根据「是否今天 / 记录数 / 是否空日」做条件化定制。
///
/// 例：
/// ```swift
/// .dayHeader { ctx in
///     HStack {
///         Text(ctx.date, format: .dateTime.month().day())
///         Spacer()
///         if ctx.isToday {
///             Text("今天").badge(ctx.itemCount)
///         } else if ctx.itemCount > 0 {
///             Text("\(ctx.itemCount) 条")
///         }
///     }
/// }
/// ```
public struct DayHeaderContext: Sendable, Equatable {

    /// 当天任意时刻的 Date（用于 format）。
    public let date: Date

    /// 当天的 DayKey（用于比较、算术）。
    public let key: DayKey

    /// 当天记录数。0 表示当天无数据或仍在加载。
    public let itemCount: Int

    /// 是否为今天（UTC）。
    public let isToday: Bool

    /// 是否为空日（itemCount == 0 且加载已完成）。
    public let isEmpty: Bool

    public init(date: Date, key: DayKey, itemCount: Int, isToday: Bool, isEmpty: Bool) {
        self.date = date
        self.key = key
        self.itemCount = itemCount
        self.isToday = isToday
        self.isEmpty = isEmpty
    }
}
