# Kubernetes Dashboard

- [Kubernetes Dashboard](#kubernetes-dashboard)
  - [참고 자료](#참고-자료)
  - [대시보드 배포](#대시보드-배포)
    - [Quickstart](#quickstart)
  - [대시보드 접근](#대시보드-접근)
    - [`kubectl proxy`](#kubectl-proxy)
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

### Ingress

- [container-networking/ingress](../../container-networking/ingress.md)
- ~~OpenSSL을 사용하여 프라이빗 키를 생성합니다.~~

```bash
openssl genrsa 2048 > kube-dash-private.key
openssl req -new -x509 -nodes -sha1 -days 3650 -extensions v3_ca -key kube-dash-private.key > kube-dash-public.crt
kubectl create secret tls tls-secret --key kube-dash-private.key --cert kube-dash-public.crt -n kube-system
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
