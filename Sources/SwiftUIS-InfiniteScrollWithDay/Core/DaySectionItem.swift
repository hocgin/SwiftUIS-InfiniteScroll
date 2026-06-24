import Foundation

/// 渲染层联合：ForEach 单元类型。
///
/// 把「正常日 / 空日折叠区间 / 加载占位」三种渲染意图统一到一个 enum，
/// 让 LazyVStack `ForEach(ctrl.sectionItems)` 元素类型固定，符合 SwiftUI ForEach 稳定要求。
///
/// 顺序约定：`.day` 与 `.gap` 按 DayKey 时间顺序混排；`.loading` 仅出现在尾部。
public enum DaySectionItem<Item: Sendable>: Sendable, Identifiable {

    /// 正常日（含 loaded / empty / failed）。
    case day(DayModel<Item>)

    /// 折叠区间（collapse 策略下，连续空日合并）。
    case gap(GapRange)

    /// 加载占位（下一批未到位时）。
    case loading(DayKey)

    // MARK: - Identifiable

    /// 稳定 ID：用 DayKey.daySinceEpoch；loading 占位用 DayKey，避免与 day 撞 ID。
    public var id: Int {
        switch self {
        case .day(let model): return model.key.daySinceEpoch
        case .gap(let gap): return gap.id
        case .loading(let key): return -(key.daySinceEpoch + 1)  // 负数空间，避开正值
        }
    }
}
