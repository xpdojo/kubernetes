# Elasticsearch Query

- [Elasticsearch Query](#elasticsearch-query)
  - [Get password](#get-password)
  - [Health Check](#health-check)
  - [Deploy a Kibana instance](#deploy-a-kibana-instance)
  - [Add data](#add-data)
  - [Search indices](#search-indices)
  - [Search](#search)

## Get password

```bash
ELASTIC_PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
ELASTIC_HOST=172.18.54.85
```

## Health Check

- [Cluster health API](https://www.elastic.co/guide/en/elasticsearch/reference/7.11/cluster-health.html)

```bash
# kubectl port-forward service/quickstart-es-http 9200
# curl -XGET -u "elastic:2Yhme41m43PAIzHWHt568e82root" -k "http://192.168.7.182:9200"
```

```bash
# curl -XGET "https://192.167.7.182:9200/_cluster/health?pretty"
# curl -XGET "https://192.167.7.182:9200?pretty"
# curl -XGET "https://192.167.7.182:9200/_cat/nodes?v"
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200/_cluster/health?pretty"
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200?pretty"
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200/_cat/nodes?v"
```

## Deploy a Kibana instance

- [Docs](https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-deploy-kibana.html)

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

```bash
kubectl get kibana
kubectl get pod --selector='kibana.k8s.elastic.co/name=quickstart'
```

```bash
kubectl get service quickstart-kb-http
kubectl port-forward service/quickstart-kb-http 5601
kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

```bash
curl -XGET "http://192.168.7.182:5601/status" -I
```

## Add data

- 여기서는 그냥 kibana 예제 데이터를 넣는다.

```bash
vi test-data.json
curl -s -XPOST -L 'http://192.168.7.182:9200/{index}/_bulk?pretty&refresh' -H "Content-Type: application/json" --data-binary "@test-data.json"
```

## Search indices

```bash
# curl -XGET 'http://192.168.7.182:9200/_cat'
# =^.^=
# /_cat/allocation
# /_cat/shards
# /_cat/shards/{index}
# /_cat/master
# /_cat/nodes
# /_cat/indices
# /_cat/indices/{index}
# /_cat/segments
# /_cat/segments/{index}
# /_cat/count
# /_cat/count/{index}
# /_cat/recovery
# /_cat/recovery/{index}
# /_cat/health
# /_cat/pending_tasks
# /_cat/aliases
# /_cat/aliases/{alias}
# /_cat/thread_pool
# /_cat/plugins
# /_cat/fielddata
# /_cat/fielddata/{fields}
# curl -XGET 'http://192.168.7.182:9200/_cat/indices?v'
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200/_cat/indices?v"
```

- [QueryDSL string query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html)

```bash
curl -s -XPOST -L 'http://192.168.7.182:9200/{index}/_msearch?pretty' --data-binary "@test-query.json"
```

## Search

- [다양한 검색 방법 (Search API)](https://victorydntmd.tistory.com/313)
- [대량 추가/조회 (Bulk API, MultiSearch API)](https://victorydntmd.tistory.com/316)

```bash
curl -XGET 'http://192.168.7.182:9200/_all/_search?pretty'
curl -XGET 'http://192.168.7.182:9200/metricbeat-*/_search?pretty'
```
