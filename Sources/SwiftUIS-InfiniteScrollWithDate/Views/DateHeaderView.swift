import SwiftUI

/// 默认日期头。
public struct DateHeaderView: View {

    private let date: Date
    private let grouping: TimelineGrouping

    public init(date: Date, grouping: TimelineGrouping = .day) {
        self.date = date
        self.grouping = grouping
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleText)
                .font(.headline)
                .foregroundStyle(.primary)
            if let subtitle = subtitleText {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var titleText: String {
        switch grouping {
        case .day:
            return date.formatted(.dateTime.month().day().year())
        case .week:
            return "Week of " + date.formatted(.dateTime.month().day())
        case .month:
            return date.formatted(.dateTime.month(.wide).year())
        case .year:
            return date.formatted(.dateTime.year())
        }
    }

    private var subtitleText: String? {
        switch grouping {
        case .day:
            return date.formatted(.dateTime.weekday(.wide))
        default:
            return nil
        }
    }
}
