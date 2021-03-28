# 개발자 가이드

- [Guide](https://github.com/kubernetes-sigs/cluster-api/blob/master/docs/book/src/developer/guide.md)
- [with Tilt](https://github.com/kubernetes-sigs/cluster-api/blob/master/docs/book/src/developer/tilt.md)

- [개발자 가이드](#개발자-가이드)
  - [Components](#components)
  - [사전 준비](#사전-준비)
  - [Kind 클러스터 생성](#kind-클러스터-생성)
  - [Cert-Manager](#cert-manager)
  - [Tilt](#tilt)
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

- Cluster API 리포지터리 클론

```bash
git clone https://github.com/kubernetes-sigs/cluster-api.git
```

- [envsubst](https://github.com/drone/envsubst)

```bash
make envsubst
```

- 프로바이더(AWS, Openstack, ...) 리포지터리 클론

## Kind 클러스터 생성

- [bootstrap/kind](../../bootstrap/kind.md)

## [Cert-Manager](https://github.com/jetstack/cert-manager)

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
kubectl wait --for=condition=Available --timeout=300s apiservice v1.cert-manager.io
```

## Tilt

```bash
tilt up
```

## Kustomize

```bash
kustomize build config/ | ./hack/tools/bin/envsubst | kubectl apply -f -
kustomize build test/infrastructure/docker/config | ./hack/tools/bin/envsubst | kubectl apply -f -
```

```bash
kubectl get po -n capd-system
kubectl get po -n capi-system
```
