# 쿠버네티스 오퍼레이터 제작하기 (with Kubebuilder)

- [쿠버네티스 오퍼레이터 제작하기 (with Kubebuilder)](#쿠버네티스-오퍼레이터-제작하기-with-kubebuilder)
  - [참고 자료](#참고-자료)
    - [Best Practices](#best-practices)
    - [더 읽을 거리](#더-읽을-거리)
  - [Quickstart](#quickstart)
    - [큐브빌더 `Kubebuilder` 설치](#큐브빌더-kubebuilder-설치)
    - [`kustomize` 설치](#kustomize-설치)
    - [프로젝트 생성](#프로젝트-생성)
    - [API 생성](#api-생성)
    - [CRD 생성](#crd-생성)
    - [큐브빌더의 마커(Marker)란?](#큐브빌더의-마커marker란)
    - [매니페스트 생성](#매니페스트-생성)
    - [컨트롤 루프 생성](#컨트롤-루프-생성)
  - [테스트](#테스트)
    - [도커 이미지 빌드](#도커-이미지-빌드)
    - [Kind 클러스터에 배포](#kind-클러스터에-배포)
    - [Reconciliation 테스트](#reconciliation-테스트)
    - [Clean up](#clean-up)

## 참고 자료

- [kubernetes-sigs/cluster-api](https://github.com/kubernetes-sigs/cluster-api)
- [오퍼레이터 허브](https://operatorhub.io/)
- [The Kubebuilder Book](https://book.kubebuilder.io/)
- [Write a Kubernetes Operator in Go with Ellen Körbes](https://youtu.be/85dKpsFFju4) - Kinvolk
- [Kubernetes Kubebuilder를 이용한 Operator 개발](https://ssup2.github.io/programming/Kubernetes_Kubebuilder/) - ssup2
- [Kubernetes Controller 구현해보기](https://getoutsidedoor.com/2020/05/09/kubernetes-controller-%EA%B5%AC%ED%98%84%ED%95%B4%EB%B3%B4%EA%B8%B0/) - zeroFruit

### Best Practices

- [Best practices for building Kubernetes Operators and stateful apps](https://cloud.google.com/blog/products/containers-kubernetes/best-practices-for-building-kubernetes-operators-and-stateful-apps) - Google Cloud
- [7 Best Practices for Writing Kubernetes Operators: An SRE Perspective](https://www.openshift.com/blog/7-best-practices-for-writing-kubernetes-operators-an-sre-perspective) - Red Hat
- [애플리케이션 자동화를 위한 쿠버네티스 오퍼레이터 개발](https://youtu.be/abHOcr-HTI4) - 한우형
- [OpenShift Container Platform Operators](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.3/html-single/operators/index) - Red Hat

### 더 읽을 거리

- [Kubernetes operators for resource management](https://www.stephenzoio.com/kubernetes-operators-for-resource-management/)
- [Tutorial: Deep Dive into the Operator Framework for...](https://youtu.be/8_DaCcRMp5I) - Melvin Hillsman, Michael Hrivnak, & Matt Dorn
- [Learning Concurrent Reconciling](http://openkruise.io/en-us/blog/blog2.html) - FEI GUO
- [Deep analysis of Kubebuilder: making writing CRD easier](https://laptrinhx.com/deep-analysis-of-kubebuilder-making-writing-crd-easier-3037683434/) - Liu Yang
- [Building an operator for Kubernetes with kubebuilder](https://itnext.io/building-an-operator-for-kubernetes-with-kubebuilder-17cbd3f07761) - Philippe Martin
- [Writing a Kubernetes operator using Kubebuilder](https://youtu.be/Fp0QUf0Bwm0) - Velocity London 2018
- [Under the hood of Kubebuilder framework](https://itnext.io/under-the-hood-of-kubebuilder-framework-ff6b38c10796) - CloudARK
- [Building Cloud-Native Applications with Kubebuilder and Kind](https://caylent.com/building-cloud-native-applications-with-kubebuilder-and-kind) - Gabriel Garrido
- [Building your own kubernetes CRDs](https://itnext.io/building-your-own-kubernetes-crds-701de1c9a161) - Pongsatorn Tonglairoum
- [Kubebuilder v2 User Guide](https://www.programmersought.com/article/13635893077/)
- [Writing and testing Kubernetes webhooks using Kubebuilder v2](https://ymmt2005.hatenablog.com/entry/2019/08/10/Writing_and_testing_Kubernetes_webhooks_using_Kubebuilder_v2)
- [Kubernetes CRD Development Guide](https://developpaper.com/kubernetes-crd-development-guide/)
- [Getting Started with Kubernetes | Operator and Operator Framework](https://www.alibabacloud.com/blog/getting-started-with-kubernetes-%7C-operator-and-operator-framework_596320) - Alibaba Cloud

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

### 프로젝트 생성

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

### API 생성

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

### CRD 생성

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

### 큐브빌더의 마커(Marker)란?

- 유틸리티 코드와 쿠버네티스 매니페스트 파일을 생성 시 메타 데이터 역할을 합니다.
- 참고 자료
  - [kubebuilder markers](https://book.kubebuilder.io/reference/markers.html)
  - [kubernetes/code-generator](https://github.com/kubernetes/code-generator)

```go
// +<tag_name>[=value]
```

### 매니페스트 생성

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

### 컨트롤 루프 생성

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
```

```bash
sudo kubectl apply -f config/samples/gc_v1alpha1_ruler.yaml
sudo watch kubectl get ruler
```

## 테스트

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

### Clean up

```bash
make uninstall
kustomize build config/default | kubectl delet -f -
```
