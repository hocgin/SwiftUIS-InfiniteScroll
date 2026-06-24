import Foundation

/// 分页结果（与业务模型无关）。
///
/// 对应后端通用响应：
/// ```json
/// { "records": [], "nextId": "123", "hasMore": true }
/// ```
public struct Page<Item: Sendable>: Sendable {

    public let records: [Item]
    public let nextId: String?
    public let hasMore: Bool

    public init(records: [Item], nextId: String?, hasMore: Bool? = nil) {
        self.records = records
        self.nextId = nextId
        self.hasMore = hasMore ?? (nextId != nil)
    }
}
