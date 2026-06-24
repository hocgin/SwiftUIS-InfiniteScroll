import Foundation

/// 通用分页加载协议：基于游标的下一页加载。
///
/// 不依赖任何业务模型（无 Date / Timeline 概念）。
/// 业务方实现此协议把任意后端适配成统一形状。
public protocol InfiniteLoader: Sendable {

    associatedtype Item: Sendable & Identifiable

    /// 加载一页数据。
    ///
    /// - Parameter nextId: 上一页返回的游标；nil 表示首页。
    func load(nextId: String?) async throws -> Page<Item>
}

/// 类型擦除 Loader，让 Store/View 持有具体 Item 而不暴露 associatedtype。
public struct AnyInfiniteLoader<Item: Sendable & Identifiable>: InfiniteLoader {

    private let fetch: @Sendable (String?) async throws -> Page<Item>

    public init<L: InfiniteLoader>(_ loader: L) where L.Item == Item {
        self.fetch = { nextId in try await loader.load(nextId: nextId) }
    }

    public init(_ fetch: @Sendable @escaping (String?) async throws -> Page<Item>) {
        self.fetch = fetch
    }

    public func load(nextId: String?) async throws -> Page<Item> {
        try await fetch(nextId)
    }
}
