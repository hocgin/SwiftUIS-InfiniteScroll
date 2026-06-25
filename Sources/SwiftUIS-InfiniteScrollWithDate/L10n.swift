//
//  L10n.swift
//  SwiftUIS-InfiniteScrollWithDate
//
//  类型安全的本地化 Key 入口。所有对外可见文案统一通过此命名空间引用，
//  禁止在视图中硬编码 String 字面量。bundle 固定为 `.module`（SPM 包内）。
//

import Foundation

public enum L10n {

    /// 非交互文本（标签、状态、占位提示）。
    public enum Label {
        /// "No data yet" - 时间轴整体为空时的占位文案
        public static var emptyData: String {
            String(
                localized: "InfiniteScrollWithDate.empty.data",
                defaultValue: "No data yet",
                bundle: .module,
                comment: "时间轴整体为空时的占位文案"
            )
        }

        /// "No records" - 单个分组内没有数据时的占位文案
        public static var emptySection: String {
            String(
                localized: "InfiniteScrollWithDate.section.empty",
                defaultValue: "No records",
                bundle: .module,
                comment: "单个分组内没有数据时的占位文案"
            )
        }

        /// "Failed to load" - 时间轴加载失败时的占位文案
        public static var loadFailed: String {
            String(
                localized: "InfiniteScrollWithDate.error.title",
                defaultValue: "Failed to load",
                bundle: .module,
                comment: "时间轴加载失败时的占位文案"
            )
        }
    }

    /// 交互按钮文案。
    public enum Action {
        /// "Retry" - 错误视图重试按钮
        public static var retry: String {
            String(
                localized: "InfiniteScrollWithDate.action.retry",
                defaultValue: "Retry",
                bundle: .module,
                comment: "错误视图重试按钮"
            )
        }
    }
}
