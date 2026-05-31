---
name: api-engineering
description: API 工程能力——REST/GraphQL/gRPC 接口设计与实现、中间件模式、错误处理、认证授权、请求校验、WebSocket 实时推送、API 版本管理。当任务涉及接口开发、中间件编写、认证实现、实时通信时激活。
---

🔌 API 工程（API Engineering）
核心问题：接口怎么设计？怎么实现得健壮？怎么保证安全？


📌 API 设计规范

  RESTful 设计约定：
    URL 用名词复数，不用动词：
      ✅ GET /api/v1/users         获取用户列表
      ✅ GET /api/v1/users/123     获取单个用户
      ✅ POST /api/v1/users        创建用户
      ✅ PUT /api/v1/users/123     全量更新用户
      ✅ PATCH /api/v1/users/123   部分更新用户
      ✅ DELETE /api/v1/users/123  删除用户
      ❌ POST /api/v1/createUser
      ❌ GET /api/v1/getUserById

    嵌套资源（表达从属关系）：
      GET /api/v1/users/123/orders         用户 123 的订单列表
      GET /api/v1/users/123/orders/456     用户 123 的订单 456
      嵌套不超过 2 层，更深的用查询参数或独立端点

    查询参数约定：
      分页：?page=1&page_size=20  或  ?cursor=xxx&limit=20（推荐游标分页）
      排序：?sort=created_at&order=desc
      过滤：?status=active&category=electronics
      字段选择：?fields=id,name,price（减少传输量）

  通用响应格式：
    成功响应：
      {
        "data": { ... },               单个对象或数组
        "meta": {
          "timestamp": "...",           响应时间
          "request_id": "...",          请求追踪 ID
          "pagination": {               仅列表接口
            "total": 1000,
            "page": 1,
            "page_size": 20,
            "has_next": true
          }
        }
      }

    错误响应：
      {
        "error": {
          "code": "VALIDATION_ERROR",   机器可读的错误码
          "message": "邮箱格式不正确",    人类可读的消息
          "details": [                   具体的校验错误（可选）
            { "field": "email", "reason": "格式不正确" }
          ]
        },
        "meta": {
          "timestamp": "...",
          "request_id": "..."
        }
      }

  HTTP 状态码使用规范：
    200 OK              → 成功（GET、PUT、PATCH、DELETE）
    201 Created         → 创建成功（POST）
    204 No Content      → 成功但无返回体（DELETE）
    400 Bad Request     → 请求参数错误、校验失败
    401 Unauthorized    → 未认证（没有 Token 或 Token 无效）
    403 Forbidden       → 已认证但无权限
    404 Not Found       → 资源不存在
    409 Conflict        → 资源冲突（重复创建、并发修改）
    422 Unprocessable   → 语法正确但语义错误（业务规则不允许）
    429 Too Many Reqs   → 触发限流
    500 Internal Error  → 服务器内部错误（绝不暴露细节）
    503 Service Unavail → 服务暂时不可用（维护、过载）


📌 协议选型

  REST
    适用：对外 API、前后端交互、简单 CRUD
    优点：通用、易调试、生态丰富
    缺点：over-fetching / under-fetching

  GraphQL
    适用：前端需要灵活查询、多端差异化、数据关系复杂
    优点：客户端按需取数据、强类型 Schema
    缺点：缓存困难、N+1 需要 DataLoader、安全需要查询深度限制
    何时用：BFF 层，不建议直接暴露给公网

  gRPC
    适用：服务间通信、高性能内部调用、流式通信
    优点：二进制协议快、强类型（Protobuf）、双向流
    缺点：调试不直观、浏览器支持需要 gRPC-Web
    何时用：微服务内部调用、对延迟敏感的场景


📌 中间件设计模式

  中间件执行顺序（从外到内）：
    请求 →
      1. 请求 ID 生成（traceId）
      2. 访问日志记录
      3. CORS 处理
      4. 安全头设置（Helmet）
      5. 限流
      6. 认证（解析 Token）
      7. 请求体解析（JSON / multipart）
      8. 请求校验（参数/Body 校验）
      9. 授权（权限检查）
      10. 业务处理（Controller → Service）
    ← 响应
      11. 响应格式化
      12. 错误处理（全局异常捕获）
      13. 响应日志记录

  关键中间件实现要点：

    请求 ID（traceId）：
      每个请求生成唯一 ID（UUID v4）
      如果上游传了 X-Request-Id 则复用
      全链路透传：日志、下游调用、消息队列
      响应头返回 X-Request-Id 方便排查

    限流中间件：
      按 IP 限流：防刷接口（登录、注册、短信验证码）
      按用户限流：防止单用户滥用
      按 API 限流：保护特定的昂贵接口
      返回 429 + Retry-After 头

    请求校验：
      在 Controller 入口处校验，不在 Service 里校验
      校验失败立即返回 400，不执行任何业务逻辑
      校验规则与业务逻辑分离（声明式校验 > 命令式校验）
      白名单校验：只接受已知字段，忽略或拒绝未知字段


📌 认证与授权

  认证（Authentication）— 你是谁？

    JWT（JSON Web Token）：
      适用：无状态认证，服务间传递用户信息
      Access Token：短期有效（15-30 分钟）
      Refresh Token：长期有效（7-30 天），用于刷新 Access Token
      存储：Access Token 存内存/Cookie（HttpOnly），Refresh Token 存 Cookie（HttpOnly + Secure）
      注意：JWT 签发后无法撤销 → 需要 Token 黑名单（Redis）处理强制登出

    OAuth 2.0 / OIDC：
      适用：第三方登录、开放平台
      Authorization Code Flow（推荐）：用于服务端应用
      PKCE 扩展：用于 SPA 和移动应用
      不要用 Implicit Flow（已弃用，不安全）

    API Key：
      适用：服务间调用、第三方集成
      通过请求头传递（X-API-Key），不放在 URL 中
      每个客户端独立的 Key，可单独吊销
      配合限流使用

  授权（Authorization）— 你能做什么？

    RBAC（基于角色）：
      用户 → 角色 → 权限
      适用：权限模型简单、角色固定的系统
      示例：admin 可以删除用户，editor 可以编辑文章，viewer 只能查看

    ABAC（基于属性）：
      基于用户属性、资源属性、环境属性的策略
      适用：权限模型复杂、需要细粒度控制
      示例：用户只能修改自己创建的订单，且订单状态为"待处理"

    资源级权限检查（最常被遗漏的）：
      不只检查"用户有没有权限做这个操作"
      还要检查"用户有没有权限操作这个具体资源"
      ❌ 只检查 user.role === 'editor'
      ✅ 还要检查 article.author_id === user.id


📌 错误处理

  全局错误处理策略：

    业务异常（可预期的）：
      创建自定义异常类，携带错误码
      在 Service 层抛出，在 Controller 层或全局处理器捕获
      返回 4xx + 明确的错误码和消息

    系统异常（不可预期的）：
      全局异常处理器兜底
      记录完整错误栈到日志（含 traceId）
      返回 500 + 通用消息，不暴露内部细节
      触发告警

    第三方依赖异常：
      超时：设置合理超时，返回降级响应或 503
      格式异常：防御式解析，不信任外部返回值
      限流：读取 Retry-After 头，实现退避重试


📌 WebSocket / 实时推送

  何时用 WebSocket：
    需要服务端主动推送（聊天、通知、实时协作）
    双向通信（在线游戏、协同编辑）
    高频数据更新（实时行情、监控面板）

  何时不用 WebSocket：
    单向低频通知 → SSE（Server-Sent Events）更简单
    偶尔的更新查询 → 轮询或长轮询够用
    可以接受延迟 → 改用消息队列 + 推送服务

  WebSocket 实现要点：
    连接管理：心跳检测（ping/pong 每 30s），超时断开
    消息格式：JSON，带 type 字段区分消息类型，带序列号保证有序性
    重连策略：客户端断线后指数退避重连，带最大重试次数
    鉴权：连接时通过 Token 认证，不在每条消息里带 Token
    房间/频道：按业务维度分组（订单频道、聊天室），避免广播风暴
    扩展性：多实例时用 Redis Pub/Sub 做消息分发


📌 API 版本管理

  版本策略：
    URL 路径版本（推荐）：/api/v1/users、/api/v2/users
    请求头版本：Accept: application/vnd.myapp.v2+json
    查询参数版本：/api/users?version=2（不推荐）

  版本升级原则：
    非破坏性变更（加字段、加端点）→ 不需要升版本
    破坏性变更（改字段名、删字段、改语义）→ 必须升版本
    旧版本至少维护 6 个月，给客户端迁移时间
    废弃版本返回 Sunset 头，提前通知


📌 API 工程产出物清单
  API 契约文档（OpenAPI / Protobuf 定义）
  错误码表（码、含义、HTTP 状态码、处理建议）
  认证授权方案文档
  中间件链配置说明
  WebSocket 消息协议定义（如有）
  API 变更日志（CHANGELOG）
