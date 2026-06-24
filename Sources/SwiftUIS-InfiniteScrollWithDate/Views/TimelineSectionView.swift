import SwiftUI

/// 单个分组的渲染：Sticky Header + items。
///
/// 由 InfiniteDateScrollView 的 ForEach 直接消费。
public struct TimelineSectionView<Item: TimelineItem, Content: View>: View {

    private let section: TimelineSection<Item>
    private let grouping: TimelineGrouping
    private let content: (Item) -> Content

    @Environment(\.dateHeaderBuilder) private var headerBuilder

    public init(
        section: TimelineSection<Item>,
        grouping: TimelineGrouping,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.section = section
        self.grouping = grouping
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            if section.items.isEmpty {
                // 空日 placeholder：展示极小提示
                Text("无记录")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(section.items) { item in
                        content(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var headerView: some View {
        if let builder = headerBuilder.builder {
            builder(section.date, grouping)
        } else {
            DateHeaderView(date: section.date, grouping: grouping)
        }
    }
}
