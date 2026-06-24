import Foundation
import SwiftUIS_InfiniteScroll

/// 演示用通用 Loader：每页 20 条数据，共 5 页。
struct MockFeedLoader: InfiniteLoader {
    typealias Item = MockFeedItem

    func load(nextId: String?) async throws -> Page<MockFeedItem> {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 400_000_000)

        let pageSize = 20
        let totalPages = 5
        let pageIdx: Int
        switch nextId {
        case nil: pageIdx = 0
        case "p2": pageIdx = 1
        case "p3": pageIdx = 2
        case "p4": pageIdx = 3
        case "p5": pageIdx = 4
        default: return Page(records: [], nextId: nil, hasMore: false)
        }

        var items: [MockFeedItem] = []
        for i in 0..<pageSize {
            let globalIdx = pageIdx * pageSize + i
            items.append(MockFeedItem(
                id: "item-\(globalIdx)",
                title: "Feed #\(globalIdx + 1)",
                subtitle: "Page \(pageIdx + 1) / \(totalPages)"
            ))
        }

        let nextCursor: String?
        let hasMore: Bool
        if pageIdx + 1 < totalPages {
            nextCursor = "p\(pageIdx + 2)"
            hasMore = true
        } else {
            nextCursor = nil
            hasMore = false
        }

        return Page(records: items, nextId: nextCursor, hasMore: hasMore)
    }
}

struct MockFeedItem: Sendable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
}
