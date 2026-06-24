import Foundation
import SwiftUIS_InfiniteScrollWithDate

/// 演示用 Loader：生成 30 天数据，分 3 页返回。
///
/// 数据布局：每页 10 天 × 每天 2 条记录。
/// 第 1 页（nextId="cursor2"）：今天 ~ 今天-9 天
/// 第 2 页（nextId="cursor3"）：今天-10 ~ 今天-19 天
/// 第 3 页（nextId=nil）：今天-20 ~ 今天-29 天
struct MockTimelineLoader: TimelineLoader {
    typealias Item = MockTimelineRecord

    func loadPage(nextId: String?) async throws -> Page<MockTimelineRecord> {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 300_000_000)

        let today = Date()
        let pageSize = 10
        let pageOffset: Int
        switch nextId {
        case nil: pageOffset = 0
        case "cursor2": pageOffset = 1
        case "cursor3": pageOffset = 2
        default: return Page(records: [], nextId: nil, hasMore: false)
        }

        var records: [MockTimelineRecord] = []
        for dayOffset in 0..<pageSize {
            let globalDay = pageOffset * pageSize + dayOffset
            let date = today.addingTimeInterval(TimeInterval(-globalDay * 86_400))
            records.append(MockTimelineRecord(
                id: "page\(pageOffset)-day\(globalDay)-a",
                date: date,
                title: "记录 #\(globalDay) A"
            ))
            records.append(MockTimelineRecord(
                id: "page\(pageOffset)-day\(globalDay)-b",
                date: date,
                title: "记录 #\(globalDay) B"
            ))
        }

        let nextCursor: String?
        let hasMore: Bool
        switch pageOffset {
        case 0: nextCursor = "cursor2"; hasMore = true
        case 1: nextCursor = "cursor3"; hasMore = true
        default: nextCursor = nil; hasMore = false
        }

        return Page(records: records, nextId: nextCursor, hasMore: hasMore)
    }
}

struct MockTimelineRecord: TimelineItem, Identifiable {
    let id: String
    let date: Date
    let title: String
}
