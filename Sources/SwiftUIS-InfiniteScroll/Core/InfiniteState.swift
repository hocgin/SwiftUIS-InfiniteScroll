import Foundation

/// 列表整体加载状态。
public enum InfiniteState: Sendable, Equatable {

    /// 未开始。
    case idle

    /// 首次加载中（无任何数据）。
    case loading

    /// 已加载（有数据）。
    case loaded

    /// 已加载但无数据（首页空）。
    case empty

    /// 首次加载失败。
    case failed
}

/// 底部分页加载状态（与 InfiniteState 区分：这是「下一页」的状态）。
public enum InfiniteFooterState: Sendable, Equatable {

    /// 无（已无更多数据或未触发）。
    case none

    /// 加载中。
    case loading

    /// 加载失败（可重试，不丢失已加载数据）。
    case failed

    /// 没有更多数据。
    case noMore
}
