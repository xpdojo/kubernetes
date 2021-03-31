# Cluster API 스터디

- [Cluster API 스터디](#cluster-api-스터디)
  - [Cluster API란?](#cluster-api란)
  - [지원되는 프로바이더 목록](#지원되는-프로바이더-목록)
  - [Kubernetes Korea Group 스터디](#kubernetes-korea-group-스터디)
  - [테스트 환경](#테스트-환경)
    - [OS](#os)
    - [`kind`](#kind)
    - [`kubectl`](#kubectl)
    - [`clusterctl`](#clusterctl)

## Cluster API란?

[지원되는 프로바이더](https://cluster-api.sigs.k8s.io/reference/providers.html) 환경에서
컴퓨팅 노드와 클러스터 등을 쿠버네티스 컨트롤러를 통해 관리할 수 있게 만들어줍니다.
[Cluster API 프로젝트](https://github.com/kubernetes-sigs/cluster-api)에는
현재 [다양한 컨트롤러](https://github.com/kubernetes-sigs/cluster-api/tree/master/docs/book/src/developer/architecture/controllers)가 개발되었습니다.
아래 다이어그램는 매니지먼트 클러스터가 Cluster API 컨트롤러를 통해 워크로드 클러스터(각 프로바이더)를 관리하는 형상입니다.

![management-workload-separate-clusters](../../images/cluster/management-workload-separate-clusters.png)

_[출처: The Cluster API Book](https://cluster-api.sigs.k8s.io/reference/versions.html)_

## 지원되는 프로바이더 목록

| Abbreviation | Full name                                                                                                                                              | [Label](https://github.com/kubernetes-sigs/cluster-api/blob/master/docs/book/src/clusterctl/provider-contract.md#labels) |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| CAPI         | [Cluster API](https://github.com/kubernetes-sigs/cluster-api)                                                                                          | `cluster.x-k8s.io/provider=cluster-api`                                                                                  |
| CAPA         | [Cluster API Provider AWS](https://github.com/kubernetes-sigs/cluster-api-provider-aws)                                                                | `cluster.x-k8s.io/provider=infrastructure-aws`                                                                           |
| CAPG         | [Cluster API Provider GCP](https://github.com/kubernetes-sigs/cluster-api-provider-gcp)                                                                | `cluster.x-k8s.io/provider=infrastructure-gcp`                                                                           |
| CAPO         | [Cluster API Provider OpenStack](https://github.com/kubernetes-sigs/cluster-api-provider-openstack)                                                    | `cluster.x-k8s.io/provider=infrastructure-openstack`                                                                     |
| CAPV         | [Cluster API Provider vSphere](https://github.com/kubernetes-sigs/cluster-api-provider-vsphere)                                                        | `cluster.x-k8s.io/provider=infrastructure-vsphere`                                                                       |
| CAPZ         | [Cluster API Provider Azure](https://github.com/kubernetes-sigs/cluster-api-provider-azure)                                                            | `cluster.x-k8s.io/provider=infrastructure-azure`                                                                         |
| CABPK        | [Cluster API Boostrap Provider Kubeadm](https://github.com/kubernetes-sigs/cluster-api/blob/v0.3.14/docs/book/src/tasks/kubeadm-bootstrap.md)          | `cluster.x-k8s.io/provider=bootstrap-kubeadm`                                                                            |
| CACPK        | [Cluster API Control Plane Provider Kubeadm](https://github.com/kubernetes-sigs/cluster-api/blob/v0.3.14/docs/book/src/tasks/kubeadm-control-plane.md) | `cluster.x-k8s.io/provider=control-plane-kubeadm`                                                                        |
| ...          | ...                                                                                                                                                    | ...                                                                                                                      |

## Kubernetes Korea Group 스터디

| #   | date | topic                 | video                                   | slide                                                                                                     |
| --- | ---- | --------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1   | 2/17 | Quickstart            | [youtube](https://youtu.be/N_JpmdBlNLo) | [pdf](https://drive.google.com/file/d/1_2lS_qkvr_4LD0bP5_L2k71kMdPjIRgu/view)                             |
| 2   | 3/3  | Objects & Controllers | [youtube](https://youtu.be/duKW0DkJ9Zo) | [google slides](https://docs.google.com/presentation/d/1eohUe_i_7hIW_XycQwujAqRLGGSfNoR_AcDoWDrxF_M/edit) |
| 3   | 3/17 | CAPG & Kustomize      | [youtube](https://youtu.be/gCl4HlveYAo) | [google slides](https://docs.google.com/presentation/d/1XwvCRgViO2pUn3hSgqzNWlQhHXKamWO69CjyNv2MR58/edit) |
| 4   | 3/31 | -                     | -                                       | -                                                                                                         |
| 5   | 4/14 | -                     | -                                       | -                                                                                                         |
| 6   | 4/28 | -                     | -                                       | -                                                                                                         |

## 테스트 환경

### OS

- macOS Catalina (v10.15.7)
- Ubuntu Linux (20.04 - Focal Fossa)

### [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/)

- 도커 컨테이너로 쿠버네티스 클러스터를 생성할 수 있는 도구입니다.

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-$(uname)-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
kind version
```

```bash
kind completion zsh # `bash`, `zsh`, `fish`
# kind create cluster --name=capi
kind create cluster --name=capi --config=../bootstrap/kind-config.yaml
kubectl config current-context
# kind-capi
kubectl cluster-info --context kind-capi
# Kubernetes control plane is running at https://127.0.0.1:54301
# KubeDNS is running at https://127.0.0.1:54301/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

Kubernetes API를 사용하기 위한 CLI 도구입니다.

```bash
# curl -LO https://dl.k8s.io/release/v1.20.0/bin/darwin/amd64/kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl.sha256"
echo "$(<kubectl.sha256)  kubectl" | shasum -a 256 --check
# kubectl: OK
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl && \
sudo chown root: /usr/local/bin/kubectl

kubectl version --client
```

### [`clusterctl`](https://cluster-api.sigs.k8s.io/user/quick-start.html)

- Cluster API를 사용하기 위한 CLI 도구입니다.

```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.14/clusterctl-$(uname)-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl
clusterctl version
clusterctl completion zsh # `bash`, `zsh`
```
