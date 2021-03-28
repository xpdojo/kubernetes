# Elastic Cluster on Kubernetes (ECK)

- [Elastic Cluster on Kubernetes (ECK)](#elastic-cluster-on-kubernetes-eck)
  - [NFS Provisioner](#nfs-provisioner)
  - [Install Elastic Stack using Helm](#install-elastic-stack-using-helm)
  - [Install Elastic Stack using Operator](#install-elastic-stack-using-operator)

## NFS Provisioner

- [NFS Client Provisioner 이용 가이드 - Naver Cloud](https://docs.ncloud.com/ko/vnks/nks-nfs_client_provisioner.html)
- [Set up NFS server](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04)

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

```bash
helm install nas-storage stable/nfs-client-provisioner \
--set nfs.server=__NAS_IP__ \
--set nfs.path=__NAS_PATH__
```

```bash
kubectl get sc
# kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Install Elastic Stack using Helm

- [Docs](https://github.com/elastic/helm-charts/blob/master/elasticsearch/README.md)

```bash
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
```

- 차트만 다운로드 받고 싶다면

```bash
helm pull elasticsearch elastic/elasticsearch
helm pull kibana elastic/kibana
```

## Install Elastic Stack using Operator

- [Quickstart](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html)
- [Deploy ECK in your Kubernetes cluster](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html)

```bash
kubectl apply -f https://download.elastic.co/downloads/eck/1.4.1/all-in-one.yaml
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

- [elastic/cloud-on-k8s](https://github.com/elastic/cloud-on-k8s)
- [Deploy an Elasticsearch cluster](https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-quickstart.html)
- [Volume claim templatesedit](https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-volume-claim-templates.html)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.11.2
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 5Gi
        storageClassName: nfs
EOF
```

```bash
kubectl get elasticsearch
# NAME         HEALTH   NODES   VERSION   PHASE   AGE
# quickstart   green    1       7.11.2    Ready   20m
```

```bash
kubectl get pods --selector='elasticsearch.k8s.elastic.co/cluster-name=quickstart' -o wide
# NAME                      READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
# quickstart-es-default-0   1/1     Running   0          21m   172.18.54.85   esxi05-vm03   <none>           <none>
```

```bash
kubectl logs -f quickstart-es-default-0
kubectl describe po quickstart-es-default-0
```

```bash
PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
# curl -u "elastic:$PASSWORD" -k "https://quickstart-es-http:9200"
kubectl port-forward service/quickstart-es-http 9200
curl -u "elastic:$PASSWORD" -k "https://172.18.54.85:9200"
```
