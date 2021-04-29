# Test with Vagrant

- [Test with Vagrant](#test-with-vagrant)
  - [Demo](#demo)
    - [Prerequisite](#prerequisite)
    - [베이그런트(Vagrant)를 사용해 VM 생성](#베이그런트vagrant를-사용해-vm-생성)
    - [Kubernetes 클러스터 구성](#kubernetes-클러스터-구성)
    - [Service Function Chaining Demo](#service-function-chaining-demo)
    - [Clean Up](#clean-up)
  - [Troubleshooting](#troubleshooting)

## Demo

- [README](https://github.com/akraino-edge-stack/icn-ovn4nfv-k8s-network-controller/blob/master/demo/sfc-setup/README.md)

### Prerequisite

Vagrant를 실행할 호스트에서 가상화를 지원하는지 확인합니다.

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
# 0 -> CPU가 하드웨어 가상화를 지원하지 않습니다.
# 1 or more -> 지원한다는 의미입니다. BIOS에서 별도로 virtualization 옵션을 `enabled` 해주어야 합니다.
```

Python 버전이 3.6 이상이어야 합니다.

```bash
# ERROR: This script does not work on Python 2.7 The minimum supported Python version is 3.6. Please use https://bootstrap.pypa.io/pip/2.7/get-pip.py instead.
# sudo: pip: command not found

apt install -y python3-pip
ls -l $(which python)
# lrwxrwxrwx 1 root root 9 Apr 16  2018 /usr/bin/python -> python2.7
ls -l $(which python3)
# lrwxrwxrwx 1 root root 9 Oct 25  2018 /usr/bin/python3 -> python3.6
rm /usr/bin/python
ln -s /usr/bin/python3.6 /usr/bin/python
python --version
# Python 3.6.9
```

~~libvirtd라는 그룹을 추가해줍니다.~~

> [commit](https://github.com/akraino-edge-stack/icn-ovn4nfv-k8s-network-controller/commit/195f4b917f25669d14085e2b130dd022b7d2229b)

`git diff 195f4b917f25669d14085e2b130dd022b7d2229b~ 195f4b917f25669d14085e2b130dd022b7d2229b`

```bash
# usermod: group 'libvirtd' does not exist
addgroup libvirtd
```

### 베이그런트(Vagrant)를 사용해 VM 생성

> Ubuntu 18.04에서 테스트되었습니다.

```bash
git clone --branch master https://github.com/akraino-edge-stack/icn-ovn4nfv-k8s-network-controller.git
cd ovn4nfv-k8s-plugin/
```

```diff
vi ./demo/sfc-setup/setup.sh
- vagrant_version=2.2.4
+ vagrant_version=2.2.14
```

```bash
./demo/sfc-setup/setup.sh -p libvirt
```

```bash
export VAGRANT_DEFAULT_PROVIDER=libvirt
# apt install virtualbox
# export VAGRANT_DEFAULT_PROVIDER=virtualbox
```

```bash
vagrant up

# Unknown Error
# master: dpkg-preconfigure: unable to re-open stdin: No such file or directory
```

```bash
vagrant status
# [INFO] Provider: libvirt
# Current machine states:

# master                    running (libvirt)
# minion01                  running (libvirt)
# minion02                  running (libvirt)
# tm1-node                  running (libvirt)
# tm2-node                  running (libvirt)
```

```bash
vagrant ssh master
ip -br -c -4 a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.10/27
# eth1             UP             10.10.10.13/24

vagrant ssh minion01
ip -br -c -4 a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.12/27
# eth1             UP             10.10.10.14/24

vagrant ssh minion02
ip -br -c -4 a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.2/27
# eth1             UP             10.10.10.15/24

vagrant ssh tm1-node
ip -br -c -4 a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.20/27
# eth1             UP             10.10.10.16/24

vagrant ssh tm2-node
ip -br -c -4 a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.21/27
# eth1             UP             10.10.10.17/24
```

iTerm2를 사용하신다면 `Shift`+`Command`+`i`:
"Keyboard input will be sent to multiple sessions."

```bash
sudo -i
apt-get update
apt-get install -y net-tools dnsutils traceroute policycoreutils
```

```bash
#  Warning  DNSConfigForming  31s (x8 over 108s)  kubelet            Nameserver limits were exceeded, some nameservers have been omitted, the applied nameserver line is: 4.2.2.1 4.2.2.2 208.67.220.220

cat /var/lib/kubelet/config.yaml | grep resolvConf
# resolvConf: /run/systemd/resolve/resolv.conf
cat /run/systemd/resolve/resolv.conf

vi /etc/resolv.conf
# nameserver 8.8.8.8
# nameserver 8.8.4.4

vi /etc/systemd/resolved.conf
# 8.8.8.8 8.8.4.4

vi /etc/netplan/01-netcfg.yaml
# [8.8.8.8, 8.8.4.4]

systemctl restart systemd-resolved.service
```

### Kubernetes 클러스터 구성

> `master`, `minion01`, `minion02` 3대로 구성합니다.

[kubeadm.md 참고](../../../../bootstrap/kubeadm.md)

```bash
# apt-get remove docker docker-engine docker.io containerd runc
apt-get install \
  curl \
  apt-transport-https \
  ca-certificates \
  docker.io \
  -y

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
```

```bash
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

sestatus
# SELinux status:                 disabled

ufw status
# Status: inactive

# cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
# br_netfilter
# EOF

# cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
# net.bridge.bridge-nf-call-iptables = 1
# net.bridge.bridge-nf-call-ip6tables = 1
# EOF
```

```bash
export KUBERNETES_VERSION=1.19.0
```

```bash
apt-get install \
  kubeadm=${KUBERNETES_VERSION}-00 \
  kubectl=${KUBERNETES_VERSION}-00 \
  kubelet=${KUBERNETES_VERSION}-00 \
  -y
```

```bash
# master node
kubeadm init \
--v 5 \
--kubernetes-version ${KUBERNETES_VERSION} \
--pod-network-cidr 10.233.64.0/18 \
--apiserver-advertise-address ${master-eth0-IP-ADDRESS}
# --apiserver-bind-port 6443

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

노드에 레이블을 지정합니다.

```bash
nodename=$(kubectl get node -o jsonpath='{.items[0].metadata.name}')
# master 노드에도 스케줄할 수 있도록 untaint
kubectl taint node $nodename node-role.kubernetes.io/master:NoSchedule-
# 1번 노드에 레이블 지정
kubectl label --overwrite node $nodename ovn4nfv-k8s-plugin=ovn-control-plane
# 모든 노드에 nfn-operator가 할당될 수 있도록 레이블 지정
kubectl label no --all --overwrite nfnType=operator

kubectl get no --show-labels
# ...,nfnType=operator
```

### Service Function Chaining Demo

![sfc-with-sdewan.png](../../../../images/networking/sfc-with-sdewan.png)

_출처: [opnfv/ovn4nfv-k8s-plugin](https://github.com/opnfv/ovn4nfv-k8s-plugin#service-function-chaining-demo)_

테스트를 위해 TM1과 TM2를 설정합니다.

```bash
vagrant ssh tm1-node

ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.20/27 fe80::5054:ff:fe83:4be9/64
# eth1             UP             10.10.10.16/24

ip addr flush dev eth1
ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.20/27 fe80::5054:ff:fe83:4be9/64
# eth1

ip -br -c l
# lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0             UP             52:54:00:a9:3e:84 <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1             UP             52:54:00:7f:6a:1b <BROADCAST,MULTICAST,UP,LOWER_UP>

ip link add link eth1 name eth1.100 type vlan id 100
ip -br -c l
# lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0             UP             52:54:00:a9:3e:84 <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1             UP             52:54:00:7f:6a:1b <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1.100@eth1    DOWN           52:54:00:7f:6a:1b <BROADCAST,MULTICAST>

ip link set dev eth1.100 up
ip -br -c l
# lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0             UP             52:54:00:a9:3e:84 <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1             UP             52:54:00:7f:6a:1b <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1.100@eth1    UP             52:54:00:7f:6a:1b <BROADCAST,MULTICAST,UP,LOWER_UP>

ip addr add 172.30.10.101/24 dev eth1.100
ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.20/27 fe80::5054:ff:fe83:4be9/64
# eth1             UP
# eth1.100@eth1    UP             172.30.10.101/24

ip r
# default via 192.168.121.1 dev eth0 proto dhcp src 192.168.121.20 metric 100
# 172.30.10.0/24 dev eth1.100 proto kernel scope link src 172.30.10.101
# 192.168.121.0/27 dev eth0 proto kernel scope link src 192.168.121.20
# 192.168.121.1 dev eth0 proto dhcp scope link src 192.168.121.20 metric 100

netstat -rn
# Kernel IP routing table
# Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
# 0.0.0.0         192.168.121.1   0.0.0.0         UG        0 0          0 eth0
# 172.30.10.0     0.0.0.0         255.255.255.0   U         0 0          0 eth1.100
# 192.168.121.0   0.0.0.0         255.255.255.224 U         0 0          0 eth0
# 192.168.121.1   0.0.0.0         255.255.255.255 UH        0 0          0 eth0

ip route del default
ip r
# 172.30.10.0/24 dev eth1.100 proto kernel scope link src 172.30.10.101
# 192.168.121.0/27 dev eth0 proto kernel scope link src 192.168.121.20
# 192.168.121.1 dev eth0 proto dhcp scope link src 192.168.121.20 metric 100

ip route add default via 172.30.10.3
ip r
# default via 172.30.10.3 dev eth1.100
# 172.30.10.0/24 dev eth1.100 proto kernel scope link src 172.30.10.101
# 192.168.121.0/27 dev eth0 proto kernel scope link src 192.168.121.20
# 192.168.121.1 dev eth0 proto dhcp scope link src 192.168.121.20 metric 100

netstat -rn
# Kernel IP routing table
# Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
# 0.0.0.0         172.30.10.3     0.0.0.0         UG        0 0          0 eth1.100
# 172.30.10.0     0.0.0.0         255.255.255.0   U         0 0          0 eth1.100
# 192.168.121.0   0.0.0.0         255.255.255.224 U         0 0          0 eth0
# 192.168.121.1   0.0.0.0         255.255.255.255 UH        0 0          0 eth0
```

```bash
vagrant ssh tm2-node

ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.11/27 fe80::5054:ff:fe51:f56/64
# eth1             UP             10.10.10.17/24 fe80::5054:ff:fe90:523b/64

ip addr flush dev eth1
ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.11/27 fe80::5054:ff:fe51:f56/64
# eth1             UP

ip -br -c l
# lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0             UP             52:54:00:51:0f:56 <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1             UP             52:54:00:90:52:3b <BROADCAST,MULTICAST,UP,LOWER_UP>

ip link add link eth1 name eth1.200 type vlan id 200
ip -br -c l
# lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0             UP             52:54:00:51:0f:56 <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1             UP             52:54:00:90:52:3b <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1.200@eth1    DOWN           52:54:00:90:52:3b <BROADCAST,MULTICAST>

ip link set dev eth1.200 up
ip -br -c l
# lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0             UP             52:54:00:51:0f:56 <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1             UP             52:54:00:90:52:3b <BROADCAST,MULTICAST,UP,LOWER_UP>
# eth1.200@eth1    UP             52:54:00:90:52:3b <BROADCAST,MULTICAST,UP,LOWER_UP>

ip addr add 172.30.20.2/24 dev eth1.200
ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# eth0             UP             192.168.121.11/27 fe80::5054:ff:fe51:f56/64
# eth1             UP
# eth1.200@eth1    UP             172.30.20.2/24
```

- TM2 노드에 virtual router 생성

```bash
ip r
# default via 192.168.121.1 dev eth0 proto dhcp src 192.168.121.11 metric 100
# 172.30.20.0/24 dev eth1.200 proto kernel scope link src 172.30.20.2
# 192.168.121.0/27 dev eth0 proto kernel scope link src 192.168.121.11
# 192.168.121.1 dev eth0 proto dhcp scope link src 192.168.121.11 metric 100

netstat -rn
# Kernel IP routing table
# Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
# 0.0.0.0         192.168.121.1   0.0.0.0         UG        0 0          0 eth0
# 172.30.20.0     0.0.0.0         255.255.255.0   U         0 0          0 eth1.200
# 192.168.121.0   0.0.0.0         255.255.255.224 U         0 0          0 eth0
# 192.168.121.1   0.0.0.0         255.255.255.255 UH        0 0          0 eth0

ip route add 172.30.10.0/24 via 172.30.20.3
ip route add 172.30.33.0/24 via 172.30.20.3
ip route add 172.30.44.0/24 via 172.30.20.3

ip r
# default via 192.168.121.1 dev eth0 proto dhcp src 192.168.121.11 metric 100
# 172.30.10.0/24 via 172.30.20.3 dev eth1.200
# 172.30.20.0/24 dev eth1.200 proto kernel scope link src 172.30.20.2
# 172.30.33.0/24 via 172.30.20.3 dev eth1.200
# 172.30.44.0/24 via 172.30.20.3 dev eth1.200
# 192.168.121.0/27 dev eth0 proto kernel scope link src 192.168.121.11
# 192.168.121.1 dev eth0 proto dhcp scope link src 192.168.121.11 metric 100

netstat -rn
# Kernel IP routing table
# Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
# 0.0.0.0         192.168.121.1   0.0.0.0         UG        0 0          0 eth0
# 172.30.10.0     172.30.20.3     255.255.255.0   UG        0 0          0 eth1.200
# 172.30.20.0     0.0.0.0         255.255.255.0   U         0 0          0 eth1.200
# 172.30.33.0     172.30.20.3     255.255.255.0   UG        0 0          0 eth1.200
# 172.30.44.0     172.30.20.3     255.255.255.0   UG        0 0          0 eth1.200
# 192.168.121.0   0.0.0.0         255.255.255.224 U         0 0          0 eth0
# 192.168.121.1   0.0.0.0         255.255.255.255 UH        0 0          0 eth0
```

```bash
iptables -vL
# Chain INPUT (policy ACCEPT 39 packets, 1920 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#
# Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#
# Chain OUTPUT (policy ACCEPT 29 packets, 2340 bytes)
#  pkts bytes target     prot opt in     out     source               destination

echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth1.200 -o eth0 -j ACCEPT

iptables -vL FORWARD
# Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
#  pkts bytes target     prot opt in     out     source               destination
#     0     0 ACCEPT     all  --  eth1   eth0    anywhere             anywhere
#     0     0 ACCEPT     all  --  eth1.200 eth0    anywhere             anywhere
```

```bash
git clone --branch master https://github.com/akraino-edge-stack/icn-ovn4nfv-k8s-network-controller.git
cd icn-ovn4nfv-k8s-network-controller/
rm -f deploy/*-centos.yaml
rm -f deploy/crd/*_cr.yaml
```

```bash
curl -LO https://docs.projectcalico.org/manifests/calico.yaml
# TODO: IP_AUTODETECTION_METHOD 꼭 넣어줘야 하는지 테스트

kubectl apply -f calico.yaml
```

```diff
3645,3647d3644
+             # Specify interface
+             - name: IP_AUTODETECTION_METHOD
+               value: "interface=eth0"
```

```bash
# Deploy ovn4nfv
kubectl apply -f deploy/ovn-daemonset.yaml
kubectl apply -f deploy/ovn4nfv-k8s-plugin.yaml
kubectl apply -f deploy/operator_roles.yaml
kubectl apply -f deploy/operator.yaml
kubectl apply -f deploy/crds/
```

- [deploy/multus-daemonset.yml 참고](https://github.com/k8snetworkplumbingwg/reference-deployment/blob/master/multus-calico/multus-daemonset.yml)
- TODO: 멀터스 동작 방식 이해하기

```diff
diff --git a/deploy/multus-daemonset.yml b/deploy/multus-daemonset.yml
index 08c3d6d..ed05463 100644
--- a/deploy/multus-daemonset.yml
+++ b/deploy/multus-daemonset.yml
@@ -191,9 +192,9 @@ spec:
         - -cex
         - |
           #!/bin/bash
-          sed "s|__KUBERNETES_NODE_NAME__|${KUBERNETES_NODE_NAME}|g" /tmp/multus-conf/00-multus.conf.template > /tmp/multus-conf/00-multus.conf
+          sed "s|__KUBERNETES_NODE_NAME__|${KUBERNETES_NODE_NAME}|g" /tmp/multus-conf/70-multus.conf.template > /tmp/multus-conf/70-multus.conf
           /entrypoint.sh \
-            --multus-conf-file=/tmp/multus-conf/00-multus.conf
+            --multus-conf-file=/tmp/multus-conf/70-multus.conf
         resources:
           requests:
             cpu: "100m"
@@ -209,7 +210,7 @@ spec:
         - name: cnibin
           mountPath: /host/opt/cni/bin
         - name: multus-cfg
-          mountPath: /tmp/multus-conf/00-multus.conf.template
+          mountPath: /tmp/multus-conf/70-multus.conf.template
           subPath: "cni-conf.json"
       volumes:
         - name: cni
```

```bash
# 제대로 동작하는 건가?
kubectl apply -f deploy/multus-daemonset.yml
```

- 만약 core-dns나 calico-node가 정상적으로 제어되지 않는다면 수동으로 삭제

```bash
kubectl -n kube-system delete po -l k8s-app=calico-node
kubectl -n kube-system delete po -l k8s-app=calico-kube-controllers

kubectl -n kube-system delete po -l k8s-app=kube-dns
```

```bash
# tail -f /var/log/calico/cni/cni.log
# tail -f /var/log/openvswitch/ovn4k8s.log
```

- ~~fix typo~~

> [commit](https://github.com/akraino-edge-stack/icn-ovn4nfv-k8s-network-controller/commit/3aacd80e874d257699421d64af4dce4150da9733)

`git diff 3aacd80e874d257699421d64af4dce4150da9733~ 3aacd80e874d257699421d64af4dce4150da9733`

```diff
diff --git a/demo/sfc-setup/deploy/sfc.yaml b/demo/sfc-setup/deploy/sfc.yaml
index 98af02a..1215097 100644
--- a/demo/sfc-setup/deploy/sfc.yaml
+++ b/demo/sfc-setup/deploy/sfc.yaml
@@ -9,10 +9,10 @@ spec:
     namespace: "default"
     networkChain: "app=slb,dync-net1,app=ngfw,dync-net2,app=sdwan"
     leftNetwork:
-    - networkName: "right-pnetwork"
+    - networkName: "left-pnetwork"
       gatewayIp: "172.30.10.2"
       subnet: "172.30.10.0/24"
     rightNetwork:
-    - networkName: "left-pnetwork"
+    - networkName: "right-pnetwork"
       gatewayIp: "172.30.20.2"
       subnet: "172.30.20.0/24"
```

데모용 `Network`와 `Deployment`를 배포합니다.

```bash
rm -f demo/sfc-setup/deploy/firewall*v

kubectl apply -f demo/sfc-setup/deploy/sfc-network.yaml
kubectl apply -f demo/sfc-setup/deploy/slb-ngfw-sdewan-cnf-deployment.yaml

kubectl apply -f demo/sfc-setup/deploy/ms1.yaml
kubectl apply -f demo/sfc-setup/deploy/sfc.yaml
```

IP가 잘 설정되었는지 확인합니다.

```bash
kubectl exec -it $(kubectl get po -l app=slb --no-headers) -- ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# tunl0@NONE       DOWN
# net0@if38        UP             172.30.10.3/24
# net1@if5         UP             172.30.33.2/24
# eth0@if39        UP             10.233.64.12/18

kubectl get network dync-net1 -o jsonpath-as-json='{.spec.ipv4Subnets}'
# [
#   [
#     {
#       "gateway": "172.30.33.1/24",
#       "name": "subnet1",
#       "subnet": "172.30.33.0/24"
#     }
#   ]
# ]

kubectl exec -it $(kubectl get po -l app=ngfw --no-headers) -- ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# tunl0@NONE       DOWN
# net0@if45        UP             172.30.33.3/24
# net1@if5         UP             172.30.44.2/24
# eth0@if46        UP             10.233.64.13/18

kubectl get network dync-net2 -o jsonpath-as-json='{.spec.ipv4Subnets}'
# [
#   [
#     {
#       "gateway": "172.30.44.1/24",
#       "name": "subnet1",
#       "subnet": "172.30.44.0/24"
#     }
#   ]
# ]

kubectl exec -it $(kubectl get po -l app=sdwan --no-headers) -- ip -br -c a
# lo               UNKNOWN        127.0.0.1/8
# tunl0@NONE       DOWN
# net0@if40        UP             172.30.44.3/24 fe80::f43c:99ff:fe1e:2c04/64
# net1@if41        UP             172.30.20.3/24 fe80::f43c:99ff:fe1e:1404/64
# eth0@if42        UP             10.233.64.17/18

kubectl get networkchaining example-networkchaining -o jsonpath-as-json='{.spec}'
# [
#   {
#     "chainType": "Routing",
#     "routingSpec": {
#       "leftNetwork": [
#         {
#           "gatewayIp": "172.30.10.2",
#           "networkName": "left-pnetwork",
#           "subnet": "172.30.10.0/24"
#         }
#       ],
#       "namespace": "default",
#       "networkChain": "app=slb,dync-net1,app=ngfw,dync-net2,app=sdwan",
#       "rightNetwork": [
#         {
#           "gatewayIp": "172.30.20.2",
#           "networkName": "right-pnetwork",
#           "subnet": "172.30.20.0/24"
#         }
#       ]
#     }
#   }
# ]
```

TM1 노드에서 `traceroute` 명령어를 통해 트래픽이 잘 지나가는지 확인합니다.

```bash
vagrant ssh tm1-node

traceroute 8.8.8.8
traceroute kubernetes.io
# traceroute to kubernetes.io (147.75.40.148), 64 hops max
#   1   172.30.10.3  0.553ms  0.141ms  0.094ms
#   2   172.30.33.3  0.862ms  0.153ms  0.232ms
#   3   172.30.44.3  0.369ms  0.152ms  0.135ms
#   4   172.30.20.2  0.479ms  0.199ms  0.183ms
```

### Clean Up

```bash
vagrant destroy --parallel
```

## Troubleshooting

- [Install Vagrant](https://linuxize.com/post/how-to-install-vagrant-on-ubuntu-18-04/)

```bash
apt update
export VAGRANT_VERSION=2.2.14
curl -O https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb
apt install ./vagrant_${VAGRANT_VERSION}_x86_64.deb
vagrant --version
# Vagrant ${VAGRANT_VERSION}
```

- Install Ruby
- [How To List Users and Groups on Linux](https://devconnected.com/how-to-list-users-and-groups-on-linux/)

```bash
# gem list ^nokogiri$ --remote --all
usermod -a -G rvm ${username}
cat /etc/passwd
# username:password:UID:GID:Comment:Home-Directory:Shelll-Used
cat /etc/passwd | cut -d: -f1,5
# username:Comment

cat /etc/group
# group-name:passwod:GID:User-in-the-group
cat /etc/group | grep rvm
# rvm:x:1002:root

apt-get install software-properties-common
apt-add-repository -y ppa:rael-gc/rvm
apt-get update
apt-get install rvm

sudo -i
rvm --version
# rvm 1.29.12 (manual) by Michal Papis, Piotr Kuczynski, Wayne E. Seguin [https://rvm.io]

ruby --version
# ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]
rvm install 2.7.1 # rvm install ruby
ruby --version
# ruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x86_64-linux]
```

- Install vagrant-libvirt plugin

```bash
vagrant plugin install vagrant-libvirt
# Installing the 'vagrant-libvirt' plugin. This can take a few minutes...
# Fetching: excon-0.80.1.gem (100%)
# Fetching: formatador-0.2.5.gem (100%)
# Fetching: fog-core-2.2.3.gem (100%)
# Fetching: fog-json-1.2.0.gem (100%)
# Fetching: racc-1.5.2.gem (100%)
# Building native extensions.  This could take a while...
# Fetching: nokogiri-1.11.3-x86_64-linux.gem (100%)
# Bundler, the underlying system Vagrant uses to install plugins,
# reported an error. The error is shown below. These errors are usually
#
# caused by misconfigured plugin installations or transient network
# issues. The error from Bundler is:
#
# nokogiri requires Ruby version < 3.1.dev, >= 2.5.
rm -rf ~/.vagrant.d
apt install ruby-pkg-config
```

```bash
# tm1-node
arp -s 172.30.10.3 9a:5f:e3:1e:0a:04
arp -v
# Address                  HWtype  HWaddress           Flags Mask            Iface
# 192.168.121.1            ether   52:54:00:b8:c1:bd   C                     eth0
# 172.30.10.3              ether   9a:5f:e3:1e:0a:04   CM                    eth1.100
# Entries: 2  Skipped: 0  Found: 2
```
