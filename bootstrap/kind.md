# kind

- [kind](#kind)
  - [References](#references)
  - [Install `kind`](#install-kind)
  - [Create Cluster](#create-cluster)
  - [kindnet](#kindnet)
  - [Ingress](#ingress)
  - [LoadBalancer](#loadbalancer)
  - [Delete Cluster](#delete-cluster)

## References

- [Docs](https://kind.sigs.k8s.io/)

## Install `kind`

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /some-dir-in-your-PATH/kind
```

## Create Cluster

```bash
# sudo kind create cluster --name operator-test --image kindest/node:1.18.12
sudo kind create cluster --config ./bootstrap/kind-config.yaml
```

```bash
sudo kind get clusters
```

## kindnet

- [aojea/kindnet](https://github.com/aojea/kindnet)
  - kind에 사용되는 CNI

```bash
sudo docker exec -it kind-control-plane bash
cat /etc/cni/net.d/10-kindnet.conflist
```

```json
{
  "cniVersion": "0.3.1",
  "name": "kindnet",
  "plugins": [
    {
      "type": "ptp",
      "ipMasq": false,
      "ipam": {
        "type": "host-local",
        "dataDir": "/run/cni-ipam-state",
        "routes": [
          {
            "dst": "0.0.0.0/0"
          }
        ],
        "ranges": [
          [
            {
              "subnet": "10.244.0.0/24"
            }
          ]
        ]
      },
      "mtu": 1500
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
```

## Ingress

- [Docs](https://kind.sigs.k8s.io/docs/user/ingress/)

## LoadBalancer

- [Docs](https://kind.sigs.k8s.io/docs/user/loadbalancer/)

## Delete Cluster

```bash
sudo kind delete cluster --name operator-test
```
