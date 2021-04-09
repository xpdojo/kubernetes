# Elastic Cloud on Kubernetes

- [Volume claim templates](https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-volume-claim-templates.html)
- The name of the volume claim must always be `elasticsearch-data`.

```yaml
spec:
  nodeSets:
    - name: default
      count: 3
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 5Gi
            storageClassName: standard
```

## 증상

- 위와 같이 설정을 했는데도 `Init:CrashLoopBackOff` 에러가 발생하고 자세한 로그도 없어서 디버깅할 방법이 없었다.
- 알고보니 firewall이 실행 중이어서 스토리지 클래스로 지정한 NFS가 제대로 동작하지 않았다.
- 마운트 디렉토리에 write는 되지만 다른 노드에서 share 할 수 없는 것을 확인할 수 있다.

## 솔루션

- `systemctl stop firewalld`
- `systemctl disable firewalld`
