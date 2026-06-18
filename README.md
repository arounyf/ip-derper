# ip-derper — Tailscale DERP 中继（纯 IP，无需域名）

基于 [Tailscale v1.98.3](https://github.com/tailscale/tailscale/releases/tag/v1.98.3) 的 `cmd/derper`。

## 纯 IP 搭建关键

derper 服务器使用自签证书时，证书与 IP/域名不匹配会导致 TLS 握手失败。需要满足以下两点：

### 1. derper 服务器不验证域名

修改 `tailscale/cmd/derper/cert.go`，注释掉 `getCertificate` 中的域名校验：

```go
func (m *manualCertManager) getCertificate(hi *tls.ClientHelloInfo) (*tls.Certificate, error) {
	// 注释掉域名校验，支持纯 IP 部署（自签证书与 IP 不匹配也能用）
	//if hi.ServerName != m.hostname && !m.noHostname {
	//	return nil, fmt.Errorf("cert mismatch with hostname: %q", hi.ServerName)
	//}

	// Return a shallow copy of the cert so the caller can append to its
	// Certificate field.
	certCopy := new(tls.Certificate)
	*certCopy = *m.cert
	certCopy.Certificate = certCopy.Certificate[:len(certCopy.Certificate):len(certCopy.Certificate)]
	return certCopy, nil
}
```

### 2. tailscale 客户端不验证域名

客户端连接 derper 时，DERP map 中必须设置 `InsecureForTests: true`，跳过自签证书验证。

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
