# Creating a cluster with kubeadm

- [Creating a cluster with kubeadm](#creating-a-cluster-with-kubeadm)
  - [사전 준비](#사전-준비)
    - [Ubuntu 20.04](#ubuntu-2004)
    - [Configure container runtime](#configure-container-runtime)
      - [network bridge for k8s](#network-bridge-for-k8s)
  - [Control Plane 구축](#control-plane-구축)
  - [기타 설정 정보](#기타-설정-정보)
    - [CRI](#cri)
    - [1개의 노드](#1개의-노드)
    - [etc](#etc)
  - [Worker Node 구축](#worker-node-구축)
  - [Clean up](#clean-up)
    - [Remove Worker Node](#remove-worker-node)
    - [Remove Control Plane](#remove-control-plane)

## 사전 준비

- [Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

### Ubuntu 20.04

- [Docker setup](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)

```sh
sudo -i
apt-get update
apt-get install -y docker.io
```

```sh
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
systemctl restart docker
# systemctl daemon-reload
```

- cgroup driver의 기본값이 `cgoupfs`이기 때문에 변경해준다.
- `systemd`를 사용해야 하는 이유는 없다. 다만 같이 쓰지 않도록 주의한다. [참고](https://tech.kakao.com/2020/06/29/cgroup-driver/)

```sh
docker info
```

```sh
apt-get install -y apt-transport-https ca-certificates curl
```

```sh
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

```sh
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```sh
apt-get update
```

```sh
apt list kubeadm -a
```

```sh
KUBE_VERION=1.26.1-00 && apt-get install kubeadm=$KUBE_VERION kubectl=$KUBE_VERION kubelet=$KUBE_VERION
```

```sh
apt-mark hold kubelet kubeadm kubectl
# kubelet set on hold.
# kubeadm set on hold.
# kubectl set on hold.
```

[Swap disabled.](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)
You **MUST** disable swap in order for the kubelet to work properly.

```sh
swapoff -a

sed -e '/swap/s/^/#/g' -i /etc/fstab
```

netcat(`nc`)으로
[필수 포트](https://kubernetes.io/docs/reference/networking/ports-and-protocols/)가 열려 있는지 확인한다.

```sh
nc -v localhost 2379 2380 6443 10250 10257 10259
# nc: connect to localhost (127.0.0.1) port 2379 (tcp) failed: Connection refused
# nc: connect to localhost (127.0.0.1) port 2380 (tcp) failed: Connection refused
# nc: connect to localhost (127.0.0.1) port 6443 (tcp) failed: Connection refused
# nc: connect to localhost (127.0.0.1) port 10250 (tcp) failed: Connection refused
# nc: connect to localhost (127.0.0.1) port 10257 (tcp) failed: Connection refused
# nc: connect to localhost (127.0.0.1) port 10259 (tcp) failed: Connection refused
```

- [kubernetes/issues/7294](https://github.com/kubernetes/kubernetes/issues/7294)
- [kubernetes/issues/53533](https://github.com/kubernetes/kubernetes/issues/53533)
- 파드의 QoS, Automatic bin packing, 예측 가능성, 일관성, 성능 저하

SELinux를 permissive 모드로 변경한다.

```sh
# apt install -y selinux-utils
# setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

```sh
sestatus
# Current mode:                   permissive
```

Firewall를 비활성화한다.
배포판에 따라 관리 도구가 다를 수 있기 때문에
`apropos`를 사용해 검색한다.

```sh
apropos firewall
# ufw (8)              - program for managing a netfilter firewall
```

```sh
sudo ufw status
# Status: inactive
```

### Configure container runtime

- [Docs](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

#### network bridge for k8s

```sh
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

```sh
sudo modprobe overlay
sudo modprobe br_netfilter
```

- 커널 모듈 `br_netfilter`는 `bridge`를 지나는 패킷이 `iptables`에 의해 제어되도록 한다.
- `modprobe`를 사용할 수 있지만 `systemd`로도 설정할 수 있다.
  - 위와 같은 `.conf` 파일을 작성하면 시스템을 리부팅하더라도 자동으로 모듈이 로딩된다.

```sh
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

```sh
# Apply sysctl params without reboot
sudo sysctl --system
```

```sh
...
* Applying /etc/sysctl.d/99-sysctl.conf ...
* Applying /etc/sysctl.d/k8s.conf ...
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
* Applying /etc/sysctl.conf ...
```

- [참고](https://wiki.libvirt.org/page/Net.bridge.bridge-nf-call_and_sysctl.conf)
- These control whether or not packets traversing the `bridge` are sent to iptables for processing.
- `0`으로 설정하면 `bridge` 네트워크로 송수신되는 패킷이 `iptables` 규칙을 우회한다.
- `1`로 설정하면 `bridge` 네트워크로 송수신되는 패킷이 `iptables` 규칙에 따라 제어된다.

Container Runtime을 확인한다.
disabled_plugins 에서 cri를 제거하거나 아예 주석 처리한다.

```toml
# /etc/containerd/config.toml
# disabled_plugins = ["cri"]
```

```sh
systemctl restart containerd
# Active: active (running)
```

## Control Plane 구축

```sh
kubeadm init -v=5
# kubeadm init --kubernetes-version=1.19.0 \
#   --pod-network-cidr=10.233.0.0/18 \
#   --service-cidr=10.233.64.0/18 \
#   --apiserver-advertise-address=192.168.7.191 \
#   --v=5
```

```sh
# To start using your cluster, you need to run the following as a regular user:

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

export KUBECONFIG=/etc/kubernetes/admin.conf
```

kubelet 로그를 확인해 볼 수 있다.
pod가 즉시 생성되는 것이 아니기 때문에 로그로 먼저 확인 후
pod를 조회해보자.

```sh
journalctl -fxu kubelet
```

```sh
kubectl get nodes -o wide
# NAME   STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
# tost   Ready    control-plane   12m   v1.26.1   192.168.0.148   <none>        Ubuntu 22.04.1 LTS   5.15.0-58-generic   containerd://1.6.16
```

```sh
kubectl get pods --all-namespaces -o wide
# NAMESPACE     NAME                           READY   STATUS              RESTARTS       AGE   IP              NODE   NOMINATED NODE   READINESS GATES
# kube-system   coredns-787d4945fb-q9xc4       0/1     ContainerCreating   0              37s   <none>          tost   <none>           <none>
# kube-system   coredns-787d4945fb-qlsl6       0/1     ContainerCreating   0              37s   <none>          tost   <none>           <none>
# kube-system   kube-apiserver-tost            1/1     Running             10 (61s ago)   93s   192.168.0.148   tost   <none>           <none>
# kube-system   kube-controller-manager-tost   1/1     Running             11 (91s ago)   93s   192.168.0.148   tost   <none>           <none>
# kube-system   kube-proxy-4zc6l               1/1     Running             1 (37s ago)    37s   192.168.0.148   tost   <none>           <none>
```

각 리소스에 대한 상태는 다음 명령어들을 사용해서 확인해볼 수 있다.

```sh
kubectl get ev -n kube-system --sort-by='.lastTimestamp'
kubectl logs kube-scheduler-tost -n kube-system
kubectl describe po kube-scheduler-tost -n kube-system
```

리소스 조회 시 `-A|--all-namespaces` 옵션
혹은 `-n|--namespace`을 사용하지 않으면
`default` 네임스페이스만 조회하기 때문에 리소스가 보이지 않을 수 있다.

```sh
kubectl get po -A
# NAMESPACE     NAME                           READY   STATUS              RESTARTS         AGE
# kube-system   coredns-787d4945fb-q9xc4       0/1     ContainerCreating   0                6m34s
# kube-system   coredns-787d4945fb-qlsl6       0/1     ContainerCreating   0                6m34s
# kube-system   etcd-tost                      1/1     Running             7 (7m28s ago)    5m48s
# kube-system   kube-apiserver-tost            1/1     Running             10 (6m58s ago)   7m30s
# kube-system   kube-controller-manager-tost   1/1     Running             12 (2m55s ago)   7m30s
# kube-system   kube-proxy-4zc6l               1/1     Running             4 (89s ago)      6m34s
# kube-system   kube-scheduler-tost            0/1     CrashLoopBackOff    12 (44s ago)     5m45s
```

pod가 정상 동작할 수 있도록
네트워크 구성을 위한 CNI를 설정해야 한다.
여기서는 Calico를 사용한다.

- [Install Calico CNI](https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises)

```sh
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico-typha.yaml
```

```sh
kubectl get nodes
# NAME   STATUS   ROLES           AGE    VERSION
# tost   Ready    control-plane   8m7s   v1.26.1
```

## 기타 설정 정보

### CRI

```sh
crictl ps
```

### 1개의 노드

노드가 컨트롤 플레인 노드를 포함해서 하나뿐이라면 아래 명령어를 실행한다.

```sh
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### etc

컨트롤 플레인 노드에서 필요한 이미지들은 다음과 같다.

```sh
kubeadm config images list
# registry.k8s.io/kube-apiserver:v1.26.1
# registry.k8s.io/kube-controller-manager:v1.26.1
# registry.k8s.io/kube-scheduler:v1.26.1
# registry.k8s.io/kube-proxy:v1.26.1
# registry.k8s.io/pause:3.9
# registry.k8s.io/etcd:3.5.6-0
# registry.k8s.io/coredns/coredns:v1.9.3
```

config 파일로 클러스터를 생성할 수 있다.

```sh
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
```

```sh
# kubeadm init --service-cidr=10.233.0.0/18 --pod-network-cidr=10.233.64.0/18 --apiserver-advertise-address=192.168.7.191 --kubernetes-version=1.18.15 --v=5
kubeadm init --config=$HOME/pkg/kubeadm-config.yaml --upload-certs --v=5
```

Worker Node를 추가(`kubeadm join`)하려면
[Token](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/)이 필요하다.

```sh
kubeadm token list
# TOKEN                     TTL         EXPIRES                USAGES                   DESCRIPTION                                                EXTRA GROUPS
# t3a59c.qp2o90nox2or04dg   23h         2023-02-05T06:56:18Z   authentication,signing   The default bootstrap token generated by 'kubeadm init'.   system:bootstrappers:kubeadm:default-node-token
```

다음 명령어로 새로 생성할 수 있다.

```sh
kubeadm token create --print-join-command --ttl=0
# <token>
```

```sh
cat /etc/kubernetes/pki/tokens.csv
```

```sh
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
# <hash>
```

```sh
kubectl -n kube-system get cm kubeadm-config -o yaml
```

## Worker Node 구축

워커 노드를 추가하려면 컨트롤 플레인 초기화 시 출력된 명령어를 실행한다.

```sh
# kubeadm join --token <token> <control-plane-host>:6443 --discovery-token-ca-cert-hash sha256:<hash>
kubeadm join 192.168.7.182:6443 \
  --token j9hs6q.qqmixdn74lksqpl0 \
  --discovery-token-ca-cert-hash sha256:3c18620c7b79f2c90a9268ea0c322536fa0b4c8b4bb5b0f34fb702b321436585
```

## Clean up

- [Clean up](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down) - Docs

### Remove Worker Node

```sh
# on control-plane node
kubectl get nodes
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
```

```sh
# on worker node
kubeadm reset
```

```sh
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

```sh
# on control-plane node
kubectl delete node <node name>
```

### Remove Control Plane

```sh
kubeadm reset
```

```sh
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

```sh
iptables -vL
# Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination

# Chain FORWARD (policy DROP 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination

# Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
```

```sh
ipvsadm -S
# -P INPUT ACCEPT
# -P FORWARD DROP
# -P OUTPUT ACCEPT
```
