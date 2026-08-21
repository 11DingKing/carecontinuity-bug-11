# CareContinuity 传染病防治服务连续性平台

CareContinuity 面向国家项目管理员、区域防治协调员、社区服务机构、实验室协调员和资金审计人员，保障 HIV 与病毒性肝炎的预防、检测、治疗转介、母婴阻断和社区随访服务在资金收缩或资源短缺时仍能持续运行。平台把服务缺口从发现、分派、补位推进到复核关闭，并跟踪样本和防治物资的跨区域交接。

## 业务流程

- 区域协调员登记社区服务站、覆盖人群和承接机构。
- 社区服务机构报告检测能力下降、转介中断、抗病毒药品保障不足或母婴阻断随访缺口。
- 国家项目管理员根据资金计划和服务优先级分派补位责任，承接机构提交恢复证据。
- 区域或实验室协调员复核服务能力，达标后关闭缺口，不达标则退回继续补位。
- 实验室样本、检测试剂和药品按区域路线生成交接批次，双端签收、异常处置和审计记录均持久化。
- 每次状态变化写入审计记录，后台任务负责超期提醒、失败重试和永久失败记录。

服务缺口状态流转为 `open -> assigned -> rectified -> verified`，复核不合格时回到 `rejected -> assigned`。所有写操作经过真实 SQLite 事务和版本控制，服务重启后可恢复站点、缺口、样本交接、资金台账、审计和会话数据。

## 身份与权限

内置演示账号：`national_admin/national-admin-demo`、`regional_coordinator/regional-coordinator-demo`、`community_provider/community-provider-demo`、`lab_coordinator/lab-coordinator-demo`。登录返回可撤销会话 Token；Token 有过期时间，退出后立即失效。项目管理员和区域协调员可以登记站点、分派和复核，实验室协调员可以上报能力缺口，社区服务机构只能处理分配给自己的恢复任务。

## 目录

```text
cmd/carecontinuity/       HTTP 服务入口
cmd/carecontinuityctl/    维护命令
internal/auth/          登录、会话、角色鉴权
internal/prevention/    社区服务站与连续性缺口领域服务
internal/domain/        状态机和值对象
internal/service/       事务业务编排、批处理和审计
internal/storage/       SQLite repository、迁移和重启恢复
internal/httpapi/       HTTP API、请求 ID、统一错误和健康检查
internal/scheduler/     超时扫描、重试和优雅停止
internal/audit/         结构化日志与审计
migrations/             版本化 SQL 迁移
```

## 运行

需要 Go 1.26 和 `GOTOOLCHAIN=local`：

```bash
export GOTOOLCHAIN=local
go test ./... -count=1
go test -race ./... -count=1
go vet ./...
go build ./...
go run ./cmd/carecontinuity
```

默认监听 `:56058`，数据目录为 `./data`。可通过 `CARECONTINUITY_PORT`、`CARECONTINUITY_DATA_DIR`、`CARECONTINUITY_LOG_LEVEL` 等环境变量覆盖配置。`/healthz` 检查存活，`/readyz` 检查数据库迁移和连接。

## 公开 API

```text
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/prevention/stations
GET  /api/v1/prevention/stations
POST /api/v1/prevention/gaps
POST /api/v1/prevention/gaps/{id}/assign
POST /api/v1/prevention/gaps/{id}/rectify
POST /api/v1/prevention/gaps/{id}/verify
GET  /api/v1/audit
GET  /api/v1/overdues
GET  /healthz
GET  /readyz
```

## 示例

```bash
TOKEN=$(curl -s localhost:56058/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"regional_coordinator","password":"regional-coordinator-demo"}' | jq -r .id)
curl -X POST localhost:56058/api/v1/prevention/stations \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"id":"site-001","name":"江北社区联合检测点","county":"示范区","operator_id":"u-community-provider"}'
```

## 数据与迁移

生产路径使用 SQLite WAL 和真实 SQL，migration 在服务启动时幂等执行。数据库包含身份、社区服务站、连续性缺口、现场复核、样本/物资交接、资金台账、审计、事件、批次和失败重试等关联表；不使用内存 map 代替主流程持久化。
