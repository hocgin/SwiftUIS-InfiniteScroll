import Foundation

/// 跳转代理：暴露给外部（toolbar / 兄弟视图）调用 `InfiniteScrollView` 列表定位。
///
/// 命名约定：三个模块的跳转代理统一采用 `<主组件>InfiniteScrollProxy` 形式，
/// 在跨模块 import 时天然避免同名歧义：
/// - 本模块：`InfiniteScrollViewInfiniteScrollProxy<Item>`（按 id 跳转）
/// - `SwiftUIS-InfiniteScrollWithDate`：`InfiniteDateScrollViewInfiniteScrollProxy`（按 Date 跳转）
/// - `SwiftUIS-InfiniteScrollWithDay`：`InfiniteDayScrollViewInfiniteScrollProxy`（按 DayKey / 月份跳转）
///
/// 通过 init 参数 `scrollProxy: Binding<InfiniteScrollViewInfiniteScrollProxy<Item>?>?` 取得：
/// ```swift
/// @State private var proxy: InfiniteScrollViewInfiniteScrollProxy<Post>?
/// InfiniteScrollView(loader: ..., scrollProxy: $proxy) { ... }
/// // 之后：proxy?.scrollTo(postId) / proxy?.scrollToTop()
/// ```
///
/// 不用 `@Environment` 是因为父视图层级（如 `.toolbar`）读不到子视图设置的 environment。
public struct InfiniteScrollViewInfiniteScrollProxy<Item: Sendable & Identifiable>: @unchecked Sendable where Item.ID: Sendable {

    private let store: InfiniteStore<Item>

    @MainActor
    public init(_ store: InfiniteStore<Item>) {
        self.store = store
    }

    /// 滚动到指定 id。若 id 不在已加载 items 中，会被忽略（记 warning）。
    @MainActor
    public func scrollTo(_ id: Item.ID, animated: Bool = true) {
        store.requestScroll(to: id, animated: animated)
    }

    /// 回到顶部（滚动到第一个 item）。
    @MainActor
    public func scrollToTop(animated: Bool = true) {
        store.requestScrollToTop(animated: animated)
    }
}
