# Creating a cluster with kubeadm

- [Creating a cluster with kubeadm](#creating-a-cluster-with-kubeadm)
  - [사전 준비](#사전-준비)
    - [Ubuntu 22.04](#ubuntu-2204)
    - [Container Runtime 설치](#container-runtime-설치)
    - [Configure container runtime](#configure-container-runtime)
      - [network bridge for k8s](#network-bridge-for-k8s)
  - [Control Plane 구축](#control-plane-구축)
    - [에러](#에러)
    - [init 후](#init-후)
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

### Ubuntu 22.04

- ~~[Docker setup](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker)~~

```sh
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
```

### Container Runtime 설치

```sh
# sudo -i
# sudo apt-get install -y podman
# podman info
```

- [Installing containerd](https://github.com/containerd/containerd/blob/27cf7f87dba9022b1de999da291b58691dbc25a4/docs/getting-started.md#option-2-from-apt-get-or-dnf)
  - `containerd` 패키지를 설치하면 [문제가 많았다](https://github.com/containerd/containerd/issues/4581).
  - Docker 리포지터리에 있는 `containerd.io` 를 설치하자.

```sh
apt-get remove docker docker-engine docker.io containerd runc
```

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
```

Add Docker’s official GPG key:

```sh
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Set up the repository:

```sh
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```sh
sudo apt-get install containerd.io
# containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
```

```toml
# /etc/containerd/config.toml
disabled_plugins = []

version = 2
[plugins."io.containerd.grpc.v1.cri"]
  systemd_cgroup = true
[plugins."io.containerd.grpc.v1.cri".containerd]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```

```sh
systemctl restart containerd
# Active: active (running)
```

- ~~cgroup driver의 기본값이 `cgoupfs`이기 때문에 변경해준다.~~
- `systemd`를 사용해야 하는 이유는 없다. 다만 같이 쓰지 않도록 주의한다.
  - [참고](https://tech.kakao.com/2020/06/29/cgroup-driver/)

```sh
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

```sh
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```sh
sudo apt update
```

```sh
sudo apt list kubeadm -a
```

v1.24부터는 docker 제외

```sh
# KUBE_VERION=1.23.1-00 && sudo apt install kubeadm=$KUBE_VERION kubectl=$KUBE_VERION kubelet=$KUBE_VERION
KUBE_VERION=1.26.1-00 && sudo apt install kubeadm=$KUBE_VERION kubectl=$KUBE_VERION kubelet=$KUBE_VERION
```

```sh
sudo apt-mark hold kubelet kubeadm kubectl
# kubelet set on hold.
# kubeadm set on hold.
# kubectl set on hold.
```

[Swap disabled.](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)
You **MUST** disable swap in order for the kubelet to work properly.

```sh
sudo swapoff -a

sudo sed -e '/swap/s/^/#/g' -i /etc/fstab
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

```sh
cat /proc/sys/net/ipv4/ip_forward
# 1
```

- [참고](https://wiki.libvirt.org/page/Net.bridge.bridge-nf-call_and_sysctl.conf)
- These control whether or not packets traversing the `bridge` are sent to iptables for processing.
- `0`으로 설정하면 `bridge` 네트워크로 송수신되는 패킷이 `iptables` 규칙을 우회한다.
- `1`로 설정하면 `bridge` 네트워크로 송수신되는 패킷이 `iptables` 규칙에 따라 제어된다.

## Control Plane 구축

```sh
sudo kubeadm init -v=5
# kubeadm init --kubernetes-version=1.19.0 \
#   --pod-network-cidr=10.233.0.0/18 \
#   --service-cidr=10.233.64.0/18 \
#   --apiserver-advertise-address=192.168.7.191 \
#   --v=5
```

### 에러

```sh
# VM 실행 시 메모리를 1700MB 이상으로 설정한다.
[ERROR Mem]: the system RAM (814 MB) is less than the minimum 1700 MB

# containerd 말고 containerd.io 설치
[ERROR CRI]: container runtime is not running: output: -

# master 노드를 taint
Feb 05 15:34:40 tost1 kubelet[52034]: E0205 15:34:40.132351   52034 kubelet.go:1711] "Failed creating a mirror pod for" err="Post \"https://172.27.23.205:6443/api/v1/namespaces/kube-system/pods\": read tcp 172.27.23.205:57068->172.27.23.205:6443: use of closed network connection" pod="kube-system/kube-scheduler-tost1"
```

### init 후

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
kubectl get po -A -o wide
# NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE     IP              NODE    NOMINATED NODE   READINESS GATES
# kube-system   coredns-787d4945fb-c6wfc        1/1     Running   0          3m58s   10.88.0.2       tost1   <none>           <none>
# kube-system   coredns-787d4945fb-qfkqf        1/1     Running   0          3m58s   10.88.0.3       tost1   <none>           <none>
# kube-system   etcd-tost1                      1/1     Running   0          4m5s    172.27.23.205   tost1   <none>           <none>
# kube-system   kube-apiserver-tost1            1/1     Running   0          4m4s    172.27.23.205   tost1   <none>           <none>
# kube-system   kube-controller-manager-tost1   1/1     Running   0          4m4s    172.27.23.205   tost1   <none>           <none>
# kube-system   kube-proxy-g7j9l                1/1     Running   0          3m58s   172.27.23.205   tost1   <none>           <none>
# kube-system   kube-scheduler-tost1            1/1     Running   0          4m4s    172.27.23.205   tost1   <none>           <none>
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

~~pod가 정상 동작할 수 있도록
네트워크 구성을 위한 CNI를 설정해야 한다.
여기서는 Calico를 사용한다.~~

v1.24 이후부터(정확하지 않음)는 CNI 플러그인을 설정하지 않아도 CoreDNS가 Pending이 아닌 Running 상태가 된다.
하지만 결국 pod를 생성하고 네트워크 인터페이스를 할당하려면 CNI 플러그인이 필요하다.

- [Install Calico CNI](https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises)

- manifest

```sh
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
```

- operator

```sh
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
# kubectl delete -f $URL
```

```sh
# Terminating 상태인 pod를 삭제하려면
# https://www.ibm.com/docs/ko/cloud-private/3.2.x?topic=console-pod-is-stuck-in-terminating-state
kubectl -n kube-system delete pod --grace-period=0 --force $POD_NAME
```

```sh
kubectl get nodes
# NAME   STATUS   ROLES           AGE    VERSION
# tost   Ready    control-plane   8m7s   v1.26.1
```

```sh
kubectl get all -A
```

## 기타 설정 정보

### CRI

```sh
crictl ps
```

### 1개의 노드

노드가 컨트롤 플레인 노드를 포함해서 하나뿐이라면 taint 해야 한다.

```sh
kubectl get ev -n kube-system
# LAST SEEN   TYPE      REASON              OBJECT                          MESSAGE
# 96s         Warning   FailedScheduling    pod/coredns-64897985d-6drrs     0/1 nodes are available: 1 node(s) had taint {node.kubernetes.io/not-ready: }, that the pod didn't tolerate.
```

```sh
kubectl taint node --all node-role.kubernetes.io/master-
# 다시 스케줄링 할 수 없도록 taint 추가
# kubectl taint nodes master node-role.kubernetes.io=master:NoSchedule
```

```sh
kubectl describe node -l node-role.kubernetes.io/master
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
