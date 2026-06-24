import SwiftUI

/// 自定义能力容器：用 EnvironmentKey 传递 builder。
///
/// 每个包装为 struct + optional AnyView 工厂，默认 nil → 走默认视图。
/// `@unchecked Sendable`：EnvironmentValue 事实上在主线程读写，闭包不真正跨线程。

public struct EmptyBuilder: @unchecked Sendable {
    public let builder: (() -> AnyView)?
    public static let `default` = EmptyBuilder(builder: nil)
}

public struct LoadingBuilder: @unchecked Sendable {
    public let builder: (() -> AnyView)?
    public static let `default` = LoadingBuilder(builder: nil)
}

public struct ErrorViewBuilder: @unchecked Sendable {
    public let builder: ((any Error, @escaping () -> Void) -> AnyView)?
    public static let `default` = ErrorViewBuilder(builder: nil)
}

public struct FooterBuilder: @unchecked Sendable {
    public let builder: ((InfiniteFooterState, @escaping () -> Void) -> AnyView)?
    public static let `default` = FooterBuilder(builder: nil)
}

// MARK: - EnvironmentKey

private struct EmptyKey: EnvironmentKey {
    static let defaultValue = EmptyBuilder.default
}

private struct LoadingKey: EnvironmentKey {
    static let defaultValue = LoadingBuilder.default
}

private struct ErrorKey: EnvironmentKey {
    static let defaultValue = ErrorViewBuilder.default
}

private struct FooterKey: EnvironmentKey {
    static let defaultValue = FooterBuilder.default
}

public extension EnvironmentValues {
    var emptyBuilder: EmptyBuilder {
        get { self[EmptyKey.self] }
        set { self[EmptyKey.self] = newValue }
    }
    var loadingBuilder: LoadingBuilder {
        get { self[LoadingKey.self] }
        set { self[LoadingKey.self] = newValue }
    }
    var errorViewBuilder: ErrorViewBuilder {
        get { self[ErrorKey.self] }
        set { self[ErrorKey.self] = newValue }
    }
    var footerBuilder: FooterBuilder {
        get { self[FooterKey.self] }
        set { self[FooterKey.self] = newValue }
    }
}

// MARK: - 说明
//
// 自定义 modifier 已移动到 `InfiniteScrollView` 的 extension（见 InfiniteScrollView.swift），
// 采用「值类型副本」模式（参考 ScalingHeaderScrollView）：modifier 返回同类型副本，
// 保持链式调用类型一致。
//
// 不再使用 `extension View`，避免跨模块同名 modifier（emptyView / loadingView 等）歧义。
