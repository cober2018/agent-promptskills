---
name: 接口工程
description: 用于以下场景：设计、实现或审查 HTTP/REST/gRPC/GraphQL 接口——涉及路由规范、响应信封、HTTP 状态码、请求校验、错误处理、中间件链路、认证（JWT/OAuth/API Key）以及 WebSocket 实时推送。
---

# 接口工程

## 概述

如何设计并实现健壮、安全、可版本化的 API。**接口即契约——破坏一次，长期买单。**

## 何时使用

- 新增端点、Controller 或 RPC 方法
- 为新功能设计 URL / 路由 / 契约
- 审查接口变更（状态码、错误信封、认证、校验）
- 在 REST / GraphQL / gRPC 之间做技术选型
- 增加中间件、认证、限流、WebSocket
- 排查「为什么返回 4xx / 5xx」

**不要用于：** 内部数据加工（→ `data-engineering`）、数据库 Schema 工作（→ `database-engineering`）。

## 速查表

### URL 规范

| 方法 | 模式 | 用途 |
|---|---|---|
| GET    | `/api/v1/{resource}`        | 列表 |
| GET    | `/api/v1/{resource}/{id}`   | 详情 |
| POST   | `/api/v1/{resource}`        | 创建 |
| PUT    | `/api/v1/{resource}/{id}`   | 全量替换 |
| PATCH  | `/api/v1/{resource}/{id}`   | 部分更新 |
| DELETE | `/api/v1/{resource}/{id}`   | 删除 |

- 名词复数、禁用动词。嵌套 ≤ 2 层，更深用查询参数。
- 分页：优先 `?cursor=...&limit=20`，避免 `?page=1&page_size=20`。

### 响应信封

```json
// 成功
{ "data": { ... },
  "meta": { "timestamp": "...", "request_id": "...",
             "pagination": { "total": 1000, "page": 1, "page_size": 20, "has_next": true } } }

// 失败
{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] },
  "meta": { "timestamp": "...", "request_id": "..." } }
```

### HTTP 状态码速查

| 状态码 | 用途 |
|---|---|
| 200  | OK（GET / PUT / PATCH / DELETE） |
| 201  | Created（POST） |
| 204  | No Content（DELETE） |
| 400  | 参数校验失败 |
| 401  | 未认证 / Token 无效 |
| 403  | 已认证但无权限 |
| 404  | 资源不存在 |
| 409  | 冲突（重复、并发编辑） |
| 422  | 语法正确但语义不合法 |
| 429  | 触发限流（响应头 `Retry-After`） |
| 500  | 服务器错误——**严禁暴露细节** |
| 503  | 维护 / 过载 |

## 核心规则

1. **在边界处校验。** 路由层用 Pydantic / Go validator 白名单校验、拒绝多余字段；Service 与 Repository 不再做校验。
2. **透传 `traceId`。** 入口处生成或继承，下沉到所有日志、下游调用、异步任务；响应头回写 `X-Request-Id`。
3. **gRPC status → HTTP 状态码** 在网关层映射：`codes.NotFound` → 404、`codes.PermissionDenied` → 403 等（完整映射见 `grpc-patterns.md`）。
4. **认证 ≠ 授权。** JWT 解决「你是谁」，还要检查资源级归属（如 `article.author_id == user.id`）。
5. **500 永远不暴露细节。** 堆栈进日志，客户端只见通用消息 + `request_id`。

## 协议选型

| 协议 | 适用 | 避免 |
|---|---|---|
| **REST** | 对外 API、CRUD、前后端联调 | 需要灵活查询形态 |
| **GraphQL** | BFF 层、多端差异化查询 | 直接对外暴露（安全 + 缓存成本） |
| **gRPC** | 服务间通信、延迟敏感、流式 | 浏览器直连（需 gRPC-Web） |

## 中间件执行顺序（外 → 内）

请求 →
1. 请求 ID（traceId）
2. 访问日志
3. CORS
4. 安全响应头（Helmet / FastAPISecurity）
5. 限流
6. 认证（解析 Token）
7. 请求体解析
8. 参数校验
9. 授权
10. 业务处理（Controller → Service）

← 响应
11. 响应格式化
12. 错误处理（全局兜底）
13. 响应日志

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| `POST /createUser`、`GET /getUserById` | 名词复数、禁用动词：`POST /users` |
| 百万行表用 `Offset` 分页 | 游标分页（`?cursor=...&limit=20`） |
| `500 Internal Server Error: TypeError: ...` 暴露堆栈 | 全局处理器返回通用消息 + `request_id` |
| Token 放在 URL 或 query string | `Authorization: Bearer` 头或 `HttpOnly` Cookie |
| 校验逻辑写在 Service / Repository | 仅在 Controller / 路由层校验 |
| `async def` 内调用 `requests.get` | 用 `httpx.AsyncClient` |
| WebSocket 每条消息都鉴权 | 仅在 `accept()` 时鉴权一次 |
| body 内返回 `error` 字段但 HTTP 状态仍是 200 | 用正确的 HTTP 状态码 |
| Pydantic 模型配置 `extra = "allow"` | 配置 `extra = "forbid"` 拒绝未知字段 |
| SPA 用 OAuth Implicit Flow | 改用 Authorization Code + PKCE |
| 废弃 v1 接口未返回 `Sunset` 头 | 设置 `Sunset` ≥ 6 个月，过期后返回 410 |

## WebSocket 与替代方案

| 场景 | 推荐 |
|---|---|
| 服务端主动推送、聊天、协同编辑、实时行情 | **WebSocket** |
| 单向低频通知 | **SSE**（更简单） |
| 偶尔更新、可接受延迟 | **轮询 / 长轮询** |

**WebSocket 关键点：** 每 30s ping/pong 心跳；鉴权在 `accept()` 而非每帧；按业务维度分房间 / 频道；多实例用 Redis Pub/Sub 扇出。

## 版本管理

| 策略 | 评价 |
|---|---|
| URL 路径：`/api/v1/users`、`/api/v2/users` | **推荐** |
| 请求头：`Accept: application/vnd.myapp.v2+json` | 内部窄场景可用 |
| 查询参数：`/api/users?version=2` | **避免** |

- 非破坏性变更（加字段、加端点）→ 不升版本
- 破坏性变更（改字段名、删字段、改语义）→ 必升版本 + 旧版维护 ≥ 6 个月 + `Sunset` 响应头

## 重型参考（拆分文件）

各子主题的完整内容放在同级文件中，本文件作为入口，按需加载对应文件。

- [`rest-design.md`](./rest-design.md) — 完整 URL / 响应 / 状态码规范
- [`fastapi-patterns.md`](./fastapi-patterns.md) — 异步模式、依赖注入、Pydantic `extra="forbid"`
- [`grpc-patterns.md`](./grpc-patterns.md) — Protobuf、状态码映射
- [`middleware.md`](./middleware.md) — 中间件链路、限流、请求 ID
- [`auth.md`](./auth.md) — JWT / OAuth / API Key / RBAC / ABAC
- [`websocket.md`](./websocket.md) — 连接生命周期、房间、扩展

## 产出物清单

- [ ] OpenAPI / Protobuf 契约文件
- [ ] 错误码映射表（HTTP ↔ gRPC）
- [ ] 认证与 Token 管理方案说明
- [ ] 中间件编排链路图
- [ ] WebSocket 实时推送消息协议（如涉及）
