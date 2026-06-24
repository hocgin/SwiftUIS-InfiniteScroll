import Foundation

/// 加载状态机。
///
/// - idle: 未开始
/// - loading: 加载中（首次或下一页）
/// - loaded: 已加载，有数据
/// - empty: 已加载，但无任何记录
/// - failed: 加载失败（网络错误等）
public enum TimelineState: Sendable, Equatable {

    case idle
    case loading
    case loaded
    case empty
    case failed
}

public extension TimelineState {

    /// 是否处于终态（非加载中）。
    var isTerminal: Bool {
        switch self {
        case .idle, .loading: return false
        case .loaded, .empty, .failed: return true
        }
    }
}
