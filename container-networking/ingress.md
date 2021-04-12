# 인그레스 API

- [인그레스 API](#인그레스-api)
  - [Ingress Controller](#ingress-controller)
    - [Using Helm](#using-helm)
    - [Kind Cluster with Ingress](#kind-cluster-with-ingress)
    - [~~Using k8s manifest~~](#using-k8s-manifest)
  - [Ingress](#ingress)
    - [`1.19` or later](#119-or-later)
    - [`1.18`](#118)
    - [nginx `.conf`](#nginx-conf)

## Ingress Controller

- [인그레스 컨트롤러](https://kubernetes.io/ko/docs/concepts/services-networking/ingress-controllers/) - 쿠버네티스 공식 문서
- [Nginx Ingress Controller](https://www.nginx.com/products/nginx-ingress-controller/)
  - [문서](https://kubernetes.github.io/ingress-nginx/)
- [Bare-metal considerations](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/): `MetalLB`, `NodePort`, `hostNetwork`, `externalIPs` or a self-provisioned edge
- 기본 설정은 `NodePort`
- Ingress는 Ingress Controller가 관리하기 때문에 꼭 필요하다.
- 인그레스는 임의의 포트 또는 프로토콜을 노출시키지 않는다. L7 HTTP(S)만을 처리한다.
- HTTP와 HTTPS 이외의 서비스를 인터넷에 노출하려면 보통 `Service.Type=NodePort` 또는 `Service.Type=LoadBalancer` (ex: MetalLB) 유형의 서비스를 사용한다.

![nginx-ingress-controller.svg](../images/networking/nginx-ingress-controller.svg)

### Using Helm

```bash
# 안 됨
# helm repo add nginx-stable https://helm.nginx.com/stable
# helm pull nginx-stable/nginx-ingress
# tar zxf nginx-ingress-0.8.1.tgz
# vi nginx-ingress/values.yaml
# externalIPs: ["192.168.7.191", "192.168.7.192"]
# helm install ingress-controller nginx-ingress
# helm repo remove nginx-stable
```

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
# helm install ingress-controller ingress-nginx/ingress-nginx
helm pull ingress-nginx/ingress-nginx
tar zxf ingress-nginx-3.25.0.tgz
```

```bash
vi ingress-nginx/values.yaml
# externalIPs: ["192.168.7.191", "192.168.7.192"]
```

```bash
helm install ingress-ctr ingress-nginx
```

### Kind Cluster with Ingress

```bash
kind create cluster --name test --config ../bootstrap/kind-with-ingress.yaml
```

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

## Ingress

- [인그레스](https://kubernetes.io/ko/docs/concepts/services-networking/ingress/) - 쿠버네티스 공식 문서
- 클러스터 외부에서 클러스터 내부 서비스로 HTTP와 HTTPS 경로를 노출합니다.
- 인그레스는 외부에서 서비스로 접속이 가능한 URL, 로드 밸런스 트래픽, SSL / TLS 종료 그리고 이름-기반의 가상 호스팅을 제공하도록 구성할 수 있습니다.
- **인그레스 컨트롤러는 일반적으로 로드 밸런서를 사용해서 인그레스를 수행할 책임이 있습니다.**
- 트래픽을 처리하는데 도움이 되도록 에지 라우터 또는 추가 프런트 엔드를 구성할 수도 있습니다.
- 인그레스는 임의의 포트 또는 프로토콜을 노출시키지 않는다. HTTP와 HTTPS 이외의 서비스를 인터넷에 노출하려면 보통 `Service.Type=NodePort` 또는 `Service.Type=LoadBalancer` 유형의 서비스를 사용합니다.

### `1.19` or later

- Kubernetes Enhancement Proposal [(KEP758)](https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/758-ingress-api-group/README.md)
- [kubernetes/kubernetes#89778](https://github.com/kubernetes/kubernetes/pull/89778)
- [Ingress v1 and v1beta1 Differences Permalink](https://docs.konghq.com/kubernetes-ingress-controller/1.2.x/concepts/ingress-versions/)
- `ingressclasses`는 필수 필드가 아닙니다.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
    - host:
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kibana
                port:
                  number: 5601
```

아무 설정 없이 `path`를 정하면 백엔드 서비스에 요청 경로가 그대로 전달됩니다.
예를 들어, kibana 서비스에 `/kib` 경로를 지정하고
`http://192.168.7.191/kib`이라는 경로로 요청을 보내면
백엔드 서비스에도 `http://kibana:5601/kib`으로 요청이 넘어갑니다.

```json
{
  "type": "response",
  "@timestamp": "2021-04-07T00:31:32+00:00",
  "tags": [],
  "pid": 6,
  "method": "get",
  "statusCode": 404,
  "req": {
    "url": "/kib",
    "method": "get",
    "headers": {
      "host": "192.168.7.191",
      "x-request-id": "f1ce54acb7dcd32ebc279bb94b4df506",
      "x-real-ip": "172.16.16.64",
      "x-forwarded-for": "172.16.16.64",
      "x-forwarded-host": "192.168.7.191",
      "x-forwarded-port": "80",
      "x-forwarded-proto": "http",
      "x-scheme": "http",
      "user-agent": "curl/7.64.1",
      "accept": "*/*"
    },
    "remoteAddress": "172.16.16.43",
    "userAgent": "curl/7.64.1"
  },
  "res": { "statusCode": 404, "responseTime": 16, "contentLength": 60 },
  "message": "GET /kib 404 16ms - 60.0B"
}
```

- 이 때 `rewrite` 규칙이 필요합니다.
- 아래와 같은 `annotation`을 추가합니다.
- `kubectl apply -f ingress.yaml` 명령어로 `Ingress` 재배포 후 확인해보면
  `http://192.168.7.191/kib/status`라는 경로로 요청할 경우
  `http://kibana:5601/status`로 요청이 전달됩니다.
- [참고](https://kubernetes.github.io/ingress-nginx/examples/rewrite/)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
    - host:
      http:
        paths:
          - path: /dash(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 80
```

### `1.18`

- [Improvements to the Ingress API in Kubernetes 1.18](https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/)

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

### nginx `.conf`

테스트 환경에서 ingress 포트(`80`, `443`) 대신 다른 포트를 사용하려면 호스트에 nginx를 설치해서 ingress로 전달하고 있는데...다른 방법 찾아보기

```nginx
http {
  upstream kibana {
    server kibana.local.com:80;
  }
  upstream nginx {
    server nginx.local.com:80;
  }

  map $host $backend {
    kibana.local.com kibana;
    nginx.local.com nginx;
  }

  server {
    listen 8089;
    client_max_body_size 500m;
    server_tokens off;

    location / {
      proxy_read_timeout 300s;
      proxy_connect_timeout 75s;
      proxy_pass http://$backend;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection 'upgrade';
      proxy_set_header Host $host;
      proxy_cache_bypass $http_upgrade;
    }
  }
}
```
