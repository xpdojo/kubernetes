# 개발자 가이드

- [Guide](https://github.com/kubernetes-sigs/cluster-api/blob/master/docs/book/src/developer/guide.md)
- [with Tilt](https://github.com/kubernetes-sigs/cluster-api/blob/master/docs/book/src/developer/tilt.md)

- [개발자 가이드](#개발자-가이드)
  - [Components](#components)
  - [사전 준비](#사전-준비)
  - [Kind 클러스터 생성](#kind-클러스터-생성)
  - [Cert-Manager](#cert-manager)
  - [Build and Deploy](#build-and-deploy)
    - [with Tilt](#with-tilt)
    - [w/o Tilt](#wo-tilt)
  - [Kustomize](#kustomize)

## Components

![components](../../../images/cluster/components.png)

_출처: [(proposal) Clusterctl redesign - Improve user experience and management across Cluster API providers](https://github.com/kubernetes-sigs/cluster-api/blob/release-0.3/docs/proposals/20191016-clusterctl-redesign.md)_

## 사전 준비

- [Docker](https://docs.docker.com/install/) v19.03+
  - [Cluster API Provider Docker (CAPD)](https://github.com/kubernetes-sigs/cluster-api/tree/master/test/infrastructure/docker)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) v0.9+
- [Kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md)
- [Kubebuilder](../../../kubernetes-katas/operator/building-operator.md)
- [Tilt](https://docs.tilt.dev/install.html) v0.12.0+

```bash
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
```

- ~~[gcloud](https://cloud.google.com/sdk/docs/install)~~

```bash
# 1. 패키지 소스로 Cloud SDK 배포 URI를 추가합니다.
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
# 2. Google Cloud 공개 키를 가져옵니다.
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
# 3. Cloud SDK를 업데이트하고 설치합니다.
sudo apt-get update && sudo apt-get install google-cloud-sdk
```

- Cluster API 리포지터리 클론

```bash
git clone https://github.com/kubernetes-sigs/cluster-api.git
```

- [envsubst](https://github.com/drone/envsubst)

```bash
cd cluster-api
make envsubst
```

- 프로바이더(AWS, Openstack, ...) 리포지터리 클론

```bash
TODO:
```

## Kind 클러스터 생성

- [bootstrap/kind](../../bootstrap/kind.md)

## [Cert-Manager](https://github.com/jetstack/cert-manager)

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
kubectl wait --for=condition=Available --timeout=300s apiservice v1.cert-manager.io
```

## Build and Deploy

### with Tilt

```bash
tilt up
```

### w/o Tilt

- `CAPI`(Cluster API), `CAPD`(Docker provider) 2가지를 빌드해야 합니다.

```diff
# vi Makefile
- REGISTRY ?= gcr.io/$(shell gcloud config get-value project)
+ REGISTRY ?= markruler

# vi test/infrastructure/docker/Makefile
- REGISTRY ?= gcr.io/$(shell gcloud config get-value project)
+ REGISTRY ?= markruler
```

```bash
make docker-build
make -C test/infrastructure/docker docker-build
make docker-push
```

## Kustomize

```diff
# vi config/manager/manager.yaml
- image: gcr.io/~
+ image: markruler/cluster-api-controller-amd64:dev

# vi test/infrastructure/docker/config/manager/manager.yaml
- image: gcr.io/~
+ image: markruler/cluster-api-controller-amd64:dev
```

```bash
make release-manifests
kubectl create ns system
kustomize build config/default | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build config/crd | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build config/rbac | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build config/manager | ./hack/tools/bin/envsubst | kubectl apply -f -
```

```bash
kustomize build test/infrastructure/docker/config/default | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build test/infrastructure/docker/config/crd | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build test/infrastructure/docker/config/rbac | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build test/infrastructure/docker/config/manager | ./hack/tools/bin/envsubst | kubectl apply -f -
```

```bash
kubectl get po -n capi-system
kubectl get po -n capd-system
```
