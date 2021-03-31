# MetalLB

- [MetalLB](#metallb)
  - [`NodePort` 보다 `LoadBalancer`가 좋은 점](#nodeport-보다-loadbalancer가-좋은-점)
  - [테스트를 위한 Kind 클러스터 생성](#테스트를-위한-kind-클러스터-생성)
  - [Quickstart](#quickstart)
    Bare Metal 환경에서 사용하기 위한 로드 밸런서 구현 소프트웨어

## `NodePort` 보다 `LoadBalancer`가 좋은 점

- 노드의 IP와 Port를 노출시켜야 할 부담이 없다.
- TODO: 정리

## 테스트를 위한 Kind 클러스터 생성

- [Kind란](../bootstrap/kind.md)

```bash
cat <<EOF | kind create cluster -v=3 --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.18.15
- role: worker
  image: kindest/node:v1.18.15
- role: worker
  image: kindest/node:v1.18.15
- role: worker
  image: kindest/node:v1.18.15
EOF
```

## Quickstart

```bash
# curl -LO https://raw.githubusercontent.com/metallb/metallb/v0.8.3/manifests/metallb.yaml
# kubectl apply -f metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.8.3/manifests/metallb.yaml
```

```bash
kubectl get po -l app=metallb -A
# NAMESPACE        NAME                          READY   STATUS    RESTARTS   AGE
# metallb-system   controller-675d6c9976-sj2b7   1/1     Running   0          2m2s
# metallb-system   speaker-vjk99                 1/1     Running   0          2m2s
# metallb-system   speaker-vtzkc                 1/1     Running   0          2m2s
```

```bash
kubectl create deploy test-nginx --image=nginx --replicas=3
# kubectl scale deploy test-nginx --replicas=3
kubectl get po -A -o wide
```

```bash
kubectl expose deploy test-nginx --type=LoadBalancer --port=3000 --target-port=80
```

- `EXTERNAL-IP`가 아직 pending 상태입니다.

```bash
kubectl get svc -l=app=test-nginx
# NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# test-nginx   LoadBalancer   10.96.103.219   <pending>     3000:30828/TCP   3m3s
```

```bash
docker network inspect -f '{{.IPAM.Config}}' kind
# [{172.18.0.0/16  172.18.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.200-172.18.255.250
EOF
```

```bash
kubectl get cm -n metallb-system
# NAME               DATA   AGE
# config             1      26s
```

```bash
kubectl get svc -l=app=test-nginx
# NAME         TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
# test-nginx   LoadBalancer   10.96.103.219   172.18.255.200   3000:30828/TCP   7m55s

kubectl get svc/test-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
# 172.18.255.200⏎
```

```bash
curl 172.18.255.200:3000
# Welcome to nginx!
```
