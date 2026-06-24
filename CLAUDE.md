# AGENTS.md

## 环境
### 技术栈
- 语言: Swift 6
- 工程管理: Swift Package Manager（SwiftPM）
- 默认本地化: `zh`
- 支持平台:
  - iOS 17+
  - macOS 15+
- 当前产物: Library `SwiftUIS-InfiniteScrollWithDay`

### 常用命令
- 查看包定义: `swift package describe`
- 构建: `swift build`
- 测试: `swift test`
- 生成 Xcode 工程入口: `open Package.swift`
- 修改 `Package.swift` 后，优先校验 `swift build` 是否通过

## 规范
### 任务规划与跟踪规范（TODO.md）
- 所有任务在开始前必须进行规划（Plan）
- 所有规划结果必须统一记录在项目根目录的 `TODO.md`
- 不允许仅在对话或上下文中存在任务列表，必须落地到文件

#### TODO.md 结构规范
使用 Markdown Checklist 格式：
```markdown
# TODO

## 进行中
- [ ] 实现用户登录功能
- [ ] 完成 Home 页面 UI

## 待办
- [ ] 接入数据库（SharingGRDB）
- [ ] 添加单元测试

## 已完成
- [x] 初始化项目结构（Tuist）
```

### 工程配置规范
- 工程配置优先通过 `Package.swift` 维护，不要手动依赖 Xcode 本地配置
- 新增依赖时，优先使用 SwiftPM 声明式配置
- 所有改动都需要保证项目可通过命令行构建
- 如需增加平台、target、product，必须同步更新 `Package.swift`

### 代码规范
- 优先使用 struct / enum / protocol，非必要避免 class
- 明确访问控制（public / internal / private）
- 禁止使用强制解包（`!`）
- 优先使用 async/await，避免回调地狱
- 完成功能时添加简要的中文注释
- 注释应解释意图或关键约束，避免无意义描述

### Swift 6 规范
- 保持 Swift 6 语义兼容，注意并发隔离与 Sendable 约束
- 出现并发警告时，优先修正设计，而不是规避编译检查
- 涉及共享状态时，明确 actor、`@MainActor` 或其他隔离边界

### 模块设计规范
- 对外 API 保持精简稳定，避免暴露不必要实现细节
- 优先保持 target 内聚，新增功能前先评估是否应拆分子模块
- 公共类型与方法命名需要清晰，避免缩写和语义不明的命名

### Testing 规范
- 新增功能或修复缺陷时，优先补充对应测试
- 至少保证 `swift build` 通过；如存在测试目标，还应保证 `swift test` 通过
- 修复所有：编译错误、测试失败、Swift 6 并发相关问题

### 版本管理规范
- 变更对外 API 或包结构时，需要同步检查文档与版本说明
- 创建 tag 前，需确认文档、构建、测试状态一致

### 项目文档规范
- 文档目录可按项目实际情况增减，但建议保持以下结构

```text
docs/
    ├── 00_CONTEXT.md          # [核心] 项目背景、约束与使用说明
    ├── 01_API_REFERENCE.md    # [核心] 对外 API 与类型说明
    ├── 02_ARCHITECTURE.md     # [进阶] 模块设计与核心实现说明
    ├── 03_GUIDES/             # [实操] 使用示例与场景指南
    │   ├── quick-start.md     # [实操] 必需，快速入门
    └── 04_CHANGELOG.md        # [版本] 版本更新记录
```
