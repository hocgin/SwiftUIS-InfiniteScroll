import Foundation

/// 单日数据状态。
///
/// Controller 维护 `[DayModel]`，每个 DayModel 持有此枚举描述当日加载结果。
/// UI 根据 case 切换：`.loading` 显示骨架，`.empty` 显示空日卡片，
/// `.loaded` 调用方 content 闭包，`.failed` 显示重试。
public enum DayState<Item: Sendable>: Sendable {

    /// 拉取中。
    case loading

    /// 当天确实无数据。
    case empty

    /// 当天数据就绪。
    case loaded([Item])

    /// 加载失败。
    ///
    /// 不透出 Error 类型（Error 非 Sendable），仅做语义标记；
    /// 详细错误已在 Controller 内 logger 记录。
    case failed
}

public extension DayState {

    /// 是否处于「未确定」状态（数据可能还没回来）。
    var isPending: Bool {
        switch self {
        case .loading: return true
        case .empty, .loaded, .failed: return false
        }
    }

    /// 是否为空（用于 CollapseAggregator 判定折叠）。
    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }
}
