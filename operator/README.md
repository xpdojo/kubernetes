# Kubernets Operator

- [Kubernets Operator](#kubernets-operator)
  - [오퍼레이터 패턴](#오퍼레이터-패턴)
  - [오퍼레이터 사용 동기](#오퍼레이터-사용-동기)
    - [Helm](#helm)
    - [Operator](#operator)
  - [오퍼레이터는 상태 머신이 아니다](#오퍼레이터는-상태-머신이-아니다)
    - [상태 머신](#상태-머신)
    - [쿠버네티스](#쿠버네티스)
  - [오퍼레이터 개발 방법](#오퍼레이터-개발-방법)

[출처: 애플리케이션 자동화를 위한 쿠버네티스 오퍼레이터 개발 - 한우형](https://www.youtube.com/watch?v=abHOcr-HTI4)

## 오퍼레이터 패턴

- [Controller](https://kubernetes.io/docs/concepts/architecture/controller/) - Kubernetes
- [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) - Kubernetes
- [Introducing Operators: Putting Operational Knowledge into Software](https://web.archive.org/web/20170129131616/https://coreos.com/blog/introducing-operators.html) - CoreOS

![k8s-control-loop](../images/k8s-control-loop.png)

- 컨트롤러
  - 현재 상태를 사용자의 desired state에 일치시키는 프로그램
- 오퍼레이터
  - 컨트롤러 + 관리자(operator)의 운영 지식
  - 컨트롤러 패턴을 애플리케이션의 자동화에 사용하면 오퍼레이터

> 모든 오퍼레이터는 컨트롤러지만, 모든 컨트롤러는 오퍼레이터가 아니다.

## 오퍼레이터 사용 동기

![helm-vs-operator](../images/helm-vs-operator.png)

### Helm

- stateless 앱 배포에 적합 (항상은 아님)
- 비즈니스 로직이 모두 컨테이너 내부에 포함

### Operator

- stateful 앱 배포에 적합
- 배포 + 운영 + 원하는 모든 자동화
- Helm으로도 관리하기 힘들 정도로 선언적 파일들이 복잡해졌다면 오퍼레이터를 통해 한층 더 자동화를 해야 한다.
- 대신 오퍼레이터를 개발해야 하는 만큼 학습비용이 들어간다.
- 오퍼레이터도 단순하지만은 않다.

## 오퍼레이터는 상태 머신이 아니다

### 상태 머신

- f(now_state, input) = next_state
- 상태의 종류가 정확히 정의되어 있다.
- 상태에 따른 입력도 정의되어 있다.

### 쿠버네티스

- 현재 상태는 항상 관측을 통해 얻는다.
- 저장된 상태는 성능을 위해 존재한다.

## 오퍼레이터 개발 방법

- 라이브러리를 이용해서 밑바닥부터 개발
  - [client-go](https://github.com/kubernetes/client-go)
  - [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
- [추천] 오퍼레이터 제작 도구
  - [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)
  - [KUDO](https://kudo.dev/) (Kubernetes Universal Declarative Operator)
  - [Metacontroller](https://metacontroller.github.io/metacontroller/)
  - [오퍼레이터 프레임워크](https://operatorframework.io/)
    - [operator-sdk](https://github.com/operator-framework/operator-sdk)

> 영상에선 operator-sdk를 추천하지만 저는 [kubernetes-sigs/cluster-api](https://github.com/kubernetes-sigs/cluster-api)를 사용하면서 kubebuilder를 공부해야 했기 때문에 kubebuilder를 사용했습니다.
