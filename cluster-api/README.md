# Cluster API 스터디

## Supported Providers list

- [reference](https://cluster-api.sigs.k8s.io/reference/providers.html)

| Abbreviation |                                                                                                                                               |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| CAPI         | [Cluster API](https://github.com/kubernetes-sigs/cluster-api)                                                                                 |
| CAPA         | [Cluster API Provider AWS](https://github.com/kubernetes-sigs/cluster-api-provider-aws)                                                       |
| CAPG         | [Cluster API Provider GCP](https://github.com/kubernetes-sigs/cluster-api-provider-gcp)                                                       |
| CAPO         | [Cluster API Provider OpenStack](https://github.com/kubernetes-sigs/cluster-api-provider-openstack)                                           |
| CAPV         | [Cluster API Provider vSphere](https://github.com/kubernetes-sigs/cluster-api-provider-vsphere)                                               |
| CAPZ         | [Cluster API Provider Azure](https://github.com/kubernetes-sigs/cluster-api-provider-azure)                                                   |
| CABPK        | [Cluster API Boostrap Provider Kubeadm](https://github.com/kubernetes-sigs/cluster-api/blob/v0.3.14/docs/book/src/tasks/kubeadm-bootstrap.md) |

## Kubernetes Korea Group - [Youtube](https://www.youtube.com/channel/UC1BCaPrwl7KK4KkQVaNK3Dg)

| #   | date | topic                 | video                                   | slide                                                                                                     |
| --- | ---- | --------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1   | 2/17 | Quickstart            | [youtube](https://youtu.be/N_JpmdBlNLo) | [pdf](https://drive.google.com/file/d/1_2lS_qkvr_4LD0bP5_L2k71kMdPjIRgu/view)                             |
| 2   | 3/3  | Objects & Controllers | [youtube](https://youtu.be/duKW0DkJ9Zo) | [google slides](https://docs.google.com/presentation/d/1eohUe_i_7hIW_XycQwujAqRLGGSfNoR_AcDoWDrxF_M/edit) |
| 3   | 3/17 | CAPG & Kustomize      | -                                       | [google slides](https://docs.google.com/presentation/d/1XwvCRgViO2pUn3hSgqzNWlQhHXKamWO69CjyNv2MR58/edit) |
| 4   | 3/31 | -                     | -                                       | -                                                                                                         |
| 5   | 4/14 | -                     | -                                       | -                                                                                                         |
| 6   | 4/28 | -                     | -                                       | -                                                                                                         |

## 공통 테스트 환경

### 테스트 OS

- macOS Catalina (v10.15.7)
- Ubuntu Linux 20.04

## [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/)

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
kind create cluster --name=capi --config=kind-config.yaml
kubectl config current-context
# kind-capi
kubectl cluster-info --context kind-capi
# Kubernetes control plane is running at https://127.0.0.1:54301
# KubeDNS is running at https://127.0.0.1:54301/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

## [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

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

## [`clusterctl`](https://cluster-api.sigs.k8s.io/user/quick-start.html)

- Cluster API를 사용하기 위한 CLI 도구입니다.

```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.14/clusterctl-$(uname)-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl
clusterctl version
clusterctl completion zsh # `bash`, `zsh`
```
