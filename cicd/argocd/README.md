# ArgoCD

## 설치

- [Install Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/)

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 트러블슈팅

Pod가 Pending 상태에서 실행되지 않고,
이벤트에서 스케줄링하지 못한다는 메시지가 보였다.

```sh
kubectl -n argocd get ev --sort-by='.lastTimestamp'
```

```sh
NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    0/1     Pending   0          5m32s
argocd-applicationset-controller-9798b8cc4-7sjxn   0/1     Pending   0          5m32s
argocd-dex-server-64f465d857-kbjdc                 0/1     Pending   0          5m32s
argocd-notifications-controller-794b9d5bb9-tntdp   0/1     Pending   0          5m32s
argocd-redis-7b59bffbff-kcd7d                      0/1     Pending   0          5m32s
argocd-repo-server-c9888f4c5-hkrs2                 0/1     Pending   0          5m32s
argocd-server-6c48df7584-crtfv                     0/1     Pending   0          5m32s
```

```sh
kubectl get ev -n argocd
```

```sh
LAST SEEN   TYPE      REASON              OBJECT                                                  MESSAGE
25s         Warning   FailedScheduling    pod/argocd-application-controller-0                     0/1 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling..
```

확인해보니 `master` 혹은 `control-plane` 노드에는 taint가 걸려있었다.

```sh
kubectl describe no tost1
```

```sh
Name:               tost1
Roles:              control-plane
Labels:             ...
                    node-role.kubernetes.io/control-plane=
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
```

```sh
kubectl get no tost1 -o jsonpath='{.spec.taints}'
# [{"effect":"NoSchedule","key":"node-role.kubernetes.io/control-plane"}]
```

이를 해결하기 위해 contairol-plane 노드에서 taint를 빼주었다.

```sh
kubectl taint node tost1 node-role.kubernetes.io/control-plane:NoSchedule-
# node/tost1 untainted
```

```sh
kubectl get no tost1 -o jsonpath='{.spec.taints}'
#
```

```sh
kubectl -n argocd get ev --sort-by='.lastTimestamp'
# 115s        Normal    Scheduled                pod/argocd-application-controller-0                     Successfully assigned argocd/argocd-application-controller-0 to tost1
```

```sh
NAME                                               READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                    1/1     Running   0          7m
argocd-applicationset-controller-9798b8cc4-7sjxn   1/1     Running   0          7m
argocd-dex-server-64f465d857-kbjdc                 1/1     Running   0          7m
argocd-notifications-controller-794b9d5bb9-tntdp   1/1     Running   0          7m
argocd-redis-7b59bffbff-kcd7d                      1/1     Running   0          7m
argocd-repo-server-c9888f4c5-hkrs2                 1/1     Running   0          7m
argocd-server-6c48df7584-crtfv                     1/1     Running   0          7m
```

```sh
kubectl get ev -n argocd
```
