# Ordo — 推理中枢

**Ordo** 是面向应用侧的 **多模态推理中枢**：用工作流（DAG）把内部模型服务与外部模型 API 组织起来，并提供 **容量感知调度**、**多部署路由（多云）**、以及 **可观测与流式事件**。

> Ordo 不是“模型 Serving 系统”。  
> Ordo 的定位是 **编排与调度层**：协调多个模型/服务完成一个任务。

---

## ✨ 为什么要做 Ordo？

AI 应用很少只是“调一次模型”，更常见的是流水线：
- LLM → 工具调用 → 生图 → 图生 3D → 后处理
- 内部 GPU 算法服务 + CPU 服务 + 外部 API 混合
- 同一工作流存在多版本 + 多云部署 + 灰度发布

Ordo 希望解决：
- 工作流标准化：每个 stage 的输入/输出/依赖关系明确
- 多部署路由：同一版本可同时在多个机房/云厂商上运行
- 容量保护：B+ 有界队列准入，避免系统被压垮
- 面向应用交付：SYNC / ASYNC / STREAM 三种调用模式
- 可观测：容量、队列、inflight、延迟、成功率

---

## ✅ v0.1 能力

### 工作流 & 执行
- YAML 工作流注册与版本管理：`workflow_id@version`
- DAG 拓扑执行（v0.1 串行执行）
- stage 输入解析：
  - `fromInputs`：来自提交请求 `inputs`
  - `fromStage`：来自上游 stage 产物
- 最终输出映射：从某 stage 的 artifact/metadata 映射到 outputs

### 调度（容量感知）
- 同一 `(workflow_id, version)` 支持多 deployment（多云/多机房）
- 原子准入（不会超卖 inflight）
- B+ 有界队列：`slots` + `queueSize`
- Capacity API：
  - `GET /v1/workflows/{workflow_id}/capacity?version=...`

### 调用方式
- **SYNC**：同步等待结果（适合快任务）
- **ASYNC**：返回 `task_id`，后台执行；可选 HTTP 回调
- **STREAM**：通过 SSE 推送生命周期/进度事件：
  - `GET /v1/executions/{task_id}/stream`

### 插件（v0.1）
- HTTP Executor（调用外部 API 或内部服务）
- Local Executor（用于 demo/测试）
- SSE Output（流式事件通道）

### 可观测
- Prometheus 指标：容量/队列/延迟/成功率等
- Hermetic E2E（不依赖 docker）

---

## 🚀 快速开始

### 1) 启动 Ordo

```bash
go run ./cmd/ordo --config configs/ordo.example.yaml
```

健康检查：

```
curl -s http://localhost:8080/healthz
```

Metrics（如开启）：

```
curl -s http://localhost:8080/metrics | head
```

### 2) 查询容量

```
curl -s "http://localhost:8080/v1/workflows/i23d.pipeline/capacity?version=v2.0" | jq .
```

### 3) 提交任务（SYNC）

```
curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"llm.chat",
    "version":"v1.0",
    "mode":"SYNC",
    "inputs":{
      "provider":"mock",
      "model":"mock-chat",
      "messages":[{"role":"user","content":"你好"}]
    }
  }' | jq .
```

### 4) 提交任务（ASYNC）

```
TASK=$(curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"i23d.pipeline",
    "version":"v2.0",
    "mode":"ASYNC",
    "inputs":{
      "variant":"geom_texture",
      "images":["mock://a.png","mock://b.png"],
      "target_format":"glb"
    }
  }' | jq -r .task_id)

curl -sS http://localhost:8080/v1/executions/$TASK | jq .
```

### 5) 提交任务（STREAM / SSE）

```
TASK=$(curl -sS -X POST http://localhost:8080/v1/executions \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id":"llm.chat",
    "version":"v1.0",
    "mode":"STREAM",
    "inputs":{
      "provider":"mock",
      "model":"mock-chat",
      "messages":[{"role":"user","content":"请流式输出"}]
    }
  }' | jq -r .task_id)

curl -N http://localhost:8080/v1/executions/$TASK/stream
```

------

## 📚 文档导航

- 🧪 Demo：`docs/demo.md`
- ❓ FAQ：`docs/faq.md`
- 📈 可观测：`docs/observability.md`
- 🏗️ 架构与概念：
  - `docs/architecture.md`
  - `docs/concepts.md`
  - `docs/plugins.md`
  - `docs/integrations.md`
- 🗺️ Roadmap：`ROADMAP.md`
- 🏷️ v0.1 Release Notes：`release-notes-v0.1.md`

------

## 🧭 架构概览

```
flowchart TB
  Client[调用方 / 应用] -->|查容量| OrdoAPI[Ordo API]
  Client -->|提交 SYNC/ASYNC/STREAM| OrdoAPI

  subgraph Ordo[Ordo Core]
    OrdoAPI --> ExecSvc[Execution Service]
    OrdoAPI --> Sched[Scheduler]
    ExecSvc --> Store[Execution Store]
    Sched --> Route[Routing Policy]
    Sched --> Q[Bounded Queue]
    ExecSvc --> Engine[Engine]
    Engine --> Resolver[Input Resolver]
    Engine --> ExecMgr[Executor Manager]
    Engine --> Obs[Observability]
  end

  ExecMgr -->|HTTP| ExtAPI[外部模型 API]
  ExecMgr -->|HTTP| InternalSvc[内部算法服务]
  ExecMgr -->|Local| LocalExec[本地 Executor（Demo/Test）]

  OrdoAPI -->|SSE| Stream[SSE Output 插件]
  Obs -->|/metrics| Prom[Prometheus]
```

------

## ⏱️ 时序图

### SYNC 同步执行

```
sequenceDiagram
  participant C as 调用方
  participant A as Ordo API
  participant S as Scheduler
  participant E as Engine
  participant X as Executor

  C->>A: POST /v1/executions (mode=SYNC)
  A->>S: RouteAndAdmit()
  S-->>A: accepted
  A->>E: Run(task_id)
  E->>X: Execute(stage1..n)
  X-->>E: outputs
  E-->>A: terminal + outputs
  A-->>C: 执行结果
```

### ASYNC + 有界队列

```
sequenceDiagram
  participant C as 调用方
  participant A as Ordo API
  participant S as Scheduler
  participant E as Engine

  C->>A: POST /v1/executions (mode=ASYNC)
  A->>S: RouteAndAdmit()
  alt slots 有空闲
    S-->>A: accepted
    A-->>C: {task_id}
    A->>E: Run(task_id)
  else slots 满且队列未满
    S-->>A: queued
    A-->>C: {task_id}
    Note over S: 等待 release 后 dequeue 执行
  else 队列已满
    S-->>A: rejected (409)
    A-->>C: 409 无容量
  end
```

### STREAM（SSE 事件）

```
sequenceDiagram
  participant C as 调用方
  participant A as Ordo API
  participant E as Engine
  participant SSE as SSE Hub

  C->>A: POST /v1/executions (mode=STREAM)
  A-->>C: {task_id}
  C->>A: GET /v1/executions/{task_id}/stream
  A->>SSE: subscribe
  E->>SSE: start/stage/final events
  SSE-->>C: SSE events
```

------

## 🔍 与 Argo / Dify 的关系

### Argo Workflows

Argo 是通用的 K8s 工作流引擎。Ordo 更聚焦于应用侧推理语义：

- inference-centric 的输入/产物抽象（params + artifacts）
- 同一版本多 deployment 的多云路由
- 有界队列准入控制（保护 SLA）
- 面向应用的 SYNC/ASYNC/STREAM 调用形态

未来 Ordo 可以把 Argo 作为某类 workflow/executor 插件来集成。

### Dify

Dify 更偏 LLM 应用搭建与管理。Ordo 更偏执行/调度/容量控制：

- Ordo 可作为 Dify 的底层执行层
- Ordo 提供多模态流水线、容量控制、可观测

------

## 🔐 Ordo开源版与企业内部使用

Ordo开源版提供稳定的 **Core + 插件框架**。企业可将核心资产私有化：

- 私有工作流（真实 3D 流水线）
- 私有 executor 插件（GPU 推理服务）
- 私有 routing 策略与 integrations

开源版只提供安全 demo（如 llm.chat、t2i → i23d 的示例）。

------

## 🧪 测试

```
make test
make e2e
```

------

## 📄 License

见 `LICENSE`。