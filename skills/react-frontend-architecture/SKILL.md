---
name: react-frontend-architecture
description: 前端架构与 React 开发能力——现代 React 19 生态、Zustand 状态管理、Tailwind CSS/Radix UI 样式体系、无障碍（WCAG）规范、高性能首屏加载及 View Transitions API 动画实现。当涉及前端UI开发、样式美化、状态管理设计、动效优化或无障碍审计时激活。
---

🎨 前端架构与 React 工程（React Frontend Architecture）
核心问题：如何构建结构清晰、极致美观、响应迅捷且高无障碍的 React 前端应用？


📌 React 19 与状态设计规范

  1. 状态共置（State Colocation）：
    - 绝不在全局 State 中存储只在局部使用的临时变量（如 `is_open`, `loading_state`）。
    - 状态应当声明在与其消费组件最接近的地方，避免无谓的父级重绘（Re-render）。

  2. 依赖精简与副作用控制：
    - 严格控制 `useEffect` 的使用，绝不用 `useEffect` 来同步状态或派生数据（优先在渲染期间直接计算 `const derivedState = list.filter(...)`）。
    - 副作用操作（如数据提交）统一封装在 Event Handler 或 React 19 的 Actions 中。

  3. 充分利用 React 19 现代 Hooks：
    - `useActionState`：自动管理表单提交的 `pending` 状态、错误处理与乐观更新。
    - `useOptimistic`：实现超敏捷的乐观更新体验，如用户点赞、提交删除后即刻反馈 UI，后台静默运行。


📌 极致 UI/UX 与样式规范（Tailwind & Headless）

  1. 间距与布局法则：
    - 严格遵循严格的间距 Scale（4px 倍数：`p-1`=4px, `p-2`=8px, `p-4`=16px, `p-8`=32px），严禁使用 ad-hoc 的自定义间距值。
    - 优先使用 CSS Grid 或 Flexbox 构建三栏式、 Bento-grid 等现代灵动式布局。

  2. 配色与时尚暗色模式：
    - 主色调选用 HSL 调和的冷调靛蓝（Indigo）、翡翠绿（Emerald）与极客板岩灰（Slate）渐变，杜绝刺眼红蓝配。
    - 暗色模式背景使用 `bg-slate-900` / `bg-zinc-950`，卡片配合 `backdrop-blur-md bg-white/5 border border-white/10` 玻璃魔态（Glassmorphism）质感，展现卓越的 premium 感觉。

  3. 交互与微动效（Micro-interactions）：
    - 所有按钮、链接、卡片必须具备平滑的 `transition-all duration-200 ease-out` 状态过渡。
    - 使用 View Transitions API 构建页面级过渡动画：
      ```css
      @keyframes fade-in {
        from { opacity: 0; transform: translateY(10px); }
      }
      ::view-transition-new(root) {
        animation: 300ms cubic-bezier(0.4, 0, 0.2, 1) both fade-in;
      }
      ```


📌 Web 无障碍（WCAG）与测试辅助

  1. 语义化 HTML：
    - 必须合理运用语义标记。
    - 按钮必须有文字或 `aria-label`。图片必须有 `alt` 属性。
  
  2. 自动化定位契约：
    - 所有核心可交互元素必须指定唯一的 `data-testid` 属性，以确保 QA 工程师能通过 Playwright 弹无虚发定位。
    - 示例：`<button data-testid="start-backtest-btn">启动回测</button>`


📌 产出物清单
  - 高可复用 React 组件库代码
  - 响应式 UI 适配测试报告（Sm/Md/Lg）
  - Lighthouse 性能/无障碍审计报告（目标均 > 90）
