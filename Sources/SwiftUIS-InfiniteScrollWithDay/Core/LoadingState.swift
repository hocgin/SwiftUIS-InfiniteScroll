import Foundation

/// 批次加载状态（用于 Controller 的 forward/backward 两个方向）。
///
/// 与 `DayState` 区别：`LoadingState` 描述「下一批是否在拉取」，
/// `DayState` 描述「某一天的数据是否就绪」。
public enum LoadingState: Sendable, Equatable {

    /// 空闲，可发起下一批。
    case idle

    /// 加载中，禁止重入。
    case loading

    /// 加载完成（无更多数据时也停留此态，配合 hasMore 判定）。
    case loaded

    /// 加载失败，允许用户重试。
    ///
    /// 不直接持有 Error：Error 可能不是 Sendable，且 UI 通常只需展示「加载失败，点击重试」。
    case failed
}

public extension LoadingState {

    /// 是否处于终态可重置。
    var isTerminal: Bool {
        switch self {
        case .idle, .loading: return false
        case .loaded, .failed: return true
        }
    }
}
