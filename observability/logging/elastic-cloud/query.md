# Elasticsearch Query

- [Elasticsearch Query](#elasticsearch-query)
  - [참고](#참고)
  - [Elasticsearch 쿼리](#elasticsearch-쿼리)
    - [사용자 정보 찾기](#사용자-정보-찾기)
    - [Health Check](#health-check)
    - [데이터 추가](#데이터-추가)
    - [Search `indices`](#search-indices)
    - [Search by `index`](#search-by-index)
      - [URL 파라미터를 사용한 쿼리](#url-파라미터를-사용한-쿼리)
      - [JSON (aka Elasticsearch Query DSL)을 사용한 쿼리](#json-aka-elasticsearch-query-dsl을-사용한-쿼리)
    - [Delete `index`](#delete-index)
    - [User 생성](#user-생성)
  - [Kibana 배포](#kibana-배포)
    - [Kibana 상태 확인](#kibana-상태-확인)
  - [Elastic (on Kubernetes)](#elastic-on-kubernetes)

## 참고

- [ElasticSearch 명령어 Cheat Sheet](https://www.bmc.com/blogs/elasticsearch-commands/)

## Elasticsearch 쿼리

### 사용자 정보 찾기

```bash
ELASTIC_PASSWORD=$(kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
ELASTIC_HOST=172.18.54.85
```

### Health Check

- [Cluster health API](https://www.elastic.co/guide/en/elasticsearch/reference/7.11/cluster-health.html)

```bash
# kubectl port-forward service/quickstart-es-http 9200
# curl -XGET -u "elastic:2Yhme41m43PAIzHWHt568e82root" -k "http://10.109.74.193:9200"
```

```bash
# curl -XGET "https://192.167.7.182:9200/_cluster/health?pretty"
# curl -XGET "https://192.167.7.182:9200?pretty"
# curl -XGET "https://192.167.7.182:9200/_cat/nodes?v"
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200/_cluster/health?pretty"
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200?pretty"
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200/_cat/nodes?v"
```

### 데이터 추가

- 여기서는 그냥 kibana 예제 데이터를 넣는다.

```bash
vi test-data.json
curl -s -XPOST -L 'http://10.109.74.193:9200/{index}/_bulk?pretty&refresh' -H "Content-Type: application/json" --data-binary "@test-data.json"
```

### Search `indices`

```bash
# curl -XGET 'http://10.109.74.193:9200/_cat'
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
# curl -XGET 'http://10.109.74.193:9200/_cat/indices?v'
curl -u "elastic:$ELASTIC_PASSWORD" -k "https://${ELASTIC_HOST}:9200/_cat/indices?v"
```

- [QueryDSL string query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html)

```bash
curl -s -XPOST -L 'http://10.109.74.193:9200/{index}/_msearch?pretty' --data-binary "@test-query.json"
```

### Search by `index`

- [다양한 검색 방법 (Search API)](https://victorydntmd.tistory.com/313)
- [대량 추가/조회 (Bulk API, MultiSearch API)](https://victorydntmd.tistory.com/316)

```bash
curl -XGET 'http://10.109.74.193:9200/_all/_search?pretty'
curl -XGET 'http://10.109.74.193:9200/metricbeat-*/_search?pretty'
```

```bash
export $ES_INDEX=yna_news_total_202104
curl -XGET 'http://10.109.74.193:9200/$ES_INDEX/_search?pretty'
```

```json
{
  "took" : 1,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 74,
      "relation" : "eq"
    },
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "yna_news_total_202104",
        "_type" : "string",
        "_id" : "s8FSsHgBux578-pKK8fj",
        "_score" : 1.0,
        "_source" : {
          "title" : "...",
          "content" : "...",
          "url" : "...",
          "article_date" : "2021-04-08T15:04:00+09:00",
          "@timestamp" : "2021-04-08T07:11:18.499756592Z",
          "analyzed_words" : []
        }
      },
      ...
    ]
  }
}
```

#### URL 파라미터를 사용한 쿼리

```bash
export $ES_INDEX=yna_news_total_202104
curl -XGET 'http://10.109.74.193:9200/$ES_INDEX/_search?pretty=true&q=school:Harvard'
```

#### JSON (aka Elasticsearch Query DSL)을 사용한 쿼리

```bash
curl -XGET http://10.109.74.193:9200/yna_news_total_202104/_search?pretty \
--header 'Content-Type: application/json' -d '
{
  "query" : {
    "match_all" : {}
  }
}'
```

- [range query](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-range-query.html)

```bash
curl -XGET http://10.109.74.193:9200/yna_news_total_202104/_search?pretty \
--header 'Content-Type: application/json' -d '
{
  "query" : {
    "range" : {
      "article_date": {
        "time_zone": "+09:00",
        "gte": "2021-04-08T15:33:20",
        "lte": "now"
      }
    }
  }
}'
```

### Delete `index`

```bash
export $ES_INDEX=yna_news_total_202104
curl -XDELETE 'http://10.109.74.193:9200/$ES_INDEX'
```

```json
{ "acknowledged": true }
```

### User 생성

```bash
curl -XPOST http://10.109.74.193:9200//_security/user/{username} \
--header 'Content-Type: application/json' -d '
  {
    "password": "qwe123",
    "roles": ["superuser"]
  }
'
```

## Kibana 배포

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
# kubectl port-forward service/quickstart-kb-http 5601
kubectl port-forward service/quickstart-kb-http --address 0.0.0.0 5601:5601 &
kubectl get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

### Kibana 상태 확인

```bash
curl -XGET "http://10.109.74.193:5601/status" -I
```

## Elastic (on Kubernetes)

```bash
# Get password
kubectl get secret <elasticsearch-secret> -o=jsonpath='{.data.elastic}' | base64 --decode; echo

# query
curl -u "$ELASTIC_USERNAME:$ELASTIC_PASSWORD" -k "https://<elasticsearch-http-service>:9200"
```
