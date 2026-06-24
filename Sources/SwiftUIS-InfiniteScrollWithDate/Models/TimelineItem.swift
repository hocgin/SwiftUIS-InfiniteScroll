import Foundation

/// 时间轴业务模型协议。
///
/// 调用方让业务 Record 遵循此协议即可被 `InfiniteDateScrollView` 渲染。
/// 要求：
/// - `id`: 唯一标识，用于 ForEach 稳定身份。
/// - `date`: 时间归属，用于日期分组。
public protocol TimelineItem: Sendable, Identifiable {

    /// 全局唯一标识。String 适配大多数后端主键。
    var id: String { get }

    /// 该条记录的时间戳（含时分秒），用于分组到 day/week/month/year。
    var date: Date { get }
}
