# LOKI-LAB（Grafana + Loki + Fluent Bit）

這是一套使用 **Docker Compose** 在本機快速啟動的 **Container Log Pipeline 範例**：

所有 Docker container 的 stdout / stderr  
→ Fluent Bit 收集  
→ 推送至 Loki  
→ 使用 Grafana Explore + LogQL 查詢

此專案適合作為：
- 本機 log pipeline 練習
- 團隊內部 Loki / Grafana PoC
- Kubernetes / Alloy 架構前的 Docker 模擬環境

---

## 專案目錄結構

```text
LOKI-LAB/
├─ docker-compose.yml
├─ loki-config.yml
├─ fluent-bit/
│  └─ fluent-bit.conf
└─ grafana/
   └─ provisioning/
      └─ datasources/
         └─ datasource.yml


---
## 設計原則說明

- Fluent Bit 使用 Docker mode 收集所有 container logs
- Loki labels 僅使用低基數欄位：
  - container_name
  - container_id
  - image

- 高變動資料（如 orderId / deviceId / userId）
  - 僅保留在 log 內容中
  - 不要作為 Loki label（避免高基數問題）
---

## 需求

- Docker Desktop（macOS / Windows / Linux 皆可）
- Docker Compose v2（`docker compose`）

---

## 啟動

在 `LOKI-LAB/` 目錄下執行：

```bash
docker compose up -d
docker compose ps
```

成功後應看到以下服務皆為 Up：

- loki
- grafana
- fluent-bit

---

## Grafana 登入與驗證

### Grafana 登入

- **URL**：http://localhost:3000
- **預設帳密**：`admin / Qwertyuiop`

> Loki datasource 已透過 provisioning 自動加入，**不需要手動設定**。

---

### 驗證 Log Pipeline（必做）

請先啟動一個會持續輸出 log 的測試 container：

```bash
docker run --rm --name log-tester alpine sh -c 'i=0; while true; do echo "hello_loki_$i"; i=$((i+1)); sleep 1; done'
```

接著到 Grafana：

1. 左側選單 → **Explore**
2. Datasource 選擇 **Loki**
3. 輸入以下 LogQL 查詢：

```logql
{container_name="log-tester"}
```

若看到 `hello_loki_0`, `hello_loki_1`… 持續出現，
代表整條 Log Pipeline 正常運作 ✅

---

## 常用 LogQL 查詢
### 看目前 Loki 有哪些 container
```bash
{container_name=~".+"}
```

### 查某個 container 的所有 log
```bash
{container_name="grafana"}
```

### 關鍵字搜尋（等同 grep）
```bash
{container_name="log-tester"} |= "hello"
```

---
## 檢查與除錯
### 查看 Fluent Bit log（最常用）：
```bash
docker compose logs fluent-bit --tail=200
```
### 看 Loki 是否 ready
```bash
curl http://localhost:3100/ready
```

### 看 Loki 是否有 labels（代表有資料進來）
```bash
curl http://localhost:3100/loki/api/v1/labels
```

---

## 常見問題（Troubleshooting）

### Q1：Grafana Explore 查不到任何資料

請依序確認以下項目（不要跳步）：

#### 1️⃣ 確認服務狀態
```bash
docker compose ps
```

- [ ] `loki` 狀態為 **Up**
- [ ] `grafana` 狀態為 **Up**
- [ ] `fluent-bit` 狀態為 **Up**

---

#### 2️⃣ 確認有產生測試 log
請確認已啟動測試 container（例如 `log-tester`）：

```bash
docker ps | grep log-tester
```

若尚未啟動，請先執行：

```bash
docker run --rm --name log-tester alpine sh -c 'i=0; while true; do echo "hello_loki_$i"; i=$((i+1)); sleep 1; done'
```

---

#### 3️⃣ 檢查 Fluent Bit 是否正常運作
```bash
docker compose logs fluent-bit --tail=200
```

請確認：
- [ ] 沒有 `error` / `failed` / `retry` 等錯誤訊息
- [ ] 有看到 log 被送往 Loki（loki output 相關訊息）

---

#### 4️⃣ 確認 Loki 是否有資料
```bash
curl http://localhost:3100/ready
```

應回傳：
```text
ready
```

接著檢查 Loki 是否已有 labels：

```bash
curl "http://localhost:3100/loki/api/v1/labels"
```

若回傳 JSON（非空陣列），代表 Loki 已收到資料。

---

#### 5️⃣ 回到 Grafana 驗證查詢
到 Grafana → **Explore** → Datasource 選 **Loki**  
嘗試以下查詢：

```logql
{container_name="log-tester"}
```

或最寬鬆查詢：

```logql
{container_name=~".+"}
```

---

#### 6️⃣ 確認時間範圍
請確認 Grafana 右上角時間範圍設定為：
- **Last 15 minutes** 或 **Last 1 hour**

時間範圍錯誤是最常見原因之一。

---

### 若以上皆正確但仍無資料

請優先檢查：

- Fluent Bit 是否能透過 `docker.sock` 存取 container
- Docker Desktop 是否允許 socket 掛載
- 嘗試重新啟動服務：

```bash
docker compose down
docker compose up -d
```

若問題仍存在，請保留以下資訊以利除錯：
- `docker compose ps`
- `docker compose logs fluent-bit --tail=200`
- 查詢用的 LogQL

---
## 清理

### 停止並移除 container：
```bash
docker compose down
```

### 連同 volume 一起刪除（會清掉 Grafana 設定與快取）：
```bash
docker compose down -v
```