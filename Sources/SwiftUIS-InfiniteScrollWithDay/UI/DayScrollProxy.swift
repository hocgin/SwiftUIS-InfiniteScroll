import Foundation
import SwiftUI

/// 抽象「可滚动到指定日」的能力，供 `DayScrollProxy` 持有而不泄漏 Item 泛型。
///
/// `InfiniteScrollController<Item>` 实现此协议；
/// `DayScrollProxy` 仅持有 `any DayScrollable`，对外隐藏 Item 类型。
@MainActor
public protocol DayScrollable: AnyObject {

    /// 滚动到指定 DayKey。
    func scrollTo(_ key: DayKey, anchor: UnitPoint?, animated: Bool)
}

/// 日期定位代理：暴露给子视图 / 调用方做日期跳转。
///
/// 通过 `@Environment(\.dayScrollProxy)` 取得（由 InfiniteDayScrollView 自动注入）。
///
/// 用法：
/// ```swift
/// @Environment(\.dayScrollProxy) private var proxy
///
/// Button("回到今天") { proxy?.scrollToToday() }
/// ```
public struct DayScrollProxy: @unchecked Sendable {

    /// 任何 @MainActor 类型实例都不直接 Sendable；
    /// 此处用 @unchecked 表示：所有访问都在 MainActor 内完成（子视图自动 MainActor）。
    private let scrollable: any DayScrollable

    @MainActor
    public init(_ scrollable: any DayScrollable) {
        self.scrollable = scrollable
    }

    /// 滚动到今天。
    @MainActor
    public func scrollToToday(anchor: UnitPoint? = .top, animated: Bool = true) {
        scrollable.scrollTo(.today, anchor: anchor, animated: animated)
    }

    /// 滚动到指定日期。
    @MainActor
    public func scrollTo(
        _ date: Date,
        anchor: UnitPoint? = .top,
        animated: Bool = true
    ) {
        scrollable.scrollTo(DayKey(date: date), anchor: anchor, animated: animated)
    }

    /// 滚动到某月第一天。
    @MainActor
    public func scrollToMonth(
        _ month: Date,
        anchor: UnitPoint? = .top,
        animated: Bool = true
    ) {
        let firstDay = Calendar.current.firstDayOfMonth(for: month)
        scrollable.scrollTo(firstDay, anchor: anchor, animated: animated)
    }
}

// MARK: - EnvironmentKey

private struct DayScrollProxyKey: EnvironmentKey {
    static let defaultValue: DayScrollProxy? = nil
}

public extension EnvironmentValues {

    /// 当前 InfiniteDayScrollView 的日期定位代理。
    ///
    /// 子视图通过 `@Environment(\.dayScrollProxy)` 取得。
    var dayScrollProxy: DayScrollProxy? {
        get { self[DayScrollProxyKey.self] }
        set { self[DayScrollProxyKey.self] = newValue }
    }
}
