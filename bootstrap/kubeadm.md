# Creating a cluster with kubeadm

- [Creating a cluster with kubeadm](#creating-a-cluster-with-kubeadm)
  - [Create Cluster](#create-cluster)
    - [Ubuntu 20.04](#ubuntu-2004)
    - [Enable network bridge for k8s](#enable-network-bridge-for-k8s)
    - [Control Plane](#control-plane)
    - [Worker Node](#worker-node)
  - [Clean up](#clean-up)

## Create Cluster

- [Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

### Ubuntu 20.04

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
apt list kubeadm -a
apt-get install kubeadm=1.18.17-00
apt-mark hold kubelet kubeadm kubectl
```

### Enable network bridge for k8s

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

- [token](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/)

```bash
kubeadm token list
# none
kubeadm token create --print-join-command --ttl=0
# <token>
cat /etc/kubernetes/pki/tokens.csv
```

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
# <hash>
```

```bash
kubectl -n kube-system get cm kubeadm-config -o yaml
```

- [Install Calico CNI](https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises)

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Worker Node

```bash
# kubeadm join --token <token> <control-plane-host>:6443 --discovery-token-ca-cert-hash sha256:<hash>
kubeadm join 192.168.7.182:6443 --token j9hs6q.qqmixdn74lksqpl0 --discovery-token-ca-cert-hash sha256:3c18620c7b79f2c90a9268ea0c322536fa0b4c8b4bb5b0f34fb702b321436585
```

## [Clean up](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down)

- Remove Worker Node

```bash
# on control-plane
kubectl get nodes
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
```

```bash
kubeadm reset
```

```bash
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
iptables -L -v
# ipvsadm -C
```

```bash
kubectl delete node <node name>
```

- Remove Control Plane

```bash
kubeadm reset
```

```bash
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
iptables -L -v
# ipvsadm -C
```
