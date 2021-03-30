# Kubernetes Dashboard

- [Kubernetes Dashboard](#kubernetes-dashboard)
  - [참고 자료](#참고-자료)
  - [대시보드 배포](#대시보드-배포)
    - [Quickstart](#quickstart)
  - [대시보드 접근](#대시보드-접근)
    - [`kubectl proxy`](#kubectl-proxy)
    - [Ingress Controller](#ingress-controller)
      - [Using Helm](#using-helm)
      - [~~Using k8s manifest~~](#using-k8s-manifest)
      - [Kind Cluster with Ingress](#kind-cluster-with-ingress)
      - [Ingress](#ingress)
    - [MetalLB](#metallb)
  - [Clean up](#clean-up)

## 참고 자료

- [kubernetes/dashboard](https://github.com/kubernetes/dashboard) - GitHub
- [Amazon EKS의 사용자 지정 경로에서 Kubernetes 대시보드에 액세스하려면 어떻게 해야 합니까?](https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-kubernetes-dashboard-custom-path/)

## 대시보드 배포

### Quickstart

```bash
# curl https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml | kubectl apply -f -
curl -o dashboard.yaml -L https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
```

```diff
kind: Service
apiVersion: v1
...
spec:
  ports:
+   - port: 80
+     targetPort: 9090
  selector:
    k8s-app: kubernetes-dashboard
```

```diff
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  template:
    spec:
      containers:
      - name: kubernetes-dashboard
        image: kubernetesui/dashboard:v2.2.0
        ports:
+         - containerPort: 9090
            protocol: TCP
        args:
-         - --auto-generate-certificates
          - --namespace=kubernetes-dashboard
        livenessProbe:
          httpGet:
+           scheme: HTTP
            path: /
+           port: 9090
```

```diff
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
rules:
...
+  - apiGroups: [""]
+    resources: ["*"]
+    verbs: ["get", "list", "watch"]
+  - apiGroups: ["apps"]
+    resources: ["*"]
+    verbs: ["get", "list", "watch"]
+  - apiGroups: ["batch"]
+    resources: ["*"]
+    verbs: ["get", "list", "watch"]
+  - apiGroups: ["rbac.authorization.k8s.io"]
+    resources: ["*"]
+    verbs: ["get", "list", "watch"]
+  - apiGroups: ["networking.k8s.io"]
+    resources: ["*"]
+    verbs: ["get", "list", "watch"]
+  - apiGroups: ["storage.k8s.io"]
+    resources: ["*"]
+    verbs: ["get", "list", "watch"]
```

```bash
kubectl apply -f dashboard.yaml
```

## 대시보드 접근

### `kubectl proxy`

```bash
kubectl proxy --port=8011 --accept-hosts="^*$" --address="192.168.7.191"
# http://192.168.7.191:8011/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Ingress Controller

- [인그레스](https://kubernetes.io/ko/docs/concepts/services-networking/ingress/) - 쿠버네티스 공식 문서
- [Ingress Nginx 문서](https://kubernetes.github.io/ingress-nginx/)
- [Bare-metal considerations](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/): `MetalLB`, `NodePort`, `hostNetwork`, `externalIPs` or a self-provisioned edge
- 기본 설정은 `NodePort`
- Ingress는 Ingress Controller가 관리하기 때문에 꼭 필요하다.
- 인그레스는 임의의 포트 또는 프로토콜을 노출시키지 않는다. L7 HTTP(S)만을 처리한다.
- HTTP와 HTTPS 이외의 서비스를 인터넷에 노출하려면 보통 `Service.Type=NodePort` 또는 `Service.Type=LoadBalancer` (ex: MetalLB) 유형의 서비스를 사용한다.

#### Using Helm

```bash
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
```

```bash
# helm pull nginx-stable/nginx-ingress
# tar zxf nginx-ingress-0.8.1.tgz
# vi nginx-ingress/values.yaml
# externalIPs: ["192.168.7.191", "192.168.7.192"]
# helm install ingress nginx-ingress

# helm install ingress-nginx ingress-nginx/ingress-nginx
helm pull ingress-nginx/ingress-nginx
tar zxf ingress-nginx-3.25.0.tgz
vi ingress-nginx/values.yaml
# externalIPs: ["192.168.7.191", "192.168.7.192"]
helm install ingress ingress-nginx
```

#### ~~Using k8s manifest~~

```bash
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/baremetal/deploy.yaml
curl -o ingress-controller.yaml -L https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/baremetal/deploy.yaml

kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --watch

# kubectl wait --namespace ingress-nginx \
#   --for=condition=ready pod \
#   --selector=app.kubernetes.io/component=controller \
#   --timeout=120s
```

#### Kind Cluster with Ingress

```bash
kind create cluster --name test --config ../bootstrap/kind-with-ingress.yaml
```

#### Ingress

- ~~OpenSSL을 사용하여 프라이빗 키를 생성합니다.~~

```bash
openssl genrsa 2048 > kube-dash-private.key
openssl req -new -x509 -nodes -sha1 -days 3650 -extensions v3_ca -key kube-dash-private.key > kube-dash-public.crt
kubectl create secret tls tls-secret --key kube-dash-private.key --cert kube-dash-public.crt -n kube-system
```

- `1.19+`
- `ingressclasses`는 필수 필드가 아닙니다.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: kubernetes-dashboard
spec:
  ingressClassName: nginx
  # tls:
  #   - hosts:
  #     - 192.168.7.221
  #     secretName: tls-secret
  rules:
    - host:
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 80
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
          - path: /
            pathType: Prefix
            backend:
              serviceName: kubernetes-dashboard
              servicePort: 80
```

- ~~Kind cluster~~

```bash
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
kubectl get ingress --all-namespaces
# NAMESPACE              NAME                CLASS    HOSTS   ADDRESS         PORTS   AGE
# kubernetes-dashboard   dashboard-ingress   <none>   *       192.168.7.221   80      3m10s
```

- 인그레스 컨트롤러가 없다면 아래와 같이 ADDRESS가 할당되지 않습니다.

```bash
kubectl get ingress --all-namespaces
# NAMESPACE              NAME                CLASS    HOSTS   ADDRESS         PORTS   AGE
# kubernetes-dashboard   dashboard-ingress   <none>   *                       80      3m10s
```

### MetalLB

TODO:

## Clean up

```bash
kubectl -n kubernetes-dashboard delete -f dashboard.yaml
```
