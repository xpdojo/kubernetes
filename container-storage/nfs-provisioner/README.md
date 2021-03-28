# NFS Provisioner

- [NFS Provisioner](#nfs-provisioner)
  - [참고 자료](#참고-자료)
    - [Kubernetes Concept](#kubernetes-concept)
  - [Quickstart](#quickstart)

## 참고 자료

- [NFS Client Provisioner 이용 가이드 Using NAS](https://docs.ncloud.com/ko/vnks/nks-nfs_client_provisioner.html) - Naver Cloud
- [helm/charts](https://github.com/helm/charts)
- [kubernetes-sigs/sig-storage-lib-external-provisioner](https://github.com/kubernetes-sigs/sig-storage-lib-external-provisioner)
- [Set up NFS server](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04)

### Kubernetes Concept

- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

## Quickstart

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

```bash
helm install nas-storage stable/nfs-client-provisioner \
--set nfs.server=__NAS_IP__ \
--set nfs.path=__NAS_PATH__
```

- `default` Storage Class 지정

```bash
kubectl get sc
```

```bash
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

- 쿠버네티스 v1.20부터 추가 플래그 필요

```diff
# /etc/kubernetes/manifests/kube-apiserver.yaml
+ - --feature-gates=RemoveSelfLink=false
```
