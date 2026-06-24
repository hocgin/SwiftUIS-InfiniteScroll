import SwiftUI

/// 自定义能力配置容器：通过 EnvironmentKey 传递，避免主 init 参数爆炸。
///
/// 设计：每个 builder 包装为 struct（含 optional AnyView 工厂），
/// 默认值为 nil → 渲染层走 fallback 默认视图。
///
/// `@unchecked Sendable`：
/// - SwiftUI 的 EnvironmentValue 事实上永远在主线程读写（与视图生命周期绑定）。
/// - 闭包本身不可 Sendable，但 EnvironmentKey 协议要求 defaultValue nonisolated。
/// - 用 @unchecked 旁路 Swift 6 严格检查；这是 SwiftUI 第三方库的惯用法。
/// - 调用方不应跨线程传递这些 builder。

// MARK: - 头部

/// 日期头 builder。`nil` 走默认 `DayHeader`。
public struct DayHeaderViewBuilder: @unchecked Sendable {
    public let builder: ((DayHeaderContext) -> AnyView)?

    public static let `default` = DayHeaderViewBuilder(builder: nil)
}

/// 空日视图 builder。`nil` 走默认空日卡片。
public struct DayEmptyViewBuilder: @unchecked Sendable {
    public let builder: (() -> AnyView)?

    public static let `default` = DayEmptyViewBuilder(builder: nil)
}

/// 折叠区间 builder。`nil` 走默认 `GapSection`。
public struct DayGapViewBuilder: @unchecked Sendable {
    public let builder: ((GapRange) -> AnyView)?

    public static let `default` = DayGapViewBuilder(builder: nil)
}

/// 加载视图 builder。`nil` 走默认 `ProgressView`。
public struct DayLoadingViewBuilder: @unchecked Sendable {
    public let builder: (() -> AnyView)?

    public static let `default` = DayLoadingViewBuilder(builder: nil)
}

// MARK: - EnvironmentKey

private struct DayHeaderKey: EnvironmentKey {
    static let defaultValue: DayHeaderViewBuilder = .default
}

private struct DayEmptyKey: EnvironmentKey {
    static let defaultValue: DayEmptyViewBuilder = .default
}

private struct DayGapKey: EnvironmentKey {
    static let defaultValue: DayGapViewBuilder = .default
}

private struct DayLoadingKey: EnvironmentKey {
    static let defaultValue: DayLoadingViewBuilder = .default
}

public extension EnvironmentValues {

    /// 自定义日期头。由 `.dayHeader { date in ... }` 写入。
    var dayHeaderView: DayHeaderViewBuilder {
        get { self[DayHeaderKey.self] }
        set { self[DayHeaderKey.self] = newValue }
    }

    /// 自定义空日视图。由 `.emptyDayView { ... }` 写入。
    var dayEmptyView: DayEmptyViewBuilder {
        get { self[DayEmptyKey.self] }
        set { self[DayEmptyKey.self] = newValue }
    }

    /// 自定义折叠区间视图。由 `.gapView { gap in ... }` 写入。
    var dayGapView: DayGapViewBuilder {
        get { self[DayGapKey.self] }
        set { self[DayGapKey.self] = newValue }
    }

    /// 自定义加载视图。由 `.loadingView { ... }` 写入。
    var dayLoadingView: DayLoadingViewBuilder {
        get { self[DayLoadingKey.self] }
        set { self[DayLoadingKey.self] = newValue }
    }
}

// MARK: - 修饰符（透出到调用方）

public extension View {

    /// 自定义日期头。
    ///
    /// 闭包接收 `DayHeaderContext`，包含日期、记录数、是否今天等。
    ///
    /// 例：
    /// ```swift
    /// .dayHeader { ctx in
    ///     HStack {
    ///         Text(ctx.date, format: .dateTime.month().day())
    ///         Spacer()
    ///         if ctx.isToday { Text("今天").bold() }
    ///     }
    /// }
    /// ```
    func dayHeader<H: View>(@ViewBuilder _ builder: @escaping (DayHeaderContext) -> H) -> some View {
        environment(\.dayHeaderView, DayHeaderViewBuilder { context in
            AnyView(builder(context))
        })
    }

    /// 自定义空日视图（仅在 `.showAll` / 单空日 case 渲染）。
    func emptyDayView<E: View>(@ViewBuilder _ builder: @escaping () -> E) -> some View {
        environment(\.dayEmptyView, DayEmptyViewBuilder {
            AnyView(builder())
        })
    }

    /// 自定义折叠区间视图（仅在 `.collapse` 策略下渲染）。
    func gapView<G: View>(@ViewBuilder _ builder: @escaping (GapRange) -> G) -> some View {
        environment(\.dayGapView, DayGapViewBuilder { gap in
            AnyView(builder(gap))
        })
    }

    /// 自定义加载视图。
    func loadingView<L: View>(@ViewBuilder _ builder: @escaping () -> L) -> some View {
        environment(\.dayLoadingView, DayLoadingViewBuilder {
            AnyView(builder())
        })
    }
}
