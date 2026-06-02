---
name: 测试证据工程
description: 用于以下场景：测试执行与证据收集——涉及 Playwright 弹性 E2E 自动化、Pytest 数据库事务隔离与 Mock 规范、Bug 报告编写、复现步骤、回归验证、测试覆盖度分析。任务涉及测试执行、Bug 发现与提交、复现验证、回归测试时激活。
---

# 测试证据工程

## 概述

Bug 存在吗？证据完整吗？**开发看完能直接修吗？** 没有截图的 Bug 报告就是无效反馈，没有稳定定位器的 E2E 就是定时炸弹。

## 何时使用

- Playwright E2E 自动化脚本编写（弹性定位、自动等待、Trace 录制）
- Pytest 单元 / 集成测试（数据库事务隔离、Mock 规范）
- 测试执行与证据收集（截图、日志、录屏、HAR）
- Bug 报告编写（标准模板 + 复现步骤）
- 回归验证
- 测试覆盖度分析

**不要用于：** 性能压测门禁（用 `quality-gate`）、发版就绪性评估（用 `quality-gate`）、代码 review（用 `code-reviewer` agent）。

## Playwright 高弹性 E2E 自动化

### 1. 杜绝 Flaky（易碎）元素定位

**严禁：** 动态或极易随页面微调失效的复杂 XPath / CSS Selector（如 `/html/body/div/div[2]/form/div[1]/input`）。

**强制首选语义化定位器：**

| 定位器 | 适用 |
|---|---|
| `page.get_by_role("button", name="提交")` | 按钮、链接等语义化元素 |
| `page.get_by_label("用户名")` | 表单字段 |
| `page.get_by_test_id("start-backtest-btn")` | 最推荐，在 React 代码中显式配置 `data-testid` |

### 2. 极致的自动等待（Auto-waiting）

**严禁：** 在代码中写入硬编码延迟（如 `time.sleep(3)` 或 `page.wait_for_timeout(3000)`）——这是 CI/CD 中测试频繁误报的罪魁祸首。

| 等待策略 | 适用 |
|---|---|
| 行为动作自动等待 | `click`、`fill` 会自动等待元素变为 visible、enabled 且 stable |
| 精确断言等待 | 动态异步加载数据用 `expect(page.get_by_test_id("result-cell")).to_be_visible(timeout=5000)` |

### 3. 自动化证据保存（Trace & Artifacts）

CI 流水线中，配置 Playwright 启动全局 Trace 录制：

```python
context = browser.new_context(record_video_dir="videos/", accept_downloads=True)
context.tracing.start(screenshots=True, snapshots=True, sources=True)
```

**测试失败时自动保存：**

| 证据 | 文件 |
|---|---|
| 失败截图 | `failure_screenshot.png` |
| 完整录像 | `video.webm` |
| 重放交互 | `trace.zip` |

## Pytest 单元与集成测试

### 1. 数据库事务隔离（Transactional Isolation）

| 原则 | 说明 |
|---|---|
| 事务包裹 | 涉及数据库写操作的测试用例，必须由 Pytest Fixture 自动启动一个数据库事务 |
| 强制回滚 | 测试用例执行完毕后，无论 PASS 还是 FAIL，`teardown` 阶段必须强制执行 `db.rollback()`，保持数据库物理无污染 |
| 禁止共享 | 严禁测试用例间共享同一张未回滚的表状态 |

### 2. 隔离第三方外部调用（Strict Mocking）

| 原则 | 说明 |
|---|---|
| 强制 Mock | 涉及昂贵、缓慢或不可控的外部依赖（量化数据源 API、三方账户扣款）必须使用 `pytest-mock` 的 `mocker.patch` 完全拦截 |
| 离线可运行 | 测试套件（Test Suite）不依赖真实网络，支持随时在离线环境下秒级运行完毕 |

## 测试执行流程

### 第一步：测试准备

| 项目 | 内容 |
|---|---|
| 环境版本 | 确认测试环境和版本（build 号、commit hash） |
| 测试数据 | 准备测试数据（前置条件所需的账号、数据状态） |
| 录屏日志 | 开启录屏和日志收集工具 |
| 环境信息 | OS 版本、浏览器版本、设备型号、网络条件 |

### 第二步：测试执行

| 原则 | 说明 |
|---|---|
| 逐步执行 | 按测试用例 / 自动化脚本逐步执行 |
| 记录行为 | 每个步骤都记录实际行为，不只是最终结果 |
| 异常处理 | 发现异常时立即截图和保存日志 |

### 第三步：证据收集（发现问题时）

| 证据类型 | 内容 |
|---|---|
| 截图 | 带标注的关键截图（标注出问题区域） |
| 录屏 | 复杂交互问题录制操作视频 |
| 控制台日志 | 完整的浏览器控制台输出（含错误栈） |
| 网络请求 | 相关 API 请求和响应（HAR 文件或截图） |
| 服务端日志 | 相关的后端错误日志（含 traceId） |

### 第四步：复现确认

| 项目 | 内容 |
|---|---|
| 多次复现 | 多次复现确认问题的稳定性 |
| 概率记录 | 必现（10/10）/ 高概率（7/10）/ 偶现（3/10） |
| 最小路径 | 找到最小复现路径（剔除无关操作） |

## Bug 报告模板

```markdown
# Bug Report: [简洁描述问题]

## 基本信息
- 严重程度：P0 / P1 / P2 / P3
- 所属模块：[模块名]
- 发现版本：v2.3.1 (build 456) / commit abc123
- 环境：
  - OS: macOS 14.2 / iOS 17.1 / Windows 11
  - 浏览器: Chrome 120.0.6099.71
  - 设备: iPhone 15 Pro / Desktop 1920x1080

## 复现步骤

### 前置条件
1. 使用已注册的免费用户账号登录
2. 运行环境已接入 ClickHouse quant 库

### 操作步骤
1. 进入"回测"页面
2. 点击右上角"运行回测"

### 实际结果
控制台报错：
TypeError: Cannot read property 'map' of undefined at ProjectList.tsx:45

### 期望结果
正确启动回测，页面出现运行动画。

## 复现概率
必现（10/10 次）

## 证据
- 截图：[附带标注的截图]
- 控制台日志：[完整错误栈]
- 网络请求：Response: { "data": null }
  - 注意：data 字段为 null 而非空数组，前端未处理 null case

## 根因定位（如果可以）
API 返回 data: null 而非 data: []
前端 ProjectList.tsx:45 直接调用 data.map() 未做空值判断
```

## Bug 报告质量标准

**必须包含（缺一不可）：**

| 要素 | 说明 |
|---|---|
| ✅ 精确的复现步骤 | 含前置条件 |
| ✅ 实际结果 vs 期望结果 | 明确对比 |
| ✅ 严重程度评估 | P0 / P1 / P2 / P3 |
| ✅ 至少一种证据 | 截图 / 日志 / 录屏 / HAR |

## 回归验证流程

1. 确认修复版本和修复内容
2. 按原始 Bug 报告的复现步骤重新执行
3. 验证问题是否真正修复
4. 检查修复是否引入新问题（副作用）
5. 记录验证证据（修复前后对比截图）

## 严重程度定义

| 级别 | 含义 | 示例 |
|---|---|---|
| **P0** | 阻塞核心流程，必须立即修复 | 主流程崩溃、数据丢失、核心功能不可用 |
| **P1** | 重要功能异常，影响主要使用 | 关键按钮失效、数据计算错误 |
| **P2** | 非核心功能异常或体验问题 | 边界条件报错、UI 错位 |
| **P3** | 轻微问题或建议 | 文案错别字、图标样式 |

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 用复杂 XPath / CSS Selector | 用 `get_by_role` / `get_by_label` / `get_by_test_id` |
| 硬编码 `time.sleep(3)` 等延迟 | 用 Playwright 自动等待或 `expect(...).to_be_visible()` |
| 测试失败不保存 Trace | CI 必开 Trace，失败自动保存截图 + 视频 + trace.zip |
| 测试用例共享未回滚的表状态 | 强制 Fixture 事务 + teardown rollback |
| 外部 API 不 Mock | 涉及网络的测试必须 `mocker.patch` 拦截 |
| Bug 报告没有复现步骤 | 必须含前置条件 + 操作步骤 + 实际 / 期望结果 |
| Bug 报告没有证据 | 至少附一种证据（截图 / 日志 / 录屏 / HAR） |
| Bug 报告没有严重程度 | 强制标注 P0 / P1 / P2 / P3 |
| 回归只看"已修复" | 必须检查修复是否引入新问题（副作用） |
| 偶现 Bug 不记录概率 | 标注必现 / 高概率 / 偶现 比例 |

## 产出物清单

- [ ] Playwright 自动化 E2E 测试用例集与 Trace 追踪归档
- [ ] Pytest 单元与集成测试用例（实现数据库隔离的 Mock 结构）
- [ ] 缺陷报告 Bug Report（附带完整 HAR、网络请求和视觉图示证据）
- [ ] 回归验证通过 PASS / FAIL 记录与对比报告
- [ ] 测试覆盖度分析报告
