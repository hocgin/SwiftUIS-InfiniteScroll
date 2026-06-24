---
name: swift-localization
description: >
  使用 String(localized:)、String Catalog (.xcstrings) 和类型安全本地化模式，
  实现 Swift/SwiftUI 应用国际化的最佳实践。适用于实现多语言支持、添加新 UI 字符串、
  或重构 Swift 应用中的硬编码文本。
license: MIT
---

# Swift 本地化最佳实践

基于 Apple 现代框架和类型安全模式，在 Swift 和 SwiftUI 应用中实现本地化的完整指南。

## 核心原则

### 1. 禁止硬编码面向用户的字符串

所有用户可见的文本都必须本地化，包括：
- UI 标签、按钮和导航标题
- 错误消息和弹窗
- 占位符文本和提示
- 无障碍标签和提示
- 状态消息和通知

**错误：**
```swift
Text("添加体重")
Button("保存") { ... }
.alert("错误", message: "出了点问题")
```

**正确：**
```swift
Text(TK.App.Label.addWeight)
Button(TK.App.Action.save) { ... }
.alert(TK.App.Message.errorTitle, message: TK.App.Message.genericError)
```

### 2. 使用类型安全的本地化 Key

通过 `TK.App` 命名空间的扩展结构，获得编译时安全保证。

## 代码规范

### 文档注释

每个变量前必须有 `///` 文档注释，格式为 `/// "<defaultValue>" - <comment>`：

```swift
/// "Save" - Use for primary save action
public static var save: String {
    String(localized: "TK.App.common.action.save", defaultValue: "Save", bundle: .main, comment: "Use for primary save action")
}
```

### 初始化器

使用 `String(localized:defaultValue:bundle:comment:)` 初始化器：

```swift
public static var settings: String {
    String(
        localized: "TK.App.settings.navigation.title",
        defaultValue: "Settings",
        bundle: .main,
        comment: "Settings screen title"
    )
}
```

### bundle 参数

`bundle` 参数根据使用场景选择：
- 在 Xcode App 项目中：`.main`
- 在 SPM 包中：`.module`
- 不要固定为某个值，应根据实际目标类型决定

## 实现模式

### 结构：TK+App+Label.swift

按功能或页面创建扩展：

```swift
import SwiftLocale_Core

/// Non-interactive text that describes or labels UI elements
extension TK.App.Label {
    /// "Dashboard" - Dashboard screen title
    public static var dashboardTitle: String {
        String(
            localized: "TK.App.dashboard.navigation.title",
            defaultValue: "Dashboard",
            bundle: .main,
            comment: "Dashboard screen title"
        )
    }

    /// "Settings" - Settings screen title
    public static var settingsTitle: String {
        String(
            localized: "TK.App.settings.navigation.title",
            defaultValue: "Settings",
            bundle: .main,
            comment: "Settings screen title"
        )
    }

    /// "Theme" - Theme selection title
    public static var themeTitle: String {
        String(
            localized: "TK.App.settings.personalization.theme.title",
            defaultValue: "Theme",
            bundle: .main,
            comment: "Theme selection title"
        )
    }
}
```

### 结构：TK+App+Action.swift

```swift
import SwiftLocale_Core

/// Interactive UI elements that trigger actions when tapped
extension TK.App.Action {
    /// "Save" - Use for primary save action
    public static var save: String {
        String(localized: "TK.App.common.action.save", defaultValue: "Save", bundle: .main, comment: "Use for primary save action")
    }

    /// "Cancel" - Use for cancel action
    public static var cancel: String {
        String(localized: "TK.App.common.action.cancel", defaultValue: "Cancel", bundle: .main, comment: "Use for cancel action")
    }
}
```

### Key 命名规范

使用点分隔的命名空间，与代码结构保持一致：
- `{feature}.{component}.{element}.{property}`
- 示例：
    - `TK.App.dashboard.currentWeight` - 简单值
    - `TK.App.common.action.save` - 可复用按钮
    - `TK.App.settings.personalization.theme.title` - 嵌套区块标题
    - `TK.App.addEntry.error.invalidWeight` - 错误消息

### 参数化字符串

对于包含动态内容的字符串，使用返回 `String` 的函数：

```swift
/// Full sentences used for user communication
extension TK.App.Message {
    /// "Latest: %@" - Latest entry time
    public static func latestEntry(_ time: String) -> String {
        String(
            localized: "TK.App.dashboard.entry.latest.time",
            defaultValue: "Latest: \(time)",
            bundle: .main,
            comment: "Latest entry time"
        )
    }

    /// "Average of %lld entries" - Average of entries count
    public static func averageEntries(_ count: Int) -> String {
        String(
            localized: "TK.App.dashboard.entry.average.count",
            defaultValue: "Average of \(count) entries",
            bundle: .main,
            comment: "Average of entries count"
        )
    }
}
```

### 在 SwiftUI 视图中使用

```swift
struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text(TK.App.Label.dashboardTitle)
                Button(TK.App.Action.save) {
                    save()
                }
            }
            .navigationTitle(TK.App.Label.dashboardTitle)
        }
    }
}
```

**字符串拼接或插值场景：**
```swift
TextField(TK.App.Placeholder.weightPlaceholder, text: $weightText)
    .accessibilityLabel(TK.App.Label.weightValue)
    .accessibilityHint(TK.App.Message.weightValueHint(unitSymbol))
```

### 无障碍本地化

始终单独定义无障碍字符串：

```swift
extension TK.App.Label {
    /// "Add weight entry" - Accessibility label for add button
    public static var addWeightEntry: String {
        String(
            localized: "TK.App.accessibility.weight.add.label",
            defaultValue: "Add weight entry",
            bundle: .main,
            comment: "Accessibility label for add button"
        )
    }
}

extension TK.App.Message {
    /// "Opens form to log a new weight" - Accessibility hint for add button
    public static var addWeightEntryHint: String {
        String(
            localized: "TK.App.accessibility.weight.add.hint",
            defaultValue: "Opens form to log a new weight",
            bundle: .main,
            comment: "Accessibility hint for add button"
        )
    }

    /// "Enter your current weight in %@" - Accessibility hint with unit
    public static func weightValueHint(_ unitSymbol: String) -> String {
        String(
            localized: "TK.App.accessibility.weight.input.hint",
            defaultValue: "Enter your current weight in \(unitSymbol)",
            bundle: .main,
            comment: "Accessibility hint with unit"
        )
    }
}
```

使用：
```swift
Button {
    showAddEntry = true
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel(TK.App.Label.addWeightEntry)
.accessibilityHint(TK.App.Message.addWeightEntryHint)
```

## String Catalog (.xcstrings)

### 文件结构

现代 Swift 项目使用 `.xcstrings` 文件（String Catalog）替代 `.strings` 文件。使用 `String(localized:)` 时，Xcode 会自动生成条目。

位置：`LocaleKit/Localizable.xcstrings`

示例结构：
```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "TK.App.common.action.save" : {
      "comment" : "Use for primary save action",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Save"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "保存"
          }
        },
        "ja" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "保存"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

### 在 Xcode 中管理 String Catalog

1. 添加新的 `String(localized:)` 条目后**构建项目** - Xcode 会自动检测
2. 在 Xcode 中打开 `Localizable.xcstrings`
3. 使用 **String Catalog 编辑器**添加翻译
4. Xcode 显示：
    - 已翻译的字符串
    - 未翻译的字符串（需要处理）
    - 状态：`new`、`translated`、`needs_review`

### 添加新语言

1. 在 Xcode 中：Project Settings -> Info -> Localizations -> `+`
2. 选择语言（如中文、日语、韩语）
3. Xcode 会将语言添加到所有 `.xcstrings` 文件
4. 在 String Catalog 编辑器中翻译字符串

## 常见模式

### 条件文本
```swift
extension TK.App.Label {
    /// "On" - iCloud sync enabled state
    public static var iCloudSyncEnabled: String {
        String(localized: "TK.App.settings.data.sync.enabled", defaultValue: "On", bundle: .main, comment: "iCloud sync enabled state")
    }

    /// "Off" - iCloud sync disabled state
    public static var iCloudSyncDisabled: String {
        String(localized: "TK.App.settings.data.sync.disabled", defaultValue: "Off", bundle: .main, comment: "iCloud sync disabled state")
    }
}

// 使用
Text(isEnabled ? TK.App.Label.iCloudSyncEnabled : TK.App.Label.iCloudSyncDisabled)
```

### 错误消息
```swift
extension TK.App.Message {
    /// "Please enter a valid weight" - Invalid weight error
    public static var errorInvalidWeight: String {
        String(
            localized: "TK.App.addEntry.error.weight.invalid",
            defaultValue: "Please enter a valid weight",
            bundle: .main,
            comment: "Invalid weight error"
        )
    }

    /// "Failed to save entry: %@" - Save failure error with detail
    public static func errorSaveFailure(_ message: String) -> String {
        String(
            localized: "TK.App.addEntry.form.save.failure",
            defaultValue: "Failed to save entry: \(message)",
            bundle: .main,
            comment: "Save failure error with detail"
        )
    }
}

// 使用
.alert(TK.App.Message.errorTitle, isPresented: $showingError) {
    Button(TK.App.Action.ok) { showingError = false }
} message: {
    Text(TK.App.Message.errorInvalidWeight)
}
```

### 复数形式

对于依赖数量的字符串，使用字符串插值：
```swift
/// "%lld days" - Days count
public static func days(_ count: Int) -> String {
    String(
        localized: "TK.App.common.unit.days",
        defaultValue: "\(count) days",
        bundle: .main,
        comment: "Days count"
    )
}
```

在 `.xcstrings` 中添加复数规则：
```json
"TK.App.common.unit.days" : {
  "localizations" : {
    "en" : {
      "variations" : {
        "plural" : {
          "one" : {
            "stringUnit" : {
              "state" : "translated",
              "value" : "%lld day"
            }
          },
          "other" : {
            "stringUnit" : {
              "state" : "translated",
              "value" : "%lld days"
            }
          }
        }
      }
    }
  }
}
```

### 日期格式化

让 Foundation 处理日期本地化：
```swift
// 正确 - 遵循用户的 locale
Text(date, style: .date)
Text(date, format: .dateTime.day().month().year())

// 避免 - 硬编码格式
Text(dateFormatter.string(from: date))
```

## 迁移策略

### 转换硬编码字符串

1. **审查硬编码字符串：**
   ```bash
   # 查找潜在的硬编码用户可见字符串
   grep -r 'Text("' --include="*.swift" .
   grep -r 'Button("' --include="*.swift" .
   grep -r '.alert("' --include="*.swift" .
   ```

2. **创建 TK.App 条目：**
    - 添加到对应的分类扩展中
    - 添加 `///` 文档注释
    - 使用描述性的 key 名称
    - 提供清晰的默认值

3. **在视图中替换：**
   ```swift
   // 之前
   Text("当前体重")

   // 之后
   Text(TK.App.Label.currentWeight)
   ```

4. **构建并验证：**
    - 构建项目以生成 `.xcstrings` 条目
    - 打开 String Catalog 验证 key 已出现
    - 为所有支持的语言添加翻译

### 处理旧版 NSLocalizedString

如果从 `NSLocalizedString` 迁移：
```swift
// 旧模式
NSLocalizedString("key", comment: "描述")

// 新模式
String(localized: "key", defaultValue: "默认值", bundle: .main, comment: "描述")
```

两者都兼容 `.xcstrings`，但 `String(localized:)` 更推荐使用。

## 测试本地化

### 伪本地化

测试字符串长度和布局问题：
1. Xcode -> Product -> Scheme -> Edit Scheme
2. Run -> Options -> App Language -> "Double-Length Pseudo-language"
3. 字符串会翻倍显示，模拟更长的翻译

### 语言测试

1. 模拟器：设置 -> 语言与地区 -> 首选语言
2. Xcode Scheme：Edit Scheme -> Run -> App Language -> 选择语言
3. 验证：
    - 所有字符串都已翻译
    - 没有截断或布局问题
    - 从右到左（RTL）语言正确显示

### 自动化检查
```swift
// 单元测试：确保视图中没有硬编码字符串
func testNoHardcodedStrings() {
    let source = try! String(contentsOfFile: "DashboardView.swift")
    let pattern = #"Text\("[^L]"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
    XCTAssertEqual(matches.count, 0, "Found hardcoded Text strings")
}
```

## 最佳实践总结

**推荐：**
- 按功能/页面组织 TK.App 结构
- 使用 `String(localized:defaultValue:bundle:comment:)` 实现类型安全
- 每个变量添加 `/// "<defaultValue>" - <comment>` 文档注释
- localized key 遵循 `{feature}.{component}.{element}.{property}` 命名规范
- `bundle` 参数根据目标类型选择 `.main` 或 `.module`
- 单独定义无障碍字符串
- 使用函数处理参数化字符串
- 让 Foundation 处理日期/数字格式化
- 使用伪本地化和 RTL 语言进行测试

**禁止：**
- 在视图中直接硬编码面向用户的字符串
- 使用字符串拼接构造句子（会破坏翻译）
- 假设英语语序适用于所有语言
- 跳过无障碍本地化
- 使用 "title1"、"label2" 等通用 key 名称
- localized key 中使用 camelCase（应使用点分隔）
- 添加新 key 后忘记构建项目


## 常见错误

### `default:` 插值标签在 `String(localized:)` 中不可用

`String(localized:defaultValue:)` 的 `defaultValue` 类型为 `String.LocalizationValue`，仅支持 `specifier:` 标签，不支持 `default:` 标签。`default:` 仅在 SwiftUI `Text` 的 `LocalizedStringKey` 插值中有效。

```swift
// 错误：String.LocalizationValue 不支持 default: 标签
// 编译错误：Incorrect argument label in call (have '_:default:', expected '_:specifier:')
String(localized: "key", defaultValue: "value \(x, default: "12")")

// 正确：直接使用插值
String(localized: "key", defaultValue: "value \(x)")

// default: 仅在 SwiftUI Text 中有效
Text("value \(x, default: "12")")  // 这是 LocalizedStringKey，支持 default:
```

### `String(format:)` 应替换为 `String(localized:)`

`String(format:)` 不走本地化系统，应迁移到 `String(localized:)` 参数化方法：

```swift
// 错误：不经过本地化系统
Text(String(format: "姓名：%@ 年龄：%d", name, age))

// 正确：使用 String(localized:) 参数化方法
Text(TK.App.Message.nameAndAge(name, age))
```

### `Any` / `Bool` 等类型不能直接用于本地化插值

`String.LocalizationValue` 内置支持 `String`、`Int`、`Double` 等类型的插值，但 `Any` 和 `Bool` 类型会产生 deprecation 警告。需要使用 `String(describing:)` 显式转换。

```swift
// 警告：Localized string interpolation produces an unlocalized, debug description for this type of value
defaultValue: "test format: \(value)"           // value: Any
defaultValue: "test Bool = \(boolValue)"         // boolValue: Bool

// 正确：使用 String(describing:) 显式转换
defaultValue: "test format: \(String(describing: value))"
defaultValue: "test Bool = \(String(describing: boolValue))"
```

## 工具

### Xcode String Catalog 编辑器
- **筛选：** 按状态搜索/筛选字符串（new、translated、needs_review）
- **批量编辑：** 选择多个字符串标记为已审查
- **导出/导入：** File -> Export/Import Localizations 用于外部翻译

### 命令行
```bash
# 导出用于翻译
xcodebuild -exportLocalizations -project MyApp.xcodeproj -localizationPath ./Localizations

# 导入翻译
xcodebuild -importLocalizations -project MyApp.xcodeproj -localizationPath ./Localizations/zh-Hans.xcloc
```

## 资源

- [Apple 本地化文档](https://developer.apple.com/documentation/xcode/localization)
- [String Catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [WWDC: Discover String Catalogs](https://developer.apple.com/videos/play/wwdc2023/10155/)

## 快速参考

| 任务 | 模式 |
|------|------|
| 简单字符串 | `public static var title: String { String(localized: "TK.App.feature.navigation.title", defaultValue: "Title", bundle: .main, comment: "...") }` |
| 参数化 | `public static func greeting(_ name: String) -> String { String(localized: "TK.App.dashboard.greeting.message", defaultValue: "Hello, \(name)!", bundle: .main, comment: "...") }` |
| 在 SwiftUI 中 | `Text(TK.App.Label.featureTitle)` |
| 导航标题 | `.navigationTitle(TK.App.Label.featureTitle)` |
| 无障碍 | `.accessibilityLabel(TK.App.Label.accessibilityLabel)` |
| 弹窗标题 | `.alert(TK.App.Message.errorTitle, message: ...)` |

---

*本指南提供了 Swift 本地化的通用最佳实践。请根据项目的具体架构和需求进行调整。*
