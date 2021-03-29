# Kubernetes 대시보드

- [Kubernetes 대시보드](#kubernetes-대시보드)
  - [참고 자료](#참고-자료)
  - [Kind Cluster with Ingress](#kind-cluster-with-ingress)
  - [Kubernetes Dashboard](#kubernetes-dashboard)
    - [Quickstart](#quickstart)
    - [Creating Sample User](#creating-sample-user)
    - [`kubectl proxy`](#kubectl-proxy)
      - [Clean up sample user](#clean-up-sample-user)
  - [Ingress Controller](#ingress-controller)
    - [~~Using k8s manifest~~](#using-k8s-manifest)
    - [Using Helm](#using-helm)
  - [Ingress](#ingress)
    - [TLS 키 생성](#tls-키-생성)
    - [Ingress 생성](#ingress-생성)
  - [덧](#덧)

## 참고 자료

- [프로젝트 GitHub](https://github.com/kubernetes/dashboard)
- [Amazon EKS의 사용자 지정 경로에서 Kubernetes 대시보드에 액세스하려면 어떻게 해야 합니까?](https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-kubernetes-dashboard-custom-path/)

## Kind Cluster with Ingress

```bash
kind create cluster --name test --config ../bootstrap/kind-with-ingress.yaml
```

## Kubernetes Dashboard

### Quickstart

```bash
curl -o dashboard.yaml -L https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
kubectl apply -f dashboard.yaml
# curl https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml | kubectl apply -f -
```

### Creating Sample User

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

```bash
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```

### `kubectl proxy`

```bash
kubectl proxy --port=8011 --address='192.168.7.191' --accept-hosts="^*$"
# http://192.168.7.191:8011/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

#### Clean up sample user

```bash
kubectl -n kubernetes-dashboard delete serviceaccount admin-user
kubectl -n kubernetes-dashboard delete clusterrolebinding admin-user
```

## Ingress Controller

- [인그레스](https://kubernetes.io/ko/docs/concepts/services-networking/ingress/) - 쿠버네티스 공식 문서
- [Ingress Nginx 문서](https://kubernetes.github.io/ingress-nginx/)
- [Bare-metal considerations](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/): `MetalLB`, `NodePort`, `hostNetwork`, `externalIPs` or a self-provisioned edge
- 기본 설정은 `NodePort`
- Ingress는 Ingress Controller가 관리하기 때문에 꼭 필요하다.
- 인그레스는 임의의 포트 또는 프로토콜을 노출시키지 않는다. L7 HTTP(S)만을 처리한다.
- HTTP와 HTTPS 이외의 서비스를 인터넷에 노출하려면 보통 `Service.Type=NodePort` 또는 `Service.Type=LoadBalancer` (ex: MetalLB) 유형의 서비스를 사용한다.

### ~~Using k8s manifest~~

```bash
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/baremetal/deploy.yaml
curl -o ingress-controller.yaml -L https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/baremetal/deploy.yaml

kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --watch

# kubectl wait --namespace ingress-nginx \
#   --for=condition=ready pod \
#   --selector=app.kubernetes.io/component=controller \
#   --timeout=120s
```

### Using Helm

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# helm install ingress-nginx ingress-nginx/ingress-nginx
helm pull ingress-nginx/ingress-nginx
```

## Ingress

### TLS 키 생성

- OpenSSL을 사용하여 프라이빗 키를 생성합니다.

```bash
openssl genrsa 2048 > kube-dash-private.key
```

- 생성된 키를 사용하여 인증서를 생성합니다.

```bash
openssl req -new -x509 -nodes -sha1 -days 3650 -extensions v3_ca -key kube-dash-private.key > kube-dash-public.crt
```

```bash
kubectl create secret tls tls-secret --key kube-dash-private.key --cert kube-dash-public.crt -n kube-system
```

### Ingress 생성

- `1.19+`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard-ingress
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/configuration-snippet: |
      rewrite ^(/dashboard)$ $1/ redirect;
  namespace: kubernetes-dashboard
spec:
  rules:
    - http:
        paths:
          - path: /dashboard(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443
```

- `1.19-`

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /dash
            pathType: Prefix
            backend:
              serviceName: kubernetes-dashboard
              servicePort: 443
          - path: /kibana
            pathType: Prefix
            backend:
              serviceName: kibana-kibana
              servicePort: 5601
```

- `kind`

```bash
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
```

## 덧

- 이유는 모르겠지만 Kubespray + IPVS + Calico 환경에서 Ingress Controller를 설치한 이후 호스트 네트워크가 동작하지 않음
- kubeadm으로 설치 후 정상 동작

```bash
journalctl -fxu kubelet
#  3월 29 16:47:49 mec01 kubelet[2927]: I0329 16:47:49.368947    2927 prober.go:124] Readiness probe for "calico-node-lfsbw_kube-system(d6230a41-4137-43cd-9ad6-1f8b95459693):calico-node" failed (failure): 2021-03-29 07:47:49.350 [INFO][9740] confd/health.go 180: Number of node(s) with BGP peering established = 0
#  3월 29 16:47:49 mec01 kubelet[2927]: calico/node is not ready: BIRD is not ready: BGP not established with 192.168.7.192,192.168.7.193,192.168.7.194
```

```bash
kubectl logs -f calico-node-lfsbw -n kube-system
# 2021-03-29 07:54:16.311 [INFO][48] felix/int_dataplane.go 848: Linux interface addrs changed. addrs=set.mapSet{"127.0.0.0":set.empty{}, "127.0.0.1":set.empty{}, "::1":set.empty{}, "fe80::84a3:8169:c147:fbe5":set.empty{}, "fe80::ecee:eeff:feee:eeee":set.empty{}} ifaceName="lo"
# 2021-03-29 07:54:16.312 [INFO][48] felix/int_dataplane.go 1205: Received interface addresses update msg=&intdataplane.ifaceAddrsUpdate{Name:"lo", Addrs:set.mapSet{"127.0.0.0":set.empty{}, "127.0.0.1":set.empty{}, "::1":set.empty{}, "fe80::84a3:8169:c147:fbe5":set.empty{}, "fe80::ecee:eeff:feee:eeee":set.empty{}}}
# 2021-03-29 07:54:16.312 [INFO][48] felix/hostip_mgr.go 84: Interface addrs changed. update=&intdataplane.ifaceAddrsUpdate{Name:"lo", Addrs:set.mapSet{"127.0.0.0":set.empty{}, "127.0.0.1":set.empty{}, "::1":set.empty{}, "fe80::84a3:8169:c147:fbe5":set.empty{}, "fe80::ecee:eeff:feee:eeee":set.empty{}}}
# 2021-03-29 07:54:16.312 [INFO][48] felix/ipsets.go 119: Queueing IP set for creation family="inet" setID="this-host" setType="hash:ip"
# 2021-03-29 07:54:16.312 [INFO][48] felix/int_dataplane.go 1300: Applying dataplane updates
# 2021-03-29 07:54:16.312 [INFO][48] felix/ipsets.go 749: Doing full IP set rewrite family="inet" numMembersInPendingReplace=6 setID="this-host"
# 2021-03-29 07:54:16.319 [INFO][48] felix/int_dataplane.go 1314: Finished applying updates to dataplane. msecToApply=7.392088
# 2021-03-29 07:54:20.207 [INFO][49] monitor-addresses/startup.go 597: Using IPv4 address from environment: IP=192.168.7.191
# 2021-03-29 07:54:20.208 [INFO][49] monitor-addresses/startup.go 630: IPv4 address 192.168.7.191 discovered on interface ens192
# 2021-03-29 07:51:27.615 [INFO][48] felix/int_dataplane.go 1300: Applying dataplane updates
# 2021-03-29 07:51:27.615 [INFO][48] felix/route_table.go 398: Queueing a resync of routing table. ifaceRegex="^cali.*" ipVersion=0x4
# 2021-03-29 07:51:27.615 [INFO][48] felix/wireguard.go 534: Queueing a resync of wireguard configuration
# 2021-03-29 07:51:27.615 [INFO][48] felix/route_table.go 398: Queueing a resync of routing table. ifaceRegex="^wireguard.cali$" ipVersion=0x4
# 2021-03-29 07:51:27.615 [INFO][48] felix/route_rule.go 172: Queueing a resync of routing rules. ipVersion=4
# 2021-03-29 07:51:27.620 [INFO][48] felix/int_dataplane.go 1314: Finished applying updates to dataplane. msecToApply=5.042048
# 2021-03-29 07:51:36.244 [INFO][48] felix/int_dataplane.go 1300: Applying dataplane updates
# 2021-03-29 07:51:36.244 [INFO][48] felix/ipsets.go 223: Asked to resync with the dataplane on next update. family="inet"
# 2021-03-29 07:51:36.244 [INFO][48] felix/ipsets.go 306: Resyncing ipsets with dataplane. family="inet"
# 2021-03-29 07:51:36.247 [INFO][48] felix/ipsets.go 356: Finished resync family="inet" numInconsistenciesFound=0 resyncDuration=2.967277ms
# 2021-03-29 07:51:36.247 [INFO][48] felix/int_dataplane.go 1314: Finished applying updates to dataplane. msecToApply=3.2024850000000002
```
