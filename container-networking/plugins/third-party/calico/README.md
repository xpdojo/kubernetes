# Calico CNI

- [Calico CNI](#calico-cni)
  - [Quickstart](#quickstart)
    - [50 노드 이하](#50-노드-이하)
    - [50 노드 초과](#50-노드-초과)
    - [etcd datastore](#etcd-datastore)

## Quickstart

- [Install Calico networking and network policy for on-premises deployments](https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises)

### 50 노드 이하

```bash
# curl -LO https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### 50 노드 초과

```bash
# curl -LO https://docs.projectcalico.org/manifests/calico-typha.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico-typha.yaml
```

### etcd datastore

```bash
# curl -LO https://docs.projectcalico.org/manifests/calico-etcd.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico-etcd.yaml
```
