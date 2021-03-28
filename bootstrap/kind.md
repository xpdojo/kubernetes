# kind

- [kind](#kind)
  - [참고 자료](#참고-자료)
  - [Kind란?](#kind란)
  - [`kind` 커맨드 도구 설치](#kind-커맨드-도구-설치)
  - [kind 클러스터 생성](#kind-클러스터-생성)
  - [kindnet](#kindnet)
  - [Ingress](#ingress)
  - [LoadBalancer](#loadbalancer)
  - [Kind 클러스터 제거](#kind-클러스터-제거)

## 참고 자료

- [Docs](https://kind.sigs.k8s.io/)

## Kind란?

- 로컬 환경에서 쿠버네티스 클러스터를 매우 가볍게 실행시킬 수 있게 해주는 도구다.
- 도커 컨테이너 하나를 노드 하나로 본다.

## `kind` 커맨드 도구 설치

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /some-dir-in-your-PATH/kind
```

## kind 클러스터 생성

```bash
# sudo kind create cluster --name operator-test --image kindest/node:1.18.12
sudo kind create cluster --config ./bootstrap/kind-config.yaml
```

```bash
sudo kind get clusters
```

## kindnet

- kind 클러스터에 사용되는 CNI
- [aojea/kindnet](https://github.com/aojea/kindnet)

```bash
sudo docker exec -it kind-control-plane bash
cat /etc/cni/net.d/10-kindnet.conflist
```

```json
{
  "cniVersion": "0.3.1",
  "name": "kindnet",
  "plugins": [
    {
      "type": "ptp",
      "ipMasq": false,
      "ipam": {
        "type": "host-local",
        "dataDir": "/run/cni-ipam-state",
        "routes": [
          {
            "dst": "0.0.0.0/0"
          }
        ],
        "ranges": [
          [
            {
              "subnet": "10.244.0.0/24"
            }
          ]
        ]
      },
      "mtu": 1500
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
```

## Ingress

- [Docs](https://kind.sigs.k8s.io/docs/user/ingress/)

## LoadBalancer

- [Docs](https://kind.sigs.k8s.io/docs/user/loadbalancer/)

## Kind 클러스터 제거

```bash
sudo kind delete cluster --name operator-test
```
