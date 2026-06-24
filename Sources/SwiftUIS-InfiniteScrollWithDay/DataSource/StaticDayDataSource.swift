import Foundation

/// 内存数据源：固定 `Dictionary<DayKey, [Item]>`。
///
/// 用于：
/// - 单元测试（无需 IO，同步返回）
/// - Demo 演示（生成 Mock 数据）
/// - 离线缓存场景（数据已全量载入内存）
///
/// 不存在的 DayKey 返回空数组（视为当天无数据，而非错误）。
public struct StaticDayDataSource<Item: Sendable & Identifiable>: DayDataSource {

    private let storage: [DayKey: [Item]]

    /// 从 DayKey 键控字典构造。
    public init(storage: [DayKey: [Item]]) {
        self.storage = storage
    }

    /// 从 Date 键控字典构造（自动归一为 DayKey）。
    public init(dateKeyed dates: [Date: [Item]]) {
        var mapped: [DayKey: [Item]] = [:]
        for (date, items) in dates {
            mapped[DayKey(date: date)] = items
        }
        self.storage = mapped
    }

    public func items(on day: Date) async throws -> [Item] {
        // 不 throw：未配置视为当天确实无数据。
        storage[DayKey(date: day)] ?? []
    }
}
