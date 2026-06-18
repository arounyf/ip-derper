# ip-derper — Tailscale DERP 中继（纯 IP，无需域名）

基于 [Tailscale v1.98.3](https://github.com/tailscale/tailscale/releases/tag/v1.98.3) 的 `cmd/derper`。

**新版不再需要修改源码** — v1.98+ 的 derper 已内置 IP 自签证书自动生成和 `noHostname` 逻辑。

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

首次启动自动生成自签证书。`DERP_HOST` 填你的公网 IP。

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

## DERP JSON 配置（供 headscale）

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
