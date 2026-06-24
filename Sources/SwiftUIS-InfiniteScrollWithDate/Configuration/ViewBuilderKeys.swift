import SwiftUI

/// 自定义能力容器：用 EnvironmentKey 传递 builder，避免主 init 参数爆炸。
///
/// 每个包装为 struct + optional AnyView 工厂，默认 nil → 走默认视图。

public struct DateHeaderBuilder: @unchecked Sendable {
    public let builder: ((Date, TimelineGrouping) -> AnyView)?
    public static let `default` = DateHeaderBuilder(builder: nil)
}

public struct LoadingViewBuilder: @unchecked Sendable {
    public let builder: (() -> AnyView)?
    public static let `default` = LoadingViewBuilder(builder: nil)
}

public struct ErrorViewBuilder: @unchecked Sendable {
    public let builder: (((any Error), @escaping () -> Void) -> AnyView)?
    public static let `default` = ErrorViewBuilder(builder: nil)
}

public struct EmptyViewBuilder: @unchecked Sendable {
    public let builder: (() -> AnyView)?
    public static let `default` = EmptyViewBuilder(builder: nil)
}

// MARK: - EnvironmentKey

private struct DateHeaderKey: EnvironmentKey {
    static let defaultValue = DateHeaderBuilder.default
}

private struct LoadingKey: EnvironmentKey {
    static let defaultValue = LoadingViewBuilder.default
}

private struct ErrorKey: EnvironmentKey {
    static let defaultValue = ErrorViewBuilder.default
}

private struct EmptyKey: EnvironmentKey {
    static let defaultValue = EmptyViewBuilder.default
}

public extension EnvironmentValues {
    var dateHeaderBuilder: DateHeaderBuilder {
        get { self[DateHeaderKey.self] }
        set { self[DateHeaderKey.self] = newValue }
    }
    var loadingBuilder: LoadingViewBuilder {
        get { self[LoadingKey.self] }
        set { self[LoadingKey.self] = newValue }
    }
    var errorBuilder: ErrorViewBuilder {
        get { self[ErrorKey.self] }
        set { self[ErrorKey.self] = newValue }
    }
    var emptyBuilder: EmptyViewBuilder {
        get { self[EmptyKey.self] }
        set { self[EmptyKey.self] = newValue }
    }
}

// MARK: - 说明
//
// 自定义 modifier 已移动到 `InfiniteDateScrollView` 的 extension（见 InfiniteDateScrollView.swift），
// 采用「值类型副本」模式：modifier 返回同类型副本，保持链式调用类型一致。
//
// 不再使用 `extension View`，避免跨模块同名 modifier 歧义。

