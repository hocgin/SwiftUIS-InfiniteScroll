import Testing
import Foundation
@testable import SwiftUIS_InfiniteScroll

@Suite struct PreloadStrategyTests {

    @Test func fixed策略剩余N项触发() {
        let strategy = PreloadStrategy.fixed(5)
        #expect(strategy.shouldTrigger(remaining: 6, total: 100) == false)
        #expect(strategy.shouldTrigger(remaining: 5, total: 100) == true)
        #expect(strategy.shouldTrigger(remaining: 0, total: 100) == true)
    }

    @Test func ratio策略百分比触发() {
        let strategy = PreloadStrategy.ratio(0.8)
        #expect(strategy.shouldTrigger(remaining: 100, total: 100) == false)  // 0%
        #expect(strategy.shouldTrigger(remaining: 25, total: 100) == false)  // 75%
        #expect(strategy.shouldTrigger(remaining: 20, total: 100) == true)   // 80%
        #expect(strategy.shouldTrigger(remaining: 0, total: 100) == true)    // 100%
    }

    @Test func total为0时ratio不触发() {
        let strategy = PreloadStrategy.ratio(0.5)
        #expect(strategy.shouldTrigger(remaining: 0, total: 0) == false)
    }
}

@Suite struct PageTests {

    @Test func hasMore未指定时由nextId推断() {
        #expect(Page<Int>(records: [1], nextId: "x").hasMore == true)
        #expect(Page<Int>(records: [1], nextId: nil).hasMore == false)
    }

    @Test func hasMore显式优先() {
        let page = Page<Int>(records: [1], nextId: "x", hasMore: false)
        #expect(page.hasMore == false)
    }
}

private struct MockItem: Sendable, Identifiable, Equatable {
    let id: String
}

private struct MockLoader: InfiniteLoader, Sendable {
    let pages: [Page<MockItem>]

    func load(nextId: String?) async throws -> Page<MockItem> {
        // 模拟轻微延迟
        try? await Task.sleep(nanoseconds: 10_000_000)
        if nextId == nil {
            return pages.first ?? Page(records: [], nextId: nil)
        }
        let idx = pages.firstIndex(where: { $0.nextId == nextId }).map { $0 + 1 } ?? pages.count
        return idx < pages.count ? pages[idx] : Page(records: [], nextId: nil)
    }
}

@MainActor
@Suite struct InfiniteStoreTests {

    @Test func bootstrap加载首页() async {
        let loader = MockLoader(pages: [
            Page(records: [MockItem(id: "a"), MockItem(id: "b")], nextId: "c1", hasMore: true),
        ])
        let store = InfiniteStore(loader: loader)
        store.bootstrap()
        await waitForIdle(store)

        #expect(store.state == .loaded)
        #expect(store.items.count == 2)
        #expect(store.hasMore == true)
    }

    @Test func loadMore追加数据() async {
        let loader = MockLoader(pages: [
            Page(records: [MockItem(id: "a")], nextId: "c1", hasMore: true),
            Page(records: [MockItem(id: "b")], nextId: nil, hasMore: false),
        ])
        let store = InfiniteStore(loader: loader)
        store.bootstrap()
        await waitForIdle(store)
        #expect(store.items.count == 1)

        store.loadMore()
        await waitForIdle(store)

        #expect(store.items.count == 2)
        #expect(store.hasMore == false)
        #expect(store.footerState == .noMore)
    }

    @Test func 加载失败切到failed状态() async {
        struct TestError: Error {}
        let loader = AnyInfiniteLoader<MockItem> { _ in throw TestError() }
        let store = InfiniteStore(loader: loader)
        store.bootstrap()
        await waitForIdle(store)

        #expect(store.state == .failed)
        #expect(store.lastError != nil)
    }

    @Test func 分页失败不丢失已加载数据() async {
        final class Toggle: @unchecked Sendable {
            var firstCall = true
        }
        let toggle = Toggle()
        struct TestError: Error {}
        let loader = AnyInfiniteLoader<MockItem> { _ in
            if toggle.firstCall {
                toggle.firstCall = false
                return Page(records: [MockItem(id: "a")], nextId: "c1", hasMore: true)
            }
            throw TestError()
        }
        let store = InfiniteStore(loader: loader)
        store.bootstrap()
        await waitForIdle(store)
        #expect(store.items.count == 1)

        store.loadMore()
        await waitForIdle(store)

        // 已加载数据保留，footer 切 failed
        #expect(store.items.count == 1)
        #expect(store.footerState == .failed)
    }

    @Test func retry从失败恢复() async {
        final class Toggle: @unchecked Sendable {
            var shouldFail = true
        }
        let toggle = Toggle()
        struct TestError: Error {}
        let loader = AnyInfiniteLoader<MockItem> { _ in
            if toggle.shouldFail {
                toggle.shouldFail = false
                throw TestError()
            }
            return Page(records: [MockItem(id: "a")], nextId: nil, hasMore: false)
        }
        let store = InfiniteStore(loader: loader)
        store.bootstrap()
        await waitForIdle(store)
        #expect(store.state == .failed)

        store.retry()
        await waitForIdle(store)
        #expect(store.state == .loaded)
    }

    @Test func preloadThreshold触发loadMore() async {
        let loader = MockLoader(pages: [
            Page(records: [MockItem(id: "a"), MockItem(id: "b")], nextId: "c1", hasMore: true),
            Page(records: [MockItem(id: "c")], nextId: nil, hasMore: false),
        ])
        let store = InfiniteStore(loader: loader, preloadStrategy: .fixed(1))
        store.bootstrap()
        await waitForIdle(store)

        // 剩 1 项时触发（fixed(1)），等价于滚到最后一条
        store.checkPreload(remaining: 1)
        await waitForIdle(store)

        #expect(store.items.count == 3)
    }

    private func waitForIdle(_ store: InfiniteStore<MockItem>) async {
        for _ in 0..<20 {
            if !store.isLoading { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
