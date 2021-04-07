# elastic/helm-charts

- [Docs](https://github.com/elastic/helm-charts/blob/master/elasticsearch/README.md)

```bash
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
```

- 차트만 다운로드 받고 싶다면

```bash
helm pull elastic/elasticsearch
helm pull elastic/kibana
```
