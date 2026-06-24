import Foundation

/// 按日提供数据的源协议。
///
/// 业务方（如 Database、API、UserDefaults）实现此协议，
/// 把任意异步数据源适配成「给定一天 → 返回当天记录列表」的统一形状。
/// `InfiniteDayScrollView` 通过此协议与业务解耦。
///
/// - 要求 `Item: Sendable & Identifiable`：
///   - `Sendable` 满足 Swift 6 跨 actor 传递（DataSource 通常在非主 actor 上工作）
///   - `Identifiable` 让 LazyVStack ForEach 拥有稳定 ID
public protocol DayDataSource: Sendable {

    /// 数据条目类型。必须可跨 actor 传递且 ForEach 可识别。
    associatedtype Item: Sendable & Identifiable

    /// 取指定天的数据。
    ///
    /// - Parameter day: 当天任意时刻；实现内部应自行 `startOfDay` 归一。
    /// - Returns: 当天数据列表；空数组代表当天确实无数据。
    /// - Throws: 业务自定义错误；Controller 会捕获并切到 `.failed` 状态。
    func items(on day: Date) async throws -> [Item]
}
