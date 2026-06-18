# ip-derper — Tailscale DERP 中继（纯 IP，无需域名）

> **⚠️ 本项目已归档，不再维护。**
>
> 自 Tailscale v1.98 起，`cmd/derper` 已原生支持纯 IP 部署（`noHostname` + 自动自签证书），无需任何源码修改。直接使用上游 derper 即可，本项目的 Dockerfile 封装已无必要。
>
> 下方文档保留供参考。建议直接使用 [tailscale/cmd/derper](https://github.com/tailscale/tailscale/tree/main/cmd/derper) 配合 `InsecureForTests: true`。

基于 [Tailscale v1.98.3](https://github.com/tailscale/tailscale/releases/tag/v1.98.3) 的 `cmd/derper`。

## 纯 IP 为什么能工作

v1.98+ 的 derper 内置了两个关键逻辑（`tailscale/cmd/derper/cert.go`）：

### 1. `noHostname` — 自动跳过域名校验

`NewManualCertManager` 检测到 hostname 是 IP 地址时，设置 `noHostname = true`：

```go
noHostname: net.ParseIP(hostname) != nil,  // IP → true, 域名 → false
```

后续 `getCertificate` 中：

```go
if hi.ServerName != m.hostname && !m.noHostname {
    // noHostname=true 时 !m.noHostname=false，整段跳过
    // 纯 IP 部署不会触发证书域名不匹配错误
}
```

### 2. 自动生成 IP 自签证书

证书文件不存在时，`createSelfSignedIPCert` 自动创建带 IP SAN 的自签证书，无需手动申请。

### 3. 客户端仍需 `InsecureForTests: true`

derper 端没问题了，但 tailscale 客户端仍会验证证书。DERP map 中必须设置：

```json
"InsecureForTests": true
```

---

## 快速启动

```shell
docker run \
  -p 3478:3478/udp \
  -p 12345:12345 \
  --name ip_derper \
  -e DERP_ADDR=:12345 \
  -e DERP_HOST=<你的公网IP> \
  runyf/ip-derper:v1.98.3
```

## docker-compose

```shell
services:
  ip_derper:
    image: runyf/ip-derper:v1.98.3
    container_name: ip_derper
    ports:
      - "3478:3478/udp"
      - "12345:12345"
    environment:
      - DERP_ADDR=:12345
      - DERP_HOST=<你的公网IP>
    restart: unless-stopped
```

## DERP JSON 配置（供 headscale / tailscale）

```json
{
  "Regions": {
    "901": {
      "RegionID": 901,
      "RegionCode": "derp-cd",
      "RegionName": "derp-chengdu",
      "Nodes": [
        {
          "Name": "901a",
          "RegionID": 901,
          "DERPPort": 12345,
          "HostName": "<你的公网IP>",
          "IPv4": "<你的公网IP>",
          "InsecureForTests": true
        }
      ]
    }
  }
}
```

**`InsecureForTests: true` 必须设置**，否则客户端会拒绝自签证书。

## 常见错误

```
# Health check:
#     - not connected to home DERP region 902
```
DERP JSON 中 `InsecureForTests` 没设为 true。

```
# Health check:
#     - TLS connection error: certificate is self-signed
```
提示但通常不影响使用——客户端仍会连接。

## 构建

```shell
git clone --recurse-submodules https://github.com/arounyf/ip-derper.git
cd ip-derper
docker build -t runyf/ip-derper:v1.98.3 .
```
