import SwiftUI
import SwiftUIS_InfiniteScrollWithDay

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
            .emptyDayView {
                Text("（当天无记录）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
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
    @State private var scrollProxy: DayScrollProxy?
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

#Preview {
    BootView()
}
