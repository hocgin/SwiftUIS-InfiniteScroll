import Foundation

/// 类型擦除的 DayDataSource 包装。
///
/// Controller / View 持有 DataSource 时不能保留 associatedtype，
/// 必须先擦除到 `AnyDayDataSource<Item>`，否则泛型会泄漏到 View 签名。
///
/// 设计：用闭包捕获原始 DataSource，对外仅暴露具体 Item。
public struct AnyDayDataSource<Item: Sendable & Identifiable>: DayDataSource {

    private let fetch: @Sendable (Date) async throws -> [Item]

    /// 从任意 DayDataSource 擦除。
    public init<D: DayDataSource>(_ source: D) where D.Item == Item {
        // 闭包捕获 source，调用时转发；source 已是 Sendable，闭包标 @Sendable 安全。
        self.fetch = { day in
            try await source.items(on: day)
        }
    }

    /// 直接用闭包构造（测试 / Demo 场景）。
    public init(_ fetch: @Sendable @escaping (Date) async throws -> [Item]) {
        self.fetch = fetch
    }

    public func items(on day: Date) async throws -> [Item] {
        try await fetch(day)
    }
}
