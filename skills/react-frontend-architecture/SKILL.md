---
name: React 前端架构
description: 用于以下场景：React 19 / Next.js App Router 现代前端架构——涉及 React Server Components、Zustand 状态收敛、TanStack Query 数据流、性能优化、WCAG 2.1 AA 无障碍。任务涉及 React 组件、Next.js 页面、状态管理、性能优化时激活。
---

# React 前端架构

## 概述

你厌恶滥用 `useEffect` 的面条代码。**Server Components 优先、状态收敛、服务端缓存、极致性能。** 这是现代 React 架构的四大铁律。

## 何时使用

- React 19 / Next.js App Router 页面与组件设计
- React Server Components (RSC) 范式选择
- Zustand 客户端状态管理
- TanStack Query 服务端状态同步
- 性能优化（View Transitions、记忆化、代码分割）
- WCAG 2.1 AA 无障碍访问
- 复合组件（Compound Components）模式

**不要用于：** UI 视觉设计（用 `frontend-design` agent）、后端 API 设计（用 `api-engineering`）、数据可视化（用对应图表库技能）、Tailwind 配置（用 `frontend-engineer` agent）。

## 核心架构范式

### Server Components 优先（RSC）

React Server Components 是 Next.js / React 生态的最大范式转换。**默认所有组件都是服务端组件（无交互状态）。**

| 原则 | 说明 |
|---|---|
| 叶子节点 | 只在树的叶子节点使用 `"use client"` |
| 数据获取 | Server Components 中直接 `async/await` 获取数据，避免客户端网络请求瀑布流 |
| 体积优化 | 大型依赖库（Markdown 解析器、图表引擎核心）应当留在 Server Components，不要打包给客户端 |

```tsx
// ✅ 服务端组件获取数据，客户端组件仅负责交互
export default async function Dashboard() {
  const data = await db.query('...'); // 直接在服务端查库

  return (
    <div>
      <MetricsDisplay data={data.metrics} />      {/* 服务端渲染 */}
      <InteractiveChart initialData={data.chart} /> {/* 标记了 "use client" */}
    </div>
  );
}
```

### Next.js App Router 模式

| 特性 | 用途 |
|---|---|
| `layout.tsx` | 嵌套布局，实现无需重绘的外层导航 |
| `loading.tsx` / `<Suspense>` | 流式渲染，核心部分立即呈现，耗时模块异步流式传输 |
| `error.tsx` | 错误隔离，捕获服务端和客户端崩溃，防止全站白屏 |

## 状态管理与数据流

### 客户端状态收敛（Zustand）

摒弃繁琐的 Redux 样板代码，使用 Zustand 构建轻量、原子化的客户端全局状态。

| 原则 | 说明 |
|---|---|
| 分离 Store | 按业务领域分离 Store，避免巨型对象（如 `useAuthStore`、`useUIStore`） |
| Selector 模式 | **必须**通过 selector 获取状态，防止不必要的组件重新渲染 |
| 状态不重复 | 能通过派生计算得出的数据，绝对不要存入 Store |

```tsx
// ✅ Zustand 最佳实践：细粒度与 Selector
const useMarketStore = create<MarketState>()((set) => ({
  symbols: [],
  activeSymbol: null,
  setActive: (sym) => set({ activeSymbol: sym }),
}));

// 组件内：只订阅需要的值
const activeSymbol = useMarketStore((state) => state.activeSymbol);
```

### 服务端状态同步（TanStack Query）

客户端不需要管理来自 API 的异步状态（Loading / Error / Cache）。**这些不是"客户端状态"，而是"服务端缓存"。**

| 原则 | 说明 |
|---|---|
| 用 `useQuery` / `useMutation` | 凡是来自网络的异步数据，一律使用这两个 Hook |
| 拒绝 `useEffect` + `useState` 取数 | 坚决不写这种取数逻辑 |
| Query Key 依赖关系 | 利用 Query Key 建立依赖，实现数据自动失效与刷新 |

## React 19 Hooks

| Hook | 用途 |
|---|---|
| `useActionState` | 替代传统表单提交，天然处理 Pending 状态 |
| `useOptimistic` | 在服务端响应前先展示"乐观"结果，提供极致丝滑体验 |

## 严打 `useEffect` 滥用

`useEffect` 是同步系统之外的后门，**不是生命周期回调。**

| 反模式 | 正确做法 |
|---|---|
| ❌ `useEffect` 中根据 props 变化 `setXXX`（引发多余渲染） | ✅ 渲染阶段直接计算派生状态，或用 `key` 让组件卸载重置 |
| ❌ `useEffect` 中 `fetch` + `setState` | ✅ Server Components 取数或 TanStack Query |
| ❌ `useEffect` 中订阅全局事件 | ✅ Zustand / Context 订阅 |

## 组件组合模式

消除 "Prop Drilling"（多层级属性传递）和拥有 20 个布尔值的"上帝组件"。

| 模式 | 适用 |
|---|---|
| **复合组件 (Compound Components)** | 如 `<Tabs><Tabs.List><Tabs.Tab /></Tabs.List></Tabs>` |
| **Slot 模式 / Children** | 把子组件作为属性传入，让父级控制外壳 |

## 极致性能优化

| 手段 | 说明 |
|---|---|
| 记忆化约束 | 不用无脑套 `useMemo` / `useCallback`，只在向下传递给被 `React.memo` 包裹的昂贵子组件时使用 |
| View Transitions API | 利用 CSS + React 实现类原生平滑路由切换 |

```css
::view-transition-old(root),
::view-transition-new(root) {
  animation-duration: 0.3s;
}
```

## WCAG 2.1 AA 无障碍访问

企业级 / 公共产品**必须**通过 A11y 审核。

| 检查项 | 标准 |
|---|---|
| 键盘导航 | 页面核心功能必须能仅用 `Tab` / `Enter` / `Space` / `Arrow` 键完成 |
| Focus Trap | 弹出层（Modal）打开时，焦点必须捕获在层内 |
| ARIA 动态区域 | 动态区域使用 `aria-live="polite"` 播报变更 |
| ARIA 控件 | 下拉框用 `aria-expanded`，单选框组用 `role="radiogroup"` |
| 色彩对比度 | 正文文本对比度 ≥ 4.5:1；大字与控件边缘 ≥ 3:1 |
| 状态区分 | 禁用状态不仅靠颜色区分，应增加视觉模式 |

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 全用 `"use client"` | 默认 Server Components，只在交互叶子节点加 `"use client"` |
| 在 `useEffect` 中 fetch 数据 | Server Components 取数 或 TanStack Query |
| Zustand 不分 Store 全部塞一起 | 按业务领域分离 Store |
| 不用 Selector 直接解构整个 Store | 必须 `useStore((s) => s.field)` 选择性订阅 |
| 把服务端 API 数据存入 Zustand | 服务端数据用 TanStack Query 缓存，不进 Zustand |
| 用 `useEffect` 同步 props 到 state | 直接在渲染阶段计算派生状态，或用 `key` |
| 无脑套 `useMemo` / `useCallback` | 只在传递给 `React.memo` 子组件时使用 |
| 20 个布尔值的"上帝组件" | 复合组件 / Slot 模式拆分 |
| Modal 打开不锁焦点 | 用 Focus Trap 防止 Tab 逃逸 |
| 禁用状态只靠颜色区分 | 颜色 + 视觉模式双重区分 |
| 动态更新无 `aria-live` | 动态区域必须有 `aria-live="polite"` 播报 |

## 产出物清单

- [ ] 组件 / 页面代码：基于 RSC、Tailwind 和类型安全的 `.tsx` 文件
- [ ] Store 定义：使用 Zustand / TanStack Query 封装的无头（Headless）状态逻辑
- [ ] 路由结构：`app/` 目录下的 `layout.tsx`、`page.tsx`、`loading.tsx`、`error.tsx`
- [ ] 优化报告：指出组件中引发不必要渲染的瓶颈及修复方案
- [ ] A11y 自检报告：键盘导航、ARIA、色彩对比度
