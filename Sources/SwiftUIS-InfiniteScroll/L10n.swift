//
//  L10n.swift
//  SwiftUIS-InfiniteScroll
//
//  类型安全的本地化 Key 入口。所有对外可见文案统一通过此命名空间引用，
//  禁止在视图中硬编码 String 字面量。bundle 固定为 `.module`（SPM 包内）。
//

import Foundation

public enum L10n {

    /// 非交互文本（标签、状态、占位提示）。
    public enum Label {
        /// "No data yet" - 列表为空时的占位文案
        public static var emptyData: String {
            String(
                localized: "InfiniteScroll.empty.data",
                defaultValue: "No data yet",
                bundle: .module,
                comment: "列表为空时的占位文案"
            )
        }

        /// "Loading…" - 列表底部加载更多时的占位文案
        public static var loading: String {
            String(
                localized: "InfiniteScroll.footer.loading",
                defaultValue: "Loading…",
                bundle: .module,
                comment: "列表底部加载更多时的占位文案"
            )
        }

        /// "Failed to load" - 错误视图标题
        public static var loadFailed: String {
            String(
                localized: "InfiniteScroll.error.title",
                defaultValue: "Failed to load",
                bundle: .module,
                comment: "错误视图标题"
            )
        }

        /// "Load failed. Tap to retry." - 列表底部加载失败时的提示
        public static var loadFailedWithHint: String {
            String(
                localized: "InfiniteScroll.footer.error",
                defaultValue: "Load failed. Tap to retry.",
                bundle: .module,
                comment: "列表底部加载失败时的提示"
            )
        }

        /// "No more items" - 列表已加载全部数据时的占位文案
        public static var noMore: String {
            String(
                localized: "InfiniteScroll.footer.end",
                defaultValue: "No more items",
                bundle: .module,
                comment: "列表已加载全部数据时的占位文案"
            )
        }
    }

    /// 交互按钮文案。
    public enum Action {
        /// "Retry" - 错误视图重试按钮
        public static var retry: String {
            String(
                localized: "InfiniteScroll.action.retry",
                defaultValue: "Retry",
                bundle: .module,
                comment: "错误视图重试按钮"
            )
        }
    }

    /// 含参数的句子或错误消息。
    public enum Message {
        /// "Failed to load. Please retry." - 默认错误的用户可读描述
        public static var loadFailedGeneric: String {
            String(
                localized: "InfiniteScroll.error.generic",
                defaultValue: "Failed to load. Please retry.",
                bundle: .module,
                comment: "默认错误的用户可读描述"
            )
        }
    }
}
