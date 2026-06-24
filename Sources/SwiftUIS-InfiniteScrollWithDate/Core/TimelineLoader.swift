import Foundation

/// 分页数据源协议：基于游标的下一页加载。
///
/// 调用方实现此协议，把任意后端（API / Database / Cache）适配成统一形状。
/// Engine 通过 `loadPage(nextId:)` 驱动无限滚动。
public protocol TimelineLoader: Sendable {

    associatedtype Item: TimelineItem

    /// 加载一页数据。
    ///
    /// - Parameter nextId: 上一页返回的游标；nil 表示从头加载（首页）。
    /// - Returns: 分页结果 Page<Item>
    /// - Throws: 业务自定义错误；Engine 会捕获并切到 `.failed` 状态。
    func loadPage(nextId: String?) async throws -> Page<Item>
}

/// 类型擦除的 Loader，让 View/Engine 能持有具体 Item 而不暴露 associatedtype。
public struct AnyTimelineLoader<Item: TimelineItem>: TimelineLoader {

    private let fetch: @Sendable (String?) async throws -> Page<Item>

    public init<L: TimelineLoader>(_ loader: L) where L.Item == Item {
        self.fetch = { nextId in
            try await loader.loadPage(nextId: nextId)
        }
    }

    public init(_ fetch: @Sendable @escaping (String?) async throws -> Page<Item>) {
        self.fetch = fetch
    }

    public func loadPage(nextId: String?) async throws -> Page<Item> {
        try await fetch(nextId)
    }
}
