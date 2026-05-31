---
name: test-evidence
description: 测试证据工程能力——测试执行、证据收集（截图/日志/录屏/HAR）、Bug 报告编写、复现步骤、回归验证、测试覆盖度分析。当任务涉及测试执行、Bug 发现与提交、复现验证、回归测试时激活。扩展支持 Playwright 弹性 E2E 测试编写与 Pytest 单元测试桩隔离规范。
---

🧪 测试证据与自动化（Test Evidence & Automation）
核心问题：Bug 存在吗？证据完整吗？自动化脚本足够鲁棒吗？开发看完能直接修吗？


📌 Playwright 高弹性 E2E 自动化规范

  1. 杜绝 Flaky (易碎) 元素定位：
    - 严禁使用动态或极易随页面微调失效的复杂 XPath / CSS Selector（如 `/html/body/div/div[2]/form/div[1]/input`）。
    - 强制首选语义化定位器：
      - `page.get_by_role("button", name="提交")`
      - `page.get_by_label("用户名")`
      - `page.get_by_test_id("start-backtest-btn")` （最推荐，在 React 代码中显式配置 `data-testid`）

  2. 极致的自动等待（Auto-waiting）：
    - 严格杜绝在代码中写入硬编码延迟（如 `time.sleep(3)` 或 `page.wait_for_timeout(3000)`），这是导致 CI/CD 中测试频繁误报的罪魁祸首。
    - 依靠 Playwright 的自动等待机制进行行为动作（`click`, `fill` 会自动等待元素变为 visible, enabled 且 stable）。
    - 对于动态异步加载数据，使用精确断言：`expect(page.get_by_test_id("result-cell")).to_be_visible(timeout=5000)`。

  3. 自动化证据保存（Trace & Artifacts）：
    - 在 CI 流水线中，配置 Playwright 启动全局 Trace 录制：
      ```python
      context = browser.new_context(record_video_dir="videos/", accept_downloads=True)
      context.tracing.start(screenshots=True, snapshots=True, sources=True)
      ```
    - 测试失败时，自动保存：`failure_screenshot.png`、完整录像文件 `video.webm` 以及用于重放交互的 `trace.zip`。


📌 Pytest 单元与集成测试规范

  1. 数据库事务隔离（Transactional Isolation）：
    - 每一个涉及数据库写操作的测试用例，必须由 Pytest Fixture 自动启动一个数据库事务。
    - 测试用例执行完毕后，无论 PASS 还是 FAIL，在 `teardown` 阶段必须强制执行 `db.rollback()`，回滚所有变更，保持数据库物理无污染。
    - 严禁测试用例间共享同一张未回滚的表状态，防止用例间的级联干扰。

  2. 隔离第三方外部调用（Strict Mocking）：
    - 在单元测试中，凡涉及昂贵、缓慢或不可控的外部依赖（如量化数据源 API 调取、三方账户扣款），必须使用 `pytest-mock` 的 `mocker.patch` 进行完全拦截替换。
    - 确保测试套件（Test Suite）不依赖真实网络，支持随时在离线环境下秒级运行完毕。


📌 测试执行流程

  第一步：测试准备
    确认测试环境和版本（build 号、commit hash）
    准备测试数据（前置条件所需的账号、数据状态）
    开启录屏和日志收集工具
    记录环境信息：OS 版本、浏览器版本、设备型号、网络条件

  第二步：测试执行
    按测试用例/自动化脚本逐步执行
    每个步骤都记录实际行为，不只是最终结果
    发现异常时立即截图和保存日志

  第三步：证据收集（发现问题时）
    截图：带标注的关键截图（标注出问题区域）
    录屏：复杂交互问题录制操作视频
    控制台日志：完整的浏览器控制台输出（含错误栈）
    网络请求：相关 API 请求和响应（HAR 文件或截图）
    服务端日志：相关的后端错误日志（含 traceId）

  第四步：复现确认
    多次复现确认问题的稳定性
    记录复现概率：必现（10/10）/ 高概率（7/10）/ 偶现（3/10）
    找到最小复现路径（剔除无关操作）


📌 Bug 报告模板

  Bug Report: [简洁描述问题]

  基本信息：
    严重程度：P0 / P1 / P2 / P3
    所属模块：[模块名]
    发现版本：v2.3.1 (build 456) / commit abc123
    环境：
      OS: macOS 14.2 / iOS 17.1 / Windows 11
      浏览器: Chrome 120.0.6099.71
      设备: iPhone 15 Pro / Desktop 1920x1080

  复现步骤：
    前置条件：
      1. 使用已注册的免费用户账号登录
      2. 运行环境已接入 ClickHouse quant 库
    操作步骤：
      1. 进入"回测"页面
      2. 点击右上角"运行回测"
    实际结果：
      控制台报错：
      TypeError: Cannot read property 'map' of undefined at ProjectList.tsx:45
    期望结果：
      正确启动回测，页面出现运行动画。

  复现概率：必现（10/10 次）

  证据：
    截图：[附带标注的截图]
    控制台日志：[完整错误栈]
    网络请求：
      Response: { "data": null }
      注意：data 字段为 null 而非空数组，前端未处理 null case

  根因定位（如果可以）：
    API 返回 data: null 而非 data: []
    前端 ProjectList.tsx:45 直接调用 data.map() 未做空值判断


📌 Bug 报告质量标准

  必须包含（缺一不可）：
    ✅ 精确的复现步骤（含前置条件）
    ✅ 实际结果 vs 期望结果
    ✅ 严重程度评估
    ✅ 至少一种证据（截图 / 日志 / 录屏 / HAR）


📌 回归验证

  验证流程：
    1. 确认修复版本和修复内容
    2. 按原始 Bug 报告的复现步骤重新执行
    3. 验证问题是否真正修复
    4. 检查修复是否引入新问题（副作用）
    5. 记录验证证据（修复前后对比截图）


📌 测试证据产出物清单
  - Playwright 自动化 E2E 测试用例集与 Trace 追踪归档
  - Pytest 单元与集成测试用例（实现数据库隔离的 Mock 结构）
  - 缺陷报告 Bug Report（附带完整 HAR、网络请求和视觉图示证据）
  - 回归验证通过 PASS / FAIL 记录与对比报告
