# 쿠버네티스 오퍼레이터 제작하기

- [쿠버네티스 오퍼레이터 제작하기](#쿠버네티스-오퍼레이터-제작하기)
  - [참고 자료](#참고-자료)
  - [Quickstart](#quickstart)
    - [큐브빌더 `Kubebuilder` 설치](#큐브빌더-kubebuilder-설치)
    - [커스터마이즈 `Kustomize` 설치](#커스터마이즈-kustomize-설치)
    - [프로젝트 생성](#프로젝트-생성)
    - [API 생성](#api-생성)
    - [CRD 생성](#crd-생성)
    - [매니페스트 생성](#매니페스트-생성)
    - [컨트롤 루프 생성](#컨트롤-루프-생성)
  - [TODO: 도커 이미지 빌드](#todo-도커-이미지-빌드)
  - [TODO: Kind 클러스터에 배포](#todo-kind-클러스터에-배포)
  - [TODO: 테스트](#todo-테스트)
  - [큐브빌더의 마커(Marker)란?](#큐브빌더의-마커marker란)

## 참고 자료

- [kubernetes-sigs/cluster-api](https://github.com/kubernetes-sigs/cluster-api)
- [오퍼레이터 허브](https://operatorhub.io/)
- [The Kubebuilder Book](https://book.kubebuilder.io/)
- [Write a Kubernetes Operator in Go with Ellen Körbes](https://youtu.be/85dKpsFFju4) - Kinvolk
- [Kubernetes operators for resource management](https://www.stephenzoio.com/kubernetes-operators-for-resource-management/)
- [Tutorial: Deep Dive into the Operator Framework for...](https://youtu.be/8_DaCcRMp5I) - Melvin Hillsman, Michael Hrivnak, & Matt Dorn
- [Learning Concurrent Reconciling](http://openkruise.io/en-us/blog/blog2.html) - FEI GUO
- [Deep analysis of Kubebuilder: making writing CRD easier](https://laptrinhx.com/deep-analysis-of-kubebuilder-making-writing-crd-easier-3037683434/) - Liu Yang
- [Kubernetes Kubebuilder를 이용한 Operator 개발](https://ssup2.github.io/programming/Kubernetes_Kubebuilder/) - ssup2
- [Kubernetes Controller 구현해보기](https://getoutsidedoor.com/2020/05/09/kubernetes-controller-%EA%B5%AC%ED%98%84%ED%95%B4%EB%B3%B4%EA%B8%B0/) - zeroFruit
- [Building an operator for Kubernetes with kubebuilder](https://itnext.io/building-an-operator-for-kubernetes-with-kubebuilder-17cbd3f07761) - Philippe Martin
- [Writing a Kubernetes operator using Kubebuilder](https://youtu.be/Fp0QUf0Bwm0) - Velocity London 2018
- [Under the hood of Kubebuilder framework](https://itnext.io/under-the-hood-of-kubebuilder-framework-ff6b38c10796) - CloudARK
- [Building Cloud-Native Applications with Kubebuilder and Kind](https://caylent.com/building-cloud-native-applications-with-kubebuilder-and-kind) - Gabriel Garrido
- [Building your own kubernetes CRDs](https://itnext.io/building-your-own-kubernetes-crds-701de1c9a161) - Pongsatorn Tonglairoum
- [Kubebuilder v2 User Guide](https://www.programmersought.com/article/13635893077/)

## [Quickstart](https://book.kubebuilder.io/quick-start.html)

### 큐브빌더 `Kubebuilder` 설치

```bash
os=$(go env GOOS)
arch=$(go env GOARCH)
url -L https://go.kubebuilder.io/dl/2.3.1/${os}/${arch} | tar -xz -C /tmp/
sudo mv /tmp/kubebuilder_2.3.1_${os}_${arch} /usr/local/kubebuilder
export PATH=$PATH:/usr/local/kubebuilder/bin
```

### 커스터마이즈 `Kustomize` 설치

- [Docs](https://kubernetes-sigs.github.io/kustomize/installation/)

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

[유한 오토마타](https://en.wikipedia.org/wiki/Finite-state_machine)? A finite-state machine (FSM) or finite-state automaton (FSA, plural: automata), finite automaton, or simply a state machine, is a mathematical model of computation. It is an abstract machine that can be in exactly one of a finite number of states at any given time. The FSM can change from one state to another in response to some inputs; the change from one state to another is called a transition. An FSM is defined by a list of its states, its initial state, and the inputs that trigger each transition. Finite-state machines are of two types—deterministic finite-state machines and non-deterministic finite-state machines. A deterministic finite-state machine can be constructed equivalent to any non-deterministic one.

![automata](../images/automata-theory.png)

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

## TODO: 도커 이미지 빌드

```bash
make
make docker-build docker-push IMG=markruler/gc:0.1.0
make deploy
```

## TODO: Kind 클러스터에 배포

- [Kind 클러스터 생성](../bootstrap/kind.md)

## TODO: 테스트

```bash

```

## 큐브빌더의 마커(Marker)란?

- [kubebuilder markers](https://book.kubebuilder.io/reference/markers.html)
- [kubernetes/code-generator](https://github.com/kubernetes/code-generator)

```go
// +<tag_name>[=value]
```
