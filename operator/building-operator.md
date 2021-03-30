# 쿠버네티스 오퍼레이터 제작하기 (with Kubebuilder)

- [쿠버네티스 오퍼레이터 제작하기 (with Kubebuilder)](#쿠버네티스-오퍼레이터-제작하기-with-kubebuilder)
  - [Quickstart](#quickstart)
    - [큐브빌더 `Kubebuilder` 설치](#큐브빌더-kubebuilder-설치)
    - [`kustomize` 설치](#kustomize-설치)
    - [스켈레톤 프로젝트 생성](#스켈레톤-프로젝트-생성)
    - [API 리소스 개발](#api-리소스-개발)
    - [컨트롤 루프 개발](#컨트롤-루프-개발)
  - [컨트롤러 컨테이너화](#컨트롤러-컨테이너화)
    - [도커 이미지 빌드](#도커-이미지-빌드)
    - [Kind 클러스터에 배포](#kind-클러스터에-배포)
    - [Reconciliation 테스트](#reconciliation-테스트)
  - [Clean up](#clean-up)

## [Quickstart](https://book.kubebuilder.io/quick-start.html)

### 큐브빌더 `Kubebuilder` 설치

```bash
os=$(go env GOOS)
arch=$(go env GOARCH)
url -L https://go.kubebuilder.io/dl/2.3.1/${os}/${arch} | tar -xz -C /tmp/
sudo mv /tmp/kubebuilder_2.3.1_${os}_${arch} /usr/local/kubebuilder
export PATH=$PATH:/usr/local/kubebuilder/bin
```

### `kustomize` 설치

- [Docs](https://kubernetes-sigs.github.io/kustomize/installation/)
- `kustomize`로 CRD를 생성합니다.

```bash
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin
```

### 스켈레톤 프로젝트 생성

```bash
go mod init markruler.com
# go: creating new go.mod: module markruler.com
```

```bash
kubebuilder init --domain markruler.com
# Writing scaffold for you to edit...
# Get controller runtime:
# $ go get sigs.k8s.io/controller-runtime@v0.5.0
# Update go.mod:
# $ go mod tidy
# Running make:
# $ make
# /home/changsu/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
# go fmt ./...
# go vet ./...
# go build -o bin/manager main.go
# Next: define a resource with:
# $ kubebuilder create api
```

### API 리소스 개발

- [Kubernetes API Group, Version, Resource](https://kubernetes.io/docs/reference/using-api)
- [Kubernetes API Deprecation Policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/)

```bash
kubebuilder create api --group gc --version v1alpha1 --kind Ruler
# Create Resource [y/n]
y
# Create Controller [y/n]
y
# Writing scaffold for you to edit...
# api/v1alpha1/ruler_types.go
# controllers/ruler_controller.go
# Running make:
# $ make
# /home/changsu/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
# go fmt ./...
# go vet ./...
# go build -o bin/manager main.go
```

```diff
# api/v1alph1/${kind}_types.go
type RulerSpec struct {
-  Foo string `json:"foo,omitempty"`
+  Type string `json:"type,omitempty"`
}

type RulerStatus struct {
+  Mark bool `json:"mark"`
}

// +kubebuilder:object:root=true
+  // +kubebuilder:printcolumn:name="type",type=string,JSONPath=`.spec.type`
+  // +kubebuilder:printcolumn:name="mark",type=boolean,JSONPath=`.status.mark`
+  // +kubebuilder:subresource:status

// Ruler is the Schema for the rulers API
type Ruler struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ObjectMeta `json:"metadata,omitempty"`

  Spec   RulerSpec   `json:"spec,omitempty"`
  Status RulerStatus `json:"status,omitempty"`
}
```

> 큐브빌더의 마커(Marker)란?

- 유틸리티 코드와 쿠버네티스 매니페스트 파일을 생성하기 위한 메타 데이터입니다.
- 참고 자료
  - [kubebuilder markers](https://book.kubebuilder.io/reference/markers.html)
  - [kubernetes/code-generator](https://github.com/kubernetes/code-generator)

```go
// +<tag_name>[=value]
```

- CRD 생성 및 배포

```bash
sudo -i
make generate manifests install
# go: creating new go.mod: module tmp
# go: found sigs.k8s.io/controller-tools/cmd/controller-gen in sigs.k8s.io/controller-tools v0.2.5
# /root/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
# /root/go/bin/controller-gen "crd:trivialVersions=true" rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases
# kustomize build config/crd | kubectl apply -f -
# customresourcedefinition.apiextensions.k8s.io/rulers.example.markruler.com configured
```

```bash
kubectl get crd
# NAME                      CREATED AT
# rulers.gc.markruler.com   2021-03-28T05:16:50Z
kubectl api-resources | grep markruler
# NAME                              SHORTNAMES   APIVERSION                        NAMESPACED   KIND
# rulers                                         gc.markruler.com/v1alpha1         true         Ruler
kubectl get rulers
```

- 리소스 생성

```bash
# bash
cat > config/samples/gc_v1alpha1_ruler.yaml <<EOF
apiVersion: gc.markruler.com/v1alpha1
kind: Ruler
metadata:
  name: sample
spec:
  type: active
EOF

# fish
printf "\
apiVersion: gc.markruler.com/v1alpha1
kind: Ruler
metadata:
  name: sample
spec:
  type: active
" | cat > config/samples/gc_v1alpha1_ruler.yaml
```

```bash
kubectl apply -f config/samples/gc_v1alpha1_ruler.yaml
# ruler.gc.markruler.com/ruler-sample created

kubectl get rulers
# NAME     TYPE     MARK
# sample   active
```

### 컨트롤 루프 개발

> 주의: 이 소스 코드는 Best Practice가 아닙니다. 테스트용으로만 사용해주세요.

```go
// controllers/${kind}_controller.go
func (r *RulerReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
  ctx := context.Background()
  log := r.Log.WithValues("ruler", req.NamespacedName)

  log.Info("Informer => Work Queue => Controller!")

  var ruler gcv1alpha1.Ruler

  if err := r.Get(ctx, req.NamespacedName, &ruler); err != nil {
    log.Info("error getting object", "name", req.NamespacedName)
    return ctrl.Result{}, client.IgnoreNotFound(err)
  }

  if ruler.Status.Mark == true {
    if err := r.Delete(ctx, &ruler); err != nil {
      log.Info("error delete object", "deleteName", req.NamespacedName)
      return ctrl.Result{}, client.IgnoreNotFound(err)
    }
    log.Info(">>> deleted ruler", "deleteName", req.NamespacedName)
    return ctrl.Result{}, nil
  }

  if ruler.Spec.Type == "" {
    ruler.Spec.Type = "garbage"
  }

  if ruler.Spec.Type == "garbage" {
    ruler.Status.Mark = true
  }

  if err := r.Status().Update(ctx, &ruler); err != nil {
    log.Info("error updating status", "name", req.NamespacedName)
    return ctrl.Result{}, client.IgnoreNotFound(err)
  } else {
    log.Info("Update Ruler", "updatedName", req.NamespacedName)
  }

  return ctrl.Result{}, nil
}
```

- 컨트롤러 로컬 테스트

```bash
make run
# go: creating new go.mod: module tmp
# go: found sigs.k8s.io/controller-tools/cmd/controller-gen in sigs.k8s.io/controller-tools v0.2.5
# /root/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
# go fmt ./...
# controllers/ruler_controller.go
# go vet ./...
# /root/go/bin/controller-gen "crd:trivialVersions=true" rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases
# go run ./main.go

sudo kubectl apply -f config/samples/gc_v1alpha1_ruler.yaml
sudo watch kubectl get ruler
```

## 컨트롤러 컨테이너화

### 도커 이미지 빌드

```bash
sudo -i
make
make docker-build docker-push IMG=markruler/gc:0.1.0
```

### Kind 클러스터에 배포

- [Kind 클러스터 생성](../bootstrap/kind.md)

```bash
make deploy IMG=markruler/gc:0.1.0
```

```bash
kubectl apply -f config/samples/gc_v1alpha1_ruler.yaml
watch kubectl get po
```

### Reconciliation 테스트

```diff
-  type: active
+  type: garbage
```

```bash
kubectl apply -f config/samples/gc_v1alpha1_ruler.yaml
```

## Clean up

```bash
make uninstall
kustomize build config/default | kubectl delete -f -
```
