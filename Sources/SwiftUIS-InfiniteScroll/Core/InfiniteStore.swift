import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.hocgin.SwiftUIS-InfiniteScroll", category: "InfiniteStore")

/// 无限列表状态机：驱动分页加载、维护数据与状态。
///
/// 隔离：`@MainActor` 保证状态读写都在主线程；
/// Loader 协议方法是非隔离 `async throws`，可在任意 actor 实现。
@MainActor
@Observable
public final class InfiniteStore<Item: Sendable & Identifiable> {

    // MARK: - 公开状态

    /// 已加载的全部数据。
    public private(set) var items: [Item] = []

    /// 首次加载状态。
    public private(set) var state: InfiniteState = .idle

    /// 底部分页状态。
    public private(set) var footerState: InfiniteFooterState = .none

    /// 是否在「下拉刷新」（与首次/分页 loading 区分）。
    public private(set) var isRefreshing: Bool = false

    /// 是否还有更多数据。
    public private(set) var hasMore: Bool = true

    /// 下一页游标。
    public private(set) var nextId: String?

    /// 最近一次错误（首次失败或分页失败）。
    public private(set) var lastError: (any Error)?

    // MARK: - 配置与依赖

    public let loader: AnyInfiniteLoader<Item>
    public let preloadStrategy: PreloadStrategy

    // MARK: - 私有

    private var loadTask: Task<Void, Never>?
    private var isBootstrapped = false

    // MARK: - 初始化

    public init<L: InfiniteLoader>(
        loader: L,
        preloadStrategy: PreloadStrategy = .defaultStrategy
    ) where L.Item == Item {
        self.loader = AnyInfiniteLoader(loader)
        self.preloadStrategy = preloadStrategy
    }

    public init(
        loader: AnyInfiniteLoader<Item>,
        preloadStrategy: PreloadStrategy = .defaultStrategy
    ) {
        self.loader = loader
        self.preloadStrategy = preloadStrategy
    }

    // MARK: - 便捷派生

    /// 是否正在加载（首次或分页）。
    public var isLoading: Bool {
        state == .loading || footerState == .loading
    }

    // MARK: - 生命周期

    /// 首次加载。幂等。
    public func bootstrap() {
        guard !isBootstrapped else { return }
        isBootstrapped = true
        loadFirst()
    }

    /// 加载首页（清空已有数据）。
    public func loadFirst() {
        guard state != .loading else { return }
        if loadTask != nil { return }

        state = .loading
        items.removeAll()
        nextId = nil
        hasMore = true
        footerState = .none
        lastError = nil

        startLoad(cursor: nil, isRefresh: false)
    }

    /// 下拉刷新：重新拉取首页（与 loadFirst 区别在 isRefreshing 标记）。
    public func reload() {
        guard !isRefreshing else { return }
        if loadTask != nil {
            loadTask?.cancel()
            loadTask = nil
        }

        isRefreshing = true
        // reload 时若已有数据，保留旧数据避免闪烁；空则切 loading。
        if items.isEmpty {
            state = .loading
        }

        nextId = nil
        hasMore = true
        footerState = .none

        startLoad(cursor: nil, isRefresh: true)
    }

    /// async 版 reload：配合 SwiftUI `.refreshable` 使用，
    /// 等到本轮加载完成（isRefreshing 变 false）后才返回，让刷新指示器正确收起。
    public func reloadAsync() async {
        reload()
        // polling 等待加载完成；50ms 间隔足够流畅。
        while isRefreshing || state == .loading {
            do {
                try await Task.sleep(nanoseconds: 50_000_000)
            } catch {
                return
            }
        }
    }

    /// 加载下一页。
    public func loadMore() {
        guard !isLoading, hasMore else { return }
        if loadTask != nil { return }

        footerState = .loading
        startLoad(cursor: nextId, isRefresh: false)
    }

    /// 重试当前页（首次失败或分页失败时调用）。
    public func retry() {
        if state == .failed {
            loadFirst()
        } else if footerState == .failed {
            footerState = .none
            loadMore()
        }
    }

    // MARK: - 内部

    private func startLoad(cursor: String?, isRefresh: Bool) {
        let loader = loader
        let isFirst = items.isEmpty && !isRefresh

        loadTask = Task { [weak self] in
            do {
                let page = try await loader.load(nextId: cursor)
                guard let self else { return }

                if isRefresh {
                    // 刷新：替换全部
                    self.items = page.records
                } else {
                    self.items.append(contentsOf: page.records)
                }
                self.nextId = page.nextId
                self.hasMore = page.hasMore
                self.lastError = nil
                self.footerState = page.hasMore ? .none : .noMore
                self.state = self.items.isEmpty ? .empty : .loaded
                self.isRefreshing = false
                self.loadTask = nil
            } catch {
                guard let self else { return }
                self.lastError = error
                if isFirst || isRefresh {
                    self.state = .failed
                    self.isRefreshing = false
                } else {
                    self.footerState = .failed
                }
                self.loadTask = nil
                logger.error("InfiniteStore load failed: \(String(describing: error))")
            }
        }
    }

    /// 预加载检查：由 View 在每个 item.onAppear 时调用。
    public func checkPreload(remaining: Int) {
        guard hasMore, !isLoading else { return }
        if preloadStrategy.shouldTrigger(remaining: remaining, total: items.count) {
            loadMore()
        }
    }
}
