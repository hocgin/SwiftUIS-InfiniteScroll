//
//  L10n.swift
//  SwiftUIS-InfiniteScrollWithDay
//
//  类型安全的本地化 Key 入口。所有对外可见文案统一通过此命名空间引用，
//  禁止在视图中硬编码 String 字面量。bundle 固定为 `.module`（SPM 包内）。
//

import Foundation

public enum L10n {

    /// 非交互文本（标签、状态、占位提示）。
    public enum Label {
        /// "No records" - 当天没有数据时的占位文案
        public static var emptyDay: String {
            String(
                localized: "InfiniteScrollWithDay.day.empty",
                defaultValue: "No records",
                bundle: .module,
                comment: "当天没有数据时的占位文案"
            )
        }

        /// "Failed to load" - 当天加载失败时的占位文案
        public static var loadFailed: String {
            String(
                localized: "InfiniteScrollWithDay.day.error",
                defaultValue: "Failed to load",
                bundle: .module,
                comment: "当天加载失败时的占位文案"
            )
        }

        /// "~" - 折叠区间起止日期之间的分隔符
        public static var gapSeparator: String {
            String(
                localized: "InfiniteScrollWithDay.gap.separator",
                defaultValue: "~",
                bundle: .module,
                comment: "折叠区间起止日期之间的分隔符"
            )
        }
    }

    /// 含参数的句子或动态文案。
    public enum Message {
        /// "%lld-day gap" - 折叠区间显示的天数说明
        public static func gapDays(_ count: Int) -> String {
            String(
                localized: "InfiniteScrollWithDay.gap.days",
                defaultValue: "\(count)-day gap",
                bundle: .module,
                comment: "折叠区间显示的天数说明，参数为天数"
            )
        }
    }
}
