# 오픈스택 기반의 workload cluster 생성하기

## 사전 준비

- [관련 이슈](https://github.com/kubernetes-sigs/cluster-api-provider-openstack/issues/717)
- `yq` v4는 아래와 같은 에러가 발생합니다.

```bash
# wget https://github.com/mikefarah/yq/releases/download/v4.5.1/yq_darwin_amd64 -O /usr/local/bin/yq
# source scripts/env.rc scripts/etc/openstack/clouds.yaml devstack
# Error: unknown command "r" for "yq"
```

- macOS의 `base64` 명령어는 `--wrap` 대신 `--break`가 사용됩니다.
- env.rc 스크립트에서 변경해주세요.

```bash
# base64: unrecognized option `--wrap=0'
```

```bash
sudo wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
yq --version
# yq version 3.4.1
```

```bash
git clone https://github.com/johnstcn/vagrant-devstack.git
# sudo apt-get install -y nfs-server
# vagrant plugin install vagrant-hostmanager
vagrant up
vagrant ssh
./devstack/stack.sh
# 40분~45분 소요
# vagrant halt
```

```bash
kind create cluster --name capo-test --config kind-config.yaml
```

## [인프라스트럭처 프로바이더 초기화](https://cluster-api.sigs.k8s.io/user/quick-start.html#initialization-for-common-providers)

```bash
# Initialize the management cluster
clusterctl init --infrastructure openstack -v 4
# Fetching providers
# Installing cert-manager Version="v0.16.1"
# Waiting for cert-manager to be available...
# Installing Provider="cluster-api" Version="v0.3.14" TargetNamespace="capi-system"
# Installing Provider="bootstrap-kubeadm" Version="v0.3.14" TargetNamespace="capi-kubeadm-bootstrap-system"
# Installing Provider="control-plane-kubeadm" Version="v0.3.14" TargetNamespace="capi-kubeadm-control-plane-system"
# Installing Provider="infrastructure-openstack" Version="v0.3.3" TargetNamespace="capo-system"

# Your management cluster has been initialized successfully!

# You can now create your first workload cluster by running the following:

#   clusterctl config cluster [name] --kubernetes-version [version] | kubectl apply -f -
```

## [Configuration](https://github.com/kubernetes-sigs/cluster-api-provider-openstack/blob/master/docs/configuration.md)

```bash
clusterctl config cluster \
  --infrastructure openstack \
  --list-variables capi-openstack
# Variables:
#   - CLUSTER_NAME
#   - CONTROL_PLANE_MACHINE_COUNT
#   - KUBERNETES_VERSION
#   - NAMESPACE
#   - OPENSTACK_CLOUD
#   - OPENSTACK_CLOUD_CACERT_B64
#   - OPENSTACK_CLOUD_PROVIDER_CONF_B64
#   - OPENSTACK_CLOUD_YAML_B64
#   - OPENSTACK_CONTROL_PLANE_MACHINE_FLAVOR
#   - OPENSTACK_DNS_NAMESERVERS
#   - OPENSTACK_FAILURE_DOMAIN
#   - OPENSTACK_IMAGE_NAME
#   - OPENSTACK_NODE_MACHINE_FLAVOR
#   - OPENSTACK_SSH_KEY_NAME
#   - WORKER_MACHINE_COUNT
```

### 오픈스택 Key Pair

![openstack-key-pair](images/openstack-key-pair.jpeg)

![openstack-image](images/openstack-image.jpeg)

```bash
mv openstack-provider.pem $HOME/.ssh/
```

### [/etc/openstack/clouds.yaml](https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)

```bash
cat /etc/openstack/clouds.yaml
```

### [Openstack credential](https://github.com/kubernetes-sigs/cluster-api-provider-openstack/blob/master/docs/configuration.md#openstack-credential)

```bash
# source env.rc <path/to/clouds.yaml> <cloud>
source scripts/env.rc scripts/etc/openstack/clouds.yaml devstack
# export CAPO_CLOUD=devstack
# export OPENSTACK_CLOUD=devstack
# export OPENSTACK_CLOUD_YAML_B64=<yaml-b64>
# export OPENSTACK_CLOUD_PROVIDER_CONF_B64=<provider-conf-b64>
# export OPENSTACK_CLOUD_CACERT_B64=<cacert-b64>
```

### [default flavors](https://docs.openstack.org/operations-guide/ops-capacity-planning-scaling.html#table-default-flavors)

| Name      | Virtual cores | Memory | Disk | Ephemeral |
| --------- | ------------- | ------ | ---- | --------- |
| m1.tiny   | 1             | 512MB  | 1GB  | 0GB       |
| m1.small  | 1             | 2GB    | 10GB | 20GB      |
| m1.medium | 2             | 4GB    | 10GB | 40GB      |
| m1.large  | 4             | 8GB    | 10GB | 80GB      |
| m1.xlarge | 8             | 16GB   | 10GB | 160GB     |

```bash
export CLUSTER_NAME=capo-test
export OPENSTACK_CONTROL_PLANE_MACHINE_FLAVOR=m1.medium
export OPENSTACK_NODE_MACHINE_FLAVOR=m1.small
export CONTROL_PLANE_MACHINE_COUNT=1
export WORKER_MACHINE_COUNT=1
export KUBERNETES_VERSION=v1.18.15
export NAMESPACE=capo-test
export OPENSTACK_DNS_NAMESERVERS=8.8.8.8
export OPENSTACK_SSH_KEY_NAME=openstack-provider
export OPENSTACK_CLUSTER_TEMPLATE=https://raw.githubusercontent.com/kubernetes-sigs/cluster-api-provider-openstack/efcc9acb81c9d92e7cca17067344aa19eea7e42b/templates/cluster-template-without-lb.yaml
# FailureDomain is the failure domain the machine will be created in.
# export OPENSTACK_FAILURE_DOMAIN=<availability zone name>
export OPENSTACK_FAILURE_DOMAIN=nova
```

### server image

- [Image builder](https://image-builder.sigs.k8s.io/capi/providers/openstack.html)

```bash
# The name of the image to use for your server instance. If the RootVolume is specified, this will be ignored and use rootVolume directly.
# export OPENSTACK_IMAGE_NAME=ubuntu-1804-kube-v.18.15
export OPENSTACK_IMAGE_NAME=<capi-image>
```

```bash
# clusterctl generate yaml \
#   --from https://github.com/kubernetes-sigs/cluster-api-provider-openstack/blob/master/templates/cluster-template-without-lb.yaml \
#   > scripts/generate.yaml
```

## 오픈스택 workload cluster 생성

```bash
# --flavor external-cloud-provider
clusterctl config cluster capo-test > scripts/capo-test.yaml
```

```bash
kubectl apply -f scripts/capo-test.yaml
```

## 리소스 확인

```bash
kubectl api-resources | grep cluster
# NAME                              SHORTNAMES   APIVERSION                                 NAMESPACED   KIND
# clusterresourcesetbindings                     addons.cluster.x-k8s.io/v1alpha3           true         ClusterResourceSetBinding
# clusterresourcesets                            addons.cluster.x-k8s.io/v1alpha3           true         ClusterResourceSet
# kubeadmconfigs                                 bootstrap.cluster.x-k8s.io/v1alpha3        true         KubeadmConfig
# kubeadmconfigtemplates                         bootstrap.cluster.x-k8s.io/v1alpha3        true         KubeadmConfigTemplate
# clusterissuers                                 cert-manager.io/v1beta1                    false        ClusterIssuer
# clusters                          cl           cluster.x-k8s.io/v1alpha3                  true         Cluster
# machinedeployments                md           cluster.x-k8s.io/v1alpha3                  true         MachineDeployment
# machinehealthchecks               mhc,mhcs     cluster.x-k8s.io/v1alpha3                  true         MachineHealthCheck
# machines                          ma           cluster.x-k8s.io/v1alpha3                  true         Machine
# machinesets                       ms           cluster.x-k8s.io/v1alpha3                  true         MachineSet
# providers                                      clusterctl.cluster.x-k8s.io/v1alpha3       true         Provider
# kubeadmcontrolplanes              kcp          controlplane.cluster.x-k8s.io/v1alpha3     true         KubeadmControlPlane
# machinepools                      mp           exp.cluster.x-k8s.io/v1alpha3              true         MachinePool
# openstackclusters                              infrastructure.cluster.x-k8s.io/v1alpha3   true         OpenStackCluster
# openstackmachines                              infrastructure.cluster.x-k8s.io/v1alpha3   true         OpenStackMachine
# openstackmachinetemplates                      infrastructure.cluster.x-k8s.io/v1alpha3   true         OpenStackMachineTemplate
```

```bash
clusterctl describe cluster --show-conditions=all --disable-grouping --disable-no-echo capo-test
# NAME                                                                     READY  SEVERITY  REASON                           SINCE  MESSAGE         
# /capo-test                                                               False  Info      WaitingForControlPlane           3m54s                  
# ├─ClusterInfrastructure - OpenStackCluster/capo-test                                                                                            
# ├─ControlPlane - KubeadmControlPlane/capo-test-control-plane                                                                                    
# └─Workers                                                                                                                                       
#   └─MachineDeployment/capo-test-md-0                                                                                                            
#     └─Machine/capo-test-md-0-656b7857f9-jlpr9                          False  Info      WaitingForInfrastructure         3m54s  0 of 2 completed
#       │           ├─BootstrapReady                                    False  Info      WaitingForClusterInfrastructure  3m54s                  
#       │           ├─InfrastructureReady                               False  Info      WaitingForInfrastructure         3m54s                  
#       │           └─NodeHealthy                                       False  Info      WaitingForNodeRef                3m54s                  
#       ├─BootstrapConfig - KubeadmConfig/capo-test-md-0-9qb8c           False  Info      WaitingForClusterInfrastructure  3m54s                  
#       │             └─DataSecretAvailable                             False  Info      WaitingForClusterInfrastructure  3m54s                  
#       └─MachineInfrastructure - OpenStackMachine/capo-test-md-0-rsrsg
```
