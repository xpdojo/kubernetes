# Elastic Cloud on Kubernetes (ECK)

- [Elastic Cloud on Kubernetes (ECK)](#elastic-cloud-on-kubernetes-eck)
  - [quickstart](#quickstart)
  - [Orchestrating Elastic Stack applicationse](#orchestrating-elastic-stack-applicationse)
    - [Run Elasticsearch on ECK](#run-elasticsearch-on-eck)
    - [Run Kibana on ECK](#run-kibana-on-eck)

## [quickstart](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html)

- [Install custom resource definitions and the operator with its RBAC rules](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html)

```bash
kubectl apply -f https://download.elastic.co/downloads/eck/1.4.1/all-in-one.yaml
```

- Monitor the operator logs

```bash
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

- [Deploy an Elasticsearch cluster](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-elasticsearch.html)
- [Volume claim templates](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-volume-claim-templates.html)

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
            storageClassName: <sc-name>
EOF
```

- [Deploy a Kibana instance](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-kibana.html)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 7.11.2
  count: 1
  elasticsearchRef:
    name: quickstart
EOF
```

## [Orchestrating Elastic Stack applicationse](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-orchestrating-elastic-stack-applications.html)

### [Run Elasticsearch on ECK](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-elasticsearch-specification.html)

- [Nodes orchestration](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-orchestration.html)

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.11.2
  nodeSets:
    - name: master-nodes
      count: 3
      config:
        node.roles: ["master"]
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 10Gi
            storageClassName: standard
    - name: data-nodes
      count: 10
      config:
        node.roles: ["data"]
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 1000Gi
            storageClassName: standard
```

### [Run Kibana on ECK](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-kibana.html)
