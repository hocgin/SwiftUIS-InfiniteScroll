import Foundation

/// 预加载策略：决定何时触发下一页加载。
///
/// - fixed: 剩余 N 个 item 时触发
/// - ratio: 滚动到列表 X% 位置时触发
public enum PreloadStrategy: Sendable, Hashable {

    /// 剩余 N 个 item 时触发。例：`.fixed(5)` → 滚到剩 5 条时加载。
    case fixed(Int)

    /// 滚动到列表 X% 位置时触发。例：`.ratio(0.8)` → 滚到 80% 时加载。
    case ratio(Double)

    /// 默认：剩余 5 项触发。
    public static let defaultStrategy: PreloadStrategy = .fixed(5)

    /// 判断当前剩余数量是否应该触发预加载。
    ///
    /// - Parameter remaining: 列表中尚未滚到的 item 数量
    /// - Parameter total: 列表 item 总数（ratio 策略需要）
    /// - Returns: 是否应触发 loadMore
    public func shouldTrigger(remaining: Int, total: Int) -> Bool {
        switch self {
        case .fixed(let threshold):
            return remaining <= max(threshold, 1)

        case .ratio(let r):
            guard total > 0 else { return false }
            let scrolled = Double(total - remaining) / Double(total)
            return scrolled >= r
        }
    }
}
