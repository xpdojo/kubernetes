# Creating a cluster with kubeadm

- [Creating a cluster with kubeadm](#creating-a-cluster-with-kubeadm)
  - [Create Cluster](#create-cluster)
    - [Ubuntu 20.04](#ubuntu-2004)
    - [Configure network bridge for k8s](#configure-network-bridge-for-k8s)
    - [Control Plane](#control-plane)
    - [Worker Node](#worker-node)
  - [Clean up](#clean-up)

## Create Cluster

- [Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

### Ubuntu 20.04

- [Docker setup](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)

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
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "insecure-registries": [
    "worker01:5000",
    "192.168.7.191:5000",
  ]
}
EOF

systemctl enable docker
systemctl daemon-reload
systemctl restart docker
```

- cgroup driver의 기본값이 `cgoupfs`이기 때문에 변경해준다.
- `systemd`를 사용해야 하는 이유는 없다. 다만 같이 쓰지 않도록 주의한다. [참고](https://tech.kakao.com/2020/06/29/cgroup-driver/)

```bash
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

```bash
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab
```

- [kubernetes/issues/7294](https://github.com/kubernetes/kubernetes/issues/7294)
- [kubernetes/issues/53533](https://github.com/kubernetes/kubernetes/issues/53533)
- 파드의 QoS, Automatic bin packing, 예측 가능성, 일관성, 성능 저하

```bash
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

```bash
systemctl stop firewalld
systemctl disable firewalld
systemctl is-enabled firewalld
```

### Configure network bridge for k8s

```bash
# modprobe overlay
# modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
```

- 커널 모듈 `br_netfilter`는 `bridge`를 지나는 패킷이 `iptables`에 의해 제어되도록 한다.
- `modprobe`를 사용할 수 있지만 `systemd`로도 설정할 수 있다.
  - 위와 같은 `.conf` 파일을 작성하면 시스템을 리부팅하더라도 자동으로 모듈이 로딩된다.

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```

- [참고](https://wiki.libvirt.org/page/Net.bridge.bridge-nf-call_and_sysctl.conf)
- These control whether or not packets traversing the `bridge` are sent to iptables for processing.
- `0`으로 설정하면 `bridge` 네트워크로 송수신되는 패킷이 `iptables` 규칙을 우회한다.
- `1`로 설정하면 `bridge` 네트워크로 송수신되는 패킷이 `iptables` 규칙에 따라 제어된다.

### Control Plane

```bash
kubeadm init
# kubeadm init --kubernetes-version=1.19.0 \
#   --pod-network-cidr=10.233.0.0/18 \
#   --service-cidr=10.233.64.0/18 \
#   --apiserver-advertise-address=192.168.7.191 \
#   --v=5
```

- 컨트롤 플레인 노드 하나라면 아래 명령어 실행

```bash
# kubectl taint nodes --all node-role.kubernetes.io/master-
```

- Config 파일 정의하기

```bash
kubeadm config images list

# https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2#ClusterConfiguration
cat > $HOME/pkg/kubeadm-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: "v1.18.15"
networking:
  podSubnet: "10.233.0.0/18"
  serviceSubnet: "10.233.64.0/18"
apiServer:
  extraArgs:
    advertise-address: "192.168.7.191"
controlPlaneEndpoint: "192.168.7.191:6443" 
clusterName: "cluster.name"
EOF

# kubeadm init --service-cidr=10.233.0.0/18 --pod-network-cidr=10.233.64.0/18 --apiserver-advertise-address=192.168.7.191 --kubernetes-version=1.18.15 --v=5
kubeadm init --config=$HOME/pkg/kubeadm-config.yaml --upload-certs --v=5

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
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
# on worker
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
iptables -vL
# ipvsadm -C
```

```bash
# on control-plane
kubectl delete node <node name>
```

- Remove Control Plane

```bash
kubeadm reset
```

```bash
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
iptables -vL
# ipvsadm -C
```
