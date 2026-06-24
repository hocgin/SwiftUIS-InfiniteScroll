import Foundation
import SwiftUI

/// ScrollView 顶部/底部哨兵 ID。
///
/// LazyVStack 末尾插入 `Color.clear.id(ScrollAnchors.bottom)`，
/// 配合 `.onAppear` 触发下一批加载。
/// 单独抽离常量是为了避免字符串字面量散落各处。
public enum ScrollAnchors {

    /// 底部哨兵：滚动到列表末尾时触发，加载更早日期。
    public static let bottom: String = "infinite.dayscroll.bottom"

    /// 顶部哨兵：仅 forwardLoading=true 时插入，加载更晚日期。
    public static let top: String = "infinite.dayscroll.top"
}
