# Kubernetes for Elastic Cluster

- [Kubernetes for Elastic Cluster](#kubernetes-for-elastic-cluster)
  - [Create Cluster](#create-cluster)
    - [Common](#common)
    - [Control Plane](#control-plane)
    - [Worker Node](#worker-node)
  - [NFS Provisioner](#nfs-provisioner)
  - [Install Elastic Stack using Helm](#install-elastic-stack-using-helm)
  - [Install Elastic Stack using Operator](#install-elastic-stack-using-operator)
  - [Clean up](#clean-up)

## Create Cluster

### Common

```bash
sudo -i
apt-get install -y docker.io
```

```bash
mkdir -p /mnt/docker-data

cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "/mnt/docker-data",
  "storage-driver": "overlay2",
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```

```bash
systemctl restart docker
docker info
```

```bash
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm
apt-mark hold kubelet kubeadm kubectl
```

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```

### Control Plane

```bash
kubeadm init
# kubectl taint nodes --all node-role.kubernetes.io/master-
```

```bash
kubeadm token list
# none
kubeadm token create
# <token>
```

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'
# <hash>
```

- [Install Calico CNI](https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises)

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Worker Node

```bash
kubectl -n kube-system get cm kubeadm-config -o yaml
```

```bash
# kubeadm join --token <token> <control-plane-host>:6443 --discovery-token-ca-cert-hash sha256:<hash>
kubeadm join 192.168.7.182:6443 --token j9hs6q.qqmixdn74lksqpl0 --discovery-token-ca-cert-hash sha256:3c18620c7b79f2c90a9268ea0c322536fa0b4c8b4bb5b0f34fb702b321436585
```

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

## [Clean up](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down)

- Remove Worker Node

```bash
# on control-plane
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
iptables -L -v
# ipvsadm -C
kubectl delete node <node name>
```

- Remove Control Plane

```bash
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
iptables -L -v
# ipvsadm -C
```
