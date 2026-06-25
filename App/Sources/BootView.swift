import SwiftUI
import SwiftUIS_InfiniteScrollWithDay
import SwiftUIS_InfiniteScrollWithDate
import SwiftUIS_InfiniteScroll

struct BootView: View {
    var body: some View {
        TabView {
            BasicDemoView()
                .tabItem {
                    Label("基础", systemImage: "calendar")
                }

            DataDrivenDemoView()
                .tabItem {
                    Label("数据驱动", systemImage: "list.bullet.rectangle")
                }

            FullDemoView()
                .tabItem {
                    Label("完整", systemImage: "rectangle.stack")
                }

            TimelineDemoView()
                .tabItem {
                    Label("时间轴", systemImage: "clock.arrow.circlepath")
                }

            FeedDemoView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet")
                }
        }
    }
}

// MARK: - 基础版 Demo

/// 基础版 Demo：按 DayRange.past(days: 365) 迭代，每天显示日期。
struct BasicDemoView: View {
    var body: some View {
        NavigationStack {
            InfiniteDayScrollView(range: .past(days: 365)) { day in
                VStack(alignment: .leading, spacing: 8) {
                    Text("这是 \(day.formatted(date: .complete, time: .omitted))")
                        .font(.body)
                    Text("（占位内容，无数据源模式）")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .navigationTitle("基础版 Demo")
        }
    }
}

// MARK: - 数据驱动版 Demo

/// 数据驱动版 Demo：用 StaticDayDataSource 提供稀疏数据，
/// 默认 `.collapse` 策略下空日会被折叠为 GapSection。
struct DataDrivenDemoView: View {

    private let source: StaticDayDataSource<Record>

    init() {
        let today = DayKey.today
        var storage: [DayKey: [Record]] = [:]
        // 60 天范围内，每 3 天塞 2 条记录（其余为空日）。
        for offset in stride(from: 0, through: 60, by: 3) {
            let key = today.adding(days: -offset)
            storage[key] = [
                Record(title: "记录 A（第 \(-offset) 天）"),
                Record(title: "记录 B（第 \(-offset) 天）"),
            ]
        }
        self.source = StaticDayDataSource(storage: storage)
    }

    var body: some View {
        NavigationStack {
            InfiniteDayScrollView(source: source) { _, records in
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(records) { record in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.6))
                                .frame(width: 4)
                            Text(record.title)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .emptyView {
                Text("（当天无记录）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .gapView { gap in
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(gap.count) 天空档")
                            .font(.subheadline.bold())
                        Text("\(gap.start.referenceDate, format: .dateTime.month(.abbreviated).day()) – \(gap.end.referenceDate, format: .dateTime.month(.abbreviated).day())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("点击展开")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .header { ctx in
                HStack(spacing: 8) {
                    // 日期数字大字
                    Text(ctx.date, format: .dateTime.day())
                        .font(.system(size: 28, weight: .bold))
                        .frame(width: 44, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(ctx.date, format: .dateTime.month(.abbreviated).year())
                                .font(.subheadline)
                            if ctx.isToday {
                                Text("今天")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                        if ctx.itemCount > 0 {
                            Text("\(ctx.itemCount) 条记录")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if ctx.isEmpty {
                            Text("无记录")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.thinMaterial)
            }
            .navigationTitle("数据驱动 Demo")
        }
    }
}

// MARK: - 完整版 Demo

/// 完整版 Demo：MockTimeline 压力数据 + 日期定位按钮 + 自定义 header/loading。
struct FullDemoView: View {

    /// 通过 binding 从 InfiniteDayScrollView 拿到 proxy，供外部 toolbar 调用。
    /// 不用 @Environment(\.dayScrollProxy)：SwiftUI environment 单向向下，
    /// toolbar（父视图层级）读不到子视图设置的 environment。
    @State private var scrollProxy: InfiniteDayScrollViewInfiniteScrollProxy?
    private let source = MockTimeline(recordsPerDay: 10)

    var body: some View {
        NavigationStack {
            InfiniteDayScrollView(
                source: source,
                emptyStrategy: .collapse,
                batchSize: 30,
                stickyHeader: false,
                forwardLoading: false,
                scrollProxy: $scrollProxy
            ) { _, records in
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.title)
                                .font(.body)
                            Text(record.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("完整版 Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("回到今天") { scrollProxy?.scrollToToday() }
                        Button("3 个月前") {
                            scrollProxy?.scrollTo(Date().addingTimeInterval(-90 * 86_400))
                        }
                        Button("6 个月前") {
                            scrollProxy?.scrollTo(Date().addingTimeInterval(-180 * 86_400))
                        }
                        Button("跳转到本月") {
                            scrollProxy?.scrollToMonth(Date())
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
        }
    }
}

// MARK: - 数据模型

private struct Record: Sendable, Identifiable {
    let id = UUID()
    let title: String
}

// MARK: - 时间轴模块 Demo（SwiftUIS-InfiniteScroll）

/// 演示基于游标分页的无限滚动时间轴。
struct TimelineDemoView: View {

    /// 通过 binding 拿到 proxy，供 toolbar 调用跳转。
    @State private var scrollProxy: InfiniteDateScrollViewInfiniteScrollProxy?

    var body: some View {
        NavigationStack {
            InfiniteDateScrollView(
                loader: MockTimelineLoader(),
                grouping: .week,
                showEmptyDays: false,
                preloadThreshold: 5,
                scrollProxy: $scrollProxy
            ) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                    Text(item.date, format: .dateTime.hour().minute().second())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .header { date, _ in
                HStack {
                    Text(date, format: .dateTime.month().day())
                        .font(.headline)
                    Spacer()
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.thinMaterial)
            }
            .errorView { _, retry in
                VStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.title)
                    Text("网络错误，请重试")
                    Button("重试", action: retry)
                        .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("时间轴 Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("跳到 7 天前") {
                        scrollProxy?.scrollTo(Date().addingTimeInterval(-7 * 86_400))
                    }
                }
            }
        }
    }
}

// MARK: - 通用 Feed Demo（SwiftUIS-InfiniteScroll 模块）

/// 演示通用无限滚动列表：游标分页 + 预加载 + 下拉刷新 + 错误恢复 + 跳转定位。
struct FeedDemoView: View {

    /// 通过 binding 从 InfiniteScrollView 拿到 proxy，供外部 toolbar 调用跳转。
    /// 仍按 FullDemoView 的模式：不用 @Environment，因为父视图层级（toolbar）读不到
    /// 子视图设置的 environment。
    @State private var scrollProxy: InfiniteScrollViewInfiniteScrollProxy<MockFeedItem>?

    var body: some View {
        NavigationStack {
            InfiniteScrollView(
                loader: MockFeedLoader(),
                preloadStrategy: .fixed(5),
                scrollProxy: $scrollProxy
            ) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.body)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .navigationTitle("Feed Demo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // 回到顶部：始终可用（首页必然已加载）。
                        Button("回到顶部") {
                            scrollProxy?.scrollToTop()
                        }
                        // 跳到首页内某条：首页必然已加载，稳定可跳。
                        Button("跳到第 5 条") {
                            scrollProxy?.scrollTo("item-4")
                        }
                        // 跳到非首页条目：需要用户先滚到加载过该条的位置。
                        // proxy 对未加载的 id 会忽略（详见 InfiniteScrollViewInfiniteScrollProxy.scrollTo）。
                        Button("跳到第 50 条（需先加载）") {
                            scrollProxy?.scrollTo("item-49")
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
        }
    }
}

#Preview {
    BootView()
}
