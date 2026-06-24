import Foundation

/// 分页结果。
///
/// 对应后端响应结构：
/// ```json
/// { "records": [], "nextId": "123", "hasMore": true }
/// ```
///
/// - records: 本页数据
/// - nextId: 下一页游标（传给 loadPage(nextId:)）；nil 表示无更多
/// - hasMore: 是否还有下一页（与 nextId == nil 等价，但显式更清晰）
public struct Page<Item: Sendable>: Sendable {

    public let records: [Item]
    public let nextId: String?
    public let hasMore: Bool

    public init(records: [Item], nextId: String?, hasMore: Bool? = nil) {
        self.records = records
        self.nextId = nextId
        // hasMore 未显式给定时，由 nextId 是否为空推断。
        self.hasMore = hasMore ?? (nextId != nil)
    }
}
