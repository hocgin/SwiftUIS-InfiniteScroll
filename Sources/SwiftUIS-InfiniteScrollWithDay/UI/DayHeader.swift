import SwiftUI

/// 默认日期头：粗体日期 + 副标题。
///
/// 用户可通过 `.dayHeader { date in ... }` 修饰符完全替换。
public struct DayHeader: View {

    private let date: Date

    public init(date: Date) {
        self.date = date
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(date, format: .dateTime.month().day())
                .font(.headline)
                .foregroundStyle(.primary)
            Text(date, format: .dateTime.weekday(.wide))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
