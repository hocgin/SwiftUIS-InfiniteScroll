import Foundation

/// 配置：不可变快照。
public struct TimelineConfig: Sendable, Equatable {

    public let grouping: TimelineGrouping
    public let showEmptyDays: Bool
    public let preloadThreshold: Int
    public let restoreScrollPosition: Bool

    public init(
        grouping: TimelineGrouping = .day,
        showEmptyDays: Bool = false,
        preloadThreshold: Int = 5,
        restoreScrollPosition: Bool = false
    ) {
        self.grouping = grouping
        self.showEmptyDays = showEmptyDays
        // 至少 1，否则永远不预加载。
        self.preloadThreshold = max(preloadThreshold, 1)
        self.restoreScrollPosition = restoreScrollPosition
    }
}
