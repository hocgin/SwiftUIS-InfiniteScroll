import Foundation
import SwiftUI

/// 抽象「可滚动到指定日期」的能力，供 `InfiniteScrollProxy` 持有而不泄漏 Item 泛型。
@MainActor
public protocol InfiniteScrollable: AnyObject {
    /// 找到/计算目标 date 所属分组键，触发滚动。
    func scrollToDate(_ date: Date)
}

/// 跳转代理：暴露给外部（toolbar / 兄弟视图）调用日期定位。
///
/// 通过 `scrollProxy:` binding 参数从 `InfiniteDateScrollView` 取得（不用 @Environment，
/// 因为父视图层级读不到子视图设置的 environment）。
public struct InfiniteScrollProxy: @unchecked Sendable {

    private let scrollable: any InfiniteScrollable

    @MainActor
    public init(_ scrollable: any InfiniteScrollable) {
        self.scrollable = scrollable
    }

    /// 滚动到指定日期所属的分组。
    ///
    /// 自动按当前 grouping（day/week/month/year）归一目标。
    @MainActor
    public func scrollTo(_ date: Date) {
        scrollable.scrollToDate(date)
    }
}
