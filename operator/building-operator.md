# 쿠버네티스 오퍼레이터 제작하기 (with Kubebuilder)

- [쿠버네티스 오퍼레이터 제작하기 (with Kubebuilder)](#쿠버네티스-오퍼레이터-제작하기-with-kubebuilder)
  - [Prerequisite](#prerequisite)
    - [큐브빌더 `Kubebuilder` 설치](#큐브빌더-kubebuilder-설치)
    - [`kustomize` 설치](#kustomize-설치)
    - [Kind 클러스터 생성](#kind-클러스터-생성)
  - [Quickstart](#quickstart)
    - [스켈레톤 프로젝트 생성](#스켈레톤-프로젝트-생성)
    - [API 리소스 개발](#api-리소스-개발)
    - [Reconcile Loop 개발](#reconcile-loop-개발)
    - [컨트롤러 컨테이너화](#컨트롤러-컨테이너화)
    - [Reconciliation 테스트](#reconciliation-테스트)
  - [Clean up](#clean-up)

## Prerequisite

> Ubuntu 20.04 에서 테스트를 진행했습니다.

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
- `kustomize`로 매니페스트 파일을 생성합니다.

```bash
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin
```

### [Kind 클러스터 생성](../bootstrap/kind.md)

```bash
# bash
cat <<EOF | kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
EOF

# fish
printf "\
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
" | kind create cluster --config -
```

## [Quickstart](https://book.kubebuilder.io/quick-start.html)

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
kubebuilder create api --group example --version v1alpha1 --kind Machine
# Create Resource [y/n]
y
# Create Controller [y/n]
y
# Writing scaffold for you to edit...
# api/v1alpha1/machine_types.go
# controllers/machine_controller.go
# Running make:
# $ make
# go: creating new go.mod: module tmp
# go: found sigs.k8s.io/controller-tools/cmd/controller-gen in sigs.k8s.io/controller-tools v0.2.5
# /root/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
# go fmt ./...
# go vet ./...
# go build -o bin/manager main.go
```

```diff
# api/v1alph1/machine_types.go
type MachineSpec struct {
-  Foo string `json:"foo,omitempty"`
+  Role string `json:"role,omitempty"`
}

type MachineStatus struct {
+  Ready bool `json:"ready"`
}

// +kubebuilder:object:root=true
+  // +kubebuilder:printcolumn:name="role",type=string,JSONPath=`.spec.role`
+  // +kubebuilder:printcolumn:name="ready",type=boolean,JSONPath=`.status.ready`
+  // +kubebuilder:subresource:status

// Machine is the Schema for the machines API
type Machine struct {
  metav1.TypeMeta   `json:",inline"`
  metav1.ObjectMeta `json:"metadata,omitempty"`

  Spec   MachineSpec   `json:"spec,omitempty"`
  Status MachineStatus `json:"status,omitempty"`
}
```

> 큐브빌더의 마커(Marker)란?

- 유틸리티 코드와 쿠버네티스 매니페스트 파일을 생성하기 위한 메타 데이터입니다.
- 참고 자료
  - [kubebuilder markers](https://book.kubebuilder.io/reference/markers.html)
  - [kubernetes-sigs/controller-tools/controller-gen v0.2.5](https://github.com/kubernetes-sigs/controller-tools/blob/v0.2.5/cmd/controller-gen/main.go)
  - ~~[kubernetes/code-generator](https://github.com/kubernetes/code-generator)~~

```go
// +<tag_name>[=value]
```

- CRD 생성 및 배포

```bash
sudo -i
make install
# go: creating new go.mod: module tmp
# go: found sigs.k8s.io/controller-tools/cmd/controller-gen in sigs.k8s.io/controller-tools v0.2.5
# /root/go/bin/controller-gen "crd:trivialVersions=true" rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases
# kustomize build config/crd | kubectl apply -f -
# Warning: apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
# customresourcedefinition.apiextensions.k8s.io/machines.example.markruler.com created
```

```bash
kubectl get crd
# NAME                      CREATED AT
# machines.example.markruler.com   2021-03-31T09:54:26Z

kubectl api-resources | grep markruler
# NAME                              SHORTNAMES   APIVERSION                        NAMESPACED   KIND
# machines                                       example.markruler.com/v1alpha1    true         Machine

kubectl get machines
# No resources found
```

- 리소스 생성

```bash
# bash
cat > config/samples/example_v1alpha1_machine.yaml <<EOF
apiVersion: example.markruler.com/v1alpha1
kind: Machine
metadata:
  name: machine-sample
spec:
  role: worker
EOF

# fish
printf "\
apiVersion: example.markruler.com/v1alpha1
kind: Machine
metadata:
  name: machine-sample
spec:
  role: worker
" | cat > config/samples/example_v1alpha1_machine.yaml
```

```bash
kubectl apply -f config/samples/example_v1alpha1_machine.yaml
# ruler.gc.markruler.com/ruler-sample created

kubectl get machines
# NAME             ROLE     READY
# machine-sample   worker
```

### Reconcile Loop 개발

> 주의: 이 소스 코드는 [Best Practice](README.md#best-practices)가 아닙니다. 테스트용으로만 사용해주세요.

```go
// controllers/machines_controller.go
func (r *RulerReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
  ctx := context.Background()
  log := r.Log.WithValues("machine", req.NamespacedName)

  log.Info("Informer => Work Queue => Controller!")

  var machine examplev1alpha1.Machine

  if err := r.Get(ctx, req.NamespacedName, &machine); err != nil {
    log.Info("error GET Machine", "name", req.NamespacedName)
    return ctrl.Result{}, client.IgnoreNotFound(err)
  }

  if machine.Spec.Role == "garbage" {
    if err := r.Delete(ctx, &machine); err != nil {
      log.Info("error DELETE Machine", "deleteName", req.NamespacedName)
      return ctrl.Result{}, client.IgnoreNotFound(err)
    }
    log.Info(">>> Deleted machine", "deleteName", req.NamespacedName)
    return ctrl.Result{}, nil
  }

  if !machine.Status.Ready {
    log.Info("Machine is not ready")
  }

  if machine.Spec.Role == "" {
    machine.Spec.Role = "garbage"
  }

  if machine.Spec.Role == "worker" {
    machine.Status.Ready = true
  } else {
    machine.Status.Ready = false
  }

  if err := r.Status().Update(ctx, &machine); err != nil {
    log.Info("error UPDATE status", "name", req.NamespacedName)
    return ctrl.Result{}, client.IgnoreNotFound(err)
  } else {
    log.Info("Update machine", "updatedName", req.NamespacedName)
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

sudo kubectl apply -f config/samples/example_v1alpha1_machine.yaml
sudo watch kubectl get ruler
```

### 컨트롤러 컨테이너화

```bash
sudo -i
make
make docker-build docker-push IMG=markruler/example:0.1.0
```

```bash
make deploy IMG=markruler/example:0.1.0
kubectl get po -A
# NAMESPACE            NAME                                             READY   STATUS    RESTARTS   AGE
# example-system       example-controller-manager-55dff57b9d-s62tj      2/2     Running   0          15s
```

```bash
kubectl apply -f config/samples/example_v1alpha1_machine.yaml
watch kubectl get machine
```

### Reconciliation 테스트

```diff
-  type: active
+  type: garbage
```

```bash
kubectl apply -f config/samples/example_v1alpha1_machine.yaml
```

## Clean up

```bash
make uninstall
kustomize build config/default | kubectl delete -f -
```
