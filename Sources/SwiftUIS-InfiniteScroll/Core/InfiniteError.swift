import Foundation

/// 错误包装。
///
/// 不强制具体 Error 类型，业务方抛任意 Error；Store 持有 `lastError: any Error`。
/// UI 层通过 `errorView { error in ... }` 自定义展示。
public protocol InfiniteError: Error, Sendable {

    /// 用户可读的错误描述（用于默认 ErrorView）。
    var userMessage: String { get }
}

/// 默认错误（无具体业务信息时使用）。
public struct DefaultInfiniteError: InfiniteError {
    public let userMessage: String

    public init(userMessage: String = "加载失败，请重试") {
        self.userMessage = userMessage
    }
}
