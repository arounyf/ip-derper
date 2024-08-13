#### 运行容器命令
```shell
docker run \
  -p 3478:3478/udp \
  -p 12345:12345 \
  --name ip_derper \
  -e DERP_ADDR=:12345 \
runyf/ip-derper:v1.70.0
```


####  常见错误(适用headscale)
```shell

# Health check:
#     - not connected to home DERP region 902
```
没有设置InsecureForTests为true，需要使用json配置才能支持

```shell
# Health check:
#     - TLS connection error for "": certificate is self-signed
```
提示TLS连接错误，但并不影响使用
```shell
# Health check:
#     - Tailscale could not connect to the 'test' relay server. Your Internet connection might be down, or the server might be temporarily unavailable.
```
deper的端口不通
