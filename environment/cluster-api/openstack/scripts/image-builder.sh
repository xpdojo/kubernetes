#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source $script_dir/.env

# vagrant ssh
# ssh 192.168.56.2

# Install packer
# https://learn.hashicorp.com/tutorials/packer/getting-started-install#installing-packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
packer version

# https://github.com/kubernetes-sigs/image-builder
# https://image-builder.sigs.k8s.io/capi/capi.html#prerequisites
# https://image-builder.sigs.k8s.io/capi/providers/openstack.html
sudo apt install -y qemu-kvm qemu-utils libvirt-daemon libvirt-clients # libvirt-bin
git clone https://github.com/kubernetes-sigs/image-builder.git
cd image-builder/images/capi/
# make deps
make deps-qemu
PACKER_LOG=1 make build-qemu-ubuntu-1804
# Started Qemu. Pid: 579822
# Qemu stderr: ioctl(KVM_CREATE_VM) failed: 16 Device or resource busy
# Qemu stderr: qemu-system-x86_64: failed to initialize KVM: Device or resource busy
# failed to unlock port lockfile: close tcp 127.0.0.1:5984: use of closed network connection
# failed to unlock port lockfile: close tcp 127.0.0.1:3795: use of closed network connection
# 
# https://www.agix.com.au/kvm-error-ioctlkvm_create_vm-failed-16-device-or-resource-busy/
# 이미 hypervisor가 실행 중인 상태(virtual-box)에서 KVM을 실행시키려고 하는 것이 원인
# 
# vagrant halt # suspend?
# make build-qemu-ubuntu-1804



# scp ./ubuntu-1804-kube-v.18.15 vagrant@192.168.56.2:/home/vagrant
