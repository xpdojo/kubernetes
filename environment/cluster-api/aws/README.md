# EC2 기반의 workload cluster 생성하기

- EKS 기반의 클러스터 생성하기 👉 [EKS.README.md](EKS.README.md)

## `aws`

### [Linux](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/install-cliv2-linux.html)

```bash
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### [macOS](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/install-cliv2-mac.html)

```bash
/tmp
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
# aws-cli/2.1.26 Python/3.7.4 Darwin/19.6.0 exe/x86_64 prompt/off
```

### `clusterawsadm`

- [kubernetes-sigs/cluster-api-provider-aws](https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases)

```bash
/tmp
curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.6.4/clusterawsadm-$(uname)-amd64 -o clusterawsadm
chmod +x clusterawsadm
sudo mv ./clusterawsadm /usr/local/bin/clusterawsadm
clusterawsadm version
```

### [SSH Key pair 생성](https://cluster-api-aws.sigs.k8s.io/topics/using-clusterawsadm-to-fulfill-prerequisites.html#create-a-new-key-pair)

> `.pem` 파일을 생성하기 위해 `aws configure`를 실행합니다.
> 다만 `aws configure`로 지정한 설정은 `clusterctl`에서 읽지 못합니다.

```bash
aws configure
# AWS Access Key ID [None]: <aws-access-key-id>
# AWS Secret Access Key [None]: <aws-secret-access-key>
# Default region name [None]: <region>
# Default output format [None]:
cat ~/.aws/config
# [default]
# region = ap-northeast-2
cat ~/.aws/credentials
# [default]
# aws_access_key_id = <aws-access-key-id>
# aws_secret_access_key = <aws-secret-access-key>
```

```BASH
aws ec2 create-key-pair \
  --key-name aws-provider \
  --query "KeyMaterial" \
  --output text \
  > $HOME/.ssh/aws-provider.pem

chmod 400 $HOME/.ssh/aws-provider.pem

sudo ssh-keygen -y -f $HOME/.ssh/aws-provider.pem > $HOME/.ssh/aws-provider.pub
```

```bash
# aws ec2 import-key-pair \
#   --key-name aws-provider \
#   --public-key-material fileb://$HOME/.ssh/aws-provider.pub

export AWS_SSH_KEY_NAME=aws-provider
```

- [콘솔에서 Key pair 확인하기](https://ap-northeast-2.console.aws.amazon.com/ec2/v2/home?region=ap-northeast-2#KeyPairs:)
- [모든 AWS 리전에 대해 단일 SSH 키 페어를 사용하려면 어떻게 해야 합니까?](https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-ssh-key-pair-regions/)

## 필수 Configuration

- [Initialization for common providers](https://cluster-api.sigs.k8s.io/user/quick-start.html#initialization-for-common-providers)

```bash
# clusterawsadm bootstrap iam create-cloudformation-stack
clusterawsadm bootstrap iam create-cloudformation-stack --config ./bootstrap-config.yaml
```

- [AWS IAM resources](https://cluster-api-aws.sigs.k8s.io/topics/using-clusterawsadm-to-fulfill-prerequisites.html#with-clusterawsadm)
- [AWS Security Credentials](https://console.aws.amazon.com/iam/home?#/security_credentials) - Access Key를 생성하는 페이지입니다.

```bash
clusterctl config cluster foo -i aws:v0.6.4 --list-variables
# Variables:
#   - AWS_CONTROL_PLANE_MACHINE_TYPE
#   - AWS_NODE_MACHINE_TYPE
#   - AWS_REGION
#   - AWS_SSH_KEY_NAME
#   - CLUSTER_NAME
#   - CONTROL_PLANE_MACHINE_COUNT
#   - KUBERNETES_VERSION
#   - WORKER_MACHINE_COUNT

# https://aws.amazon.com/ec2/instance-types/
export KUBERNETES_VERSION=v1.18.15
export CONTROL_PLANE_MACHINE_COUNT=1
export WORKER_MACHINE_COUNT=2
export AWS_CONTROL_PLANE_MACHINE_TYPE=t3.medium
export AWS_NODE_MACHINE_TYPE=t3.small

export AWS_ACCESS_KEY_ID=<aws-access-key-id>
export AWS_SECRET_ACCESS_KEY=<aws-secret-access-key>
export AWS_REGION=<region>
export AWS_SESSION_TOKEN=<session-token> # If you are using Multi-Factor Auth(MFA).
```

### base64 인코딩 방식의 credentials 설정

- This command uses your environment variables and encodes them in a value to be stored in a Kubernetes Secret.

```bash
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)
```

## workload cluster 생성

### Initialize the management cluster

- [clusterctl Configuration File](https://cluster-api.sigs.k8s.io/clusterctl/configuration.html)
- [verbosity 5](https://github.com/kubernetes-sigs/cluster-api/issues/3351#issuecomment-660290631)
- [Enabling EKS Support](https://cluster-api-aws.sigs.k8s.io/topics/eks/enabling.html)

![clusterctl-init](../../images/cluster/clusterctl-init.png)

_출처: [(proposal) Clusterctl redesign - Improve user experience and management across Cluster API providers](https://github.com/kubernetes-sigs/cluster-api/blob/release-0.3/docs/proposals/20191016-clusterctl-redesign.md)_

```bash
export EXP_EKS=false
export EXP_EKS_IAM=false
export EXP_EKS_ADD_ROLES=false
clusterctl init --infrastructure aws -v 5
# Installing the clusterctl inventory CRD
# Fetching providers
# Installing cert-manager Version="v0.16.1"
# Waiting for cert-manager to be available...
# Installing Provider="cluster-api" Version="v0.3.14" TargetNamespace="capi-system"
# Creating shared objects Provider="cluster-api" Version="v0.3.14"
# Creating instance objects Provider="cluster-api" Version="v0.3.14" TargetNamespace="capi-system"
# Creating inventory entry Provider="cluster-api" Version="v0.3.14" TargetNamespace="capi-system"
# Installing Provider="bootstrap-aws-eks" Version="v0.6.4" TargetNamespace="capa-eks-bootstrap-system"
# Creating shared objects Provider="bootstrap-aws-eks" Version="v0.6.4"
# Creating instance objects Provider="bootstrap-aws-eks" Version="v0.6.4" TargetNamespace="capa-eks-bootstrap-system"
# Creating inventory entry Provider="bootstrap-aws-eks" Version="v0.6.4" TargetNamespace="capa-eks-bootstrap-system"
# Installing Provider="control-plane-aws-eks" Version="v0.6.4" TargetNamespace="capa-eks-control-plane-system"
# Creating shared objects Provider="control-plane-aws-eks" Version="v0.6.4"
# Creating instance objects Provider="control-plane-aws-eks" Version="v0.6.4" TargetNamespace="capa-eks-control-plane-system"
# Creating inventory entry Provider="control-plane-aws-eks" Version="v0.6.4" TargetNamespace="capa-eks-control-plane-system"
# Installing Provider="infrastructure-aws" Version="v0.6.4" TargetNamespace="capa-system"
# Creating shared objects Provider="infrastructure-aws" Version="v0.6.4"
# Creating instance objects Provider="infrastructure-aws" Version="v0.6.4" TargetNamespace="capa-system"
# Creating inventory entry Provider="infrastructure-aws" Version="v0.6.4" TargetNamespace="capa-system"
#
# Your management cluster has been initialized successfully!
#
# You can now create your first workload cluster by running the following:
#
#   clusterctl config cluster [name] --kubernetes-version [version] | kubectl apply -f -
```

### 실제 workload cluster 생성

> control-plane 노드를 짝수로 설정하면 오류가 발생합니다.\
> spec.replicas: Forbidden: cannot be an even number when using managed etcd

![clusterctl-create-cluster](../../images/cluster/clusterctl-create-cluster.png)

_출처: [(proposal) Clusterctl redesign - Improve user experience and management across Cluster API providers](https://github.com/kubernetes-sigs/cluster-api/blob/release-0.3/docs/proposals/20191016-clusterctl-redesign.md)_

```bash
clusterctl config cluster capa-test > aws/scripts/capa-test.yaml

# VPC Dashboard: Security Group, EIP, ELB, VPC, NAT Gateway, Subnets, Route Tables, Internet Gateways, Network ACL
# EC2 Dashboard: Instances -> Volume
sudo kubectl apply -f aws/scripts/capa-test.yaml

clusterctl describe cluster --show-conditions=all --disable-grouping --disable-no-echo capa-test
# NAME                                                                READY  SEVERITY  REASON                           SINCE  MESSAGE         
# /capa-test                                                          False  Info      WaitingForControlPlane           91s                    
# ├─ClusterInfrastructure - AWSCluster/capa-test                    False  Info      NatGatewaysCreationStarted       88s    3 of 7 completed
# │             ├─InternetGatewayReady                             True                                              88s                    
# │             ├─NatGatewaysReady                                 False  Info      NatGatewaysCreationStarted       88s                    
# │             ├─SubnetsReady                                     True                                              88s                    
# │             └─VpcReady                                         True                                              91s                    
# ├─ControlPlane - KubeadmControlPlane/capa-test-control-plane                                                                               
# └─Workers                                                                                                                                  
#   └─MachineDeployment/capa-test-md-0                                                                                                       
#     ├─Machine/capa-test-md-0-67b9597f8c-f58d7                     False  Info      WaitingForClusterInfrastructure  91s    0 of 2 completed
#     │ │           ├─BootstrapReady                              False  Info      WaitingForClusterInfrastructure  91s                    
#     │ │           ├─InfrastructureReady                         False  Info      WaitingForClusterInfrastructure  91s    0 of 2 completed
#     │ │           └─NodeHealthy                                 False  Info      WaitingForNodeRef                91s                    
#     │ ├─BootstrapConfig - KubeadmConfig/capa-test-md-0-pq2rw     False  Info      WaitingForClusterInfrastructure  92s                    
#     │ │             └─DataSecretAvailable                       False  Info      WaitingForClusterInfrastructure  92s                    
#     │ └─MachineInfrastructure - AWSMachine/capa-test-md-0-5dvcf  False  Info      WaitingForClusterInfrastructure  91s    0 of 2 completed
#     │               └─InstanceReady                              False  Info      WaitingForClusterInfrastructure  91s                    
#     └─Machine/capa-test-md-0-67b9597f8c-zbcb4                     False  Info      WaitingForClusterInfrastructure  91s    0 of 2 completed
#       │           ├─BootstrapReady                               False  Info      WaitingForClusterInfrastructure  91s                    
#       │           ├─InfrastructureReady                          False  Info      WaitingForClusterInfrastructure  91s    0 of 2 completed
#       │           └─NodeHealthy                                  False  Info      WaitingForNodeRef                91s                    
#       ├─BootstrapConfig - KubeadmConfig/capa-test-md-0-q25rq      False  Info      WaitingForClusterInfrastructure  92s                    
#       │             └─DataSecretAvailable                        False  Info      WaitingForClusterInfrastructure  92s                    
#       └─MachineInfrastructure - AWSMachine/capa-test-md-0-mf8p4   False  Info      WaitingForClusterInfrastructure  92s    0 of 2 completed
#                     └─InstanceReady                               False  Info      WaitingForClusterInfrastructure  92s 

# 약 15분 뒤...
clusterctl describe cluster --show-conditions=all --disable-grouping --disable-no-echo capa-test
# NAME                                                                       READY  SEVERITY  REASON                SINCE  MESSAGE                        
# /capa-test                                                                 True                                   3m40s                                 
# ├─ClusterInfrastructure - AWSCluster/capa-test                           True                                   6m46s                                 
# │             ├─ClusterSecurityGroupsReady                              True                                   8m21s                                 
# │             ├─InternetGatewayReady                                    True                                   10m                                   
# │             ├─LoadBalancerReady                                       True                                   6m46s                                 
# │             ├─NatGatewaysReady                                        True                                   8m20s                                 
# │             ├─RouteTablesReady                                        True                                   8m23s                                 
# │             ├─SubnetsReady                                            True                                   10m                                   
# │             └─VpcReady                                                True                                   10m                                   
# ├─ControlPlane - KubeadmControlPlane/capa-test-control-plane             True                                   3m40s                                 
# │ │           ├─Available                                              True                                   3m40s                                 
# │ │           ├─CertificatesAvailable                                  True                                   6m45s                                 
# │ │           ├─ControlPlaneComponentsHealthy                          True                                   59s                                   
# │ │           ├─EtcdClusterHealthyCondition                            True                                   59s                                   
# │ │           ├─MachinesReady                                          True                                   6m27s                                 
# │ │           └─Resized                                                True                                   6m27s                                 
# │ └─Machine/capa-test-control-plane-7kx42                               True                                   6m27s                                 
# │   │           ├─APIServerPodHealthy                                  True                                   59s                                   
# │   │           ├─BootstrapReady                                       True                                   6m45s                                 
# │   │           ├─ControllerManagerPodHealthy                          True                                   59s                                   
# │   │           ├─EtcdMemberHealthy                                    True                                   59s                                   
# │   │           ├─EtcdPodHealthy                                       True                                   59s                                   
# │   │           ├─InfrastructureReady                                  True                                   6m27s                                 
# │   │           ├─NodeHealthy                                          False  Warning   NodeConditionsFailed  59s    Node condition Ready is False. 
# │   │           └─SchedulerPodHealthy                                  True                                   59s                                   
# │   ├─BootstrapConfig - KubeadmConfig/capa-test-control-plane-r86pr     True                                   6m45s                                 
# │   │             ├─CertificatesAvailable                              True                                   6m45s                                 
# │   │             └─DataSecretAvailable                                True                                   6m45s                                 
# │   └─MachineInfrastructure - AWSMachine/capa-test-control-plane-ttws5  True                                   6m27s                                 
# │                 ├─ELBAttached                                         True                                   6m28s                                 
# │                 ├─InstanceReady                                       True                                   6m27s                                 
# │                 └─SecurityGroupsReady                                 True                                   6m28s                                 
# └─Workers                                                                                                                                             
#   └─MachineDeployment/capa-test-md-0                                                                                                                  
#     ├─Machine/capa-test-md-0-67b9597f8c-f58d7                            True                                   2m58s                                 
#     │ │           ├─BootstrapReady                                     True                                   3m16s                                 
#     │ │           ├─InfrastructureReady                                True                                   2m58s                                 
#     │ │           └─NodeHealthy                                        False  Warning   NodeConditionsFailed  2m17s  Node condition Ready is False. 
#     │ ├─BootstrapConfig - KubeadmConfig/capa-test-md-0-pq2rw            True                                   3m16s                                 
#     │ │             ├─CertificatesAvailable                            True                                   3m16s                                 
#     │ │             └─DataSecretAvailable                              True                                   3m16s                                 
#     │ └─MachineInfrastructure - AWSMachine/capa-test-md-0-5dvcf         True                                   2m58s                                 
#     │               ├─InstanceReady                                     True                                   2m58s                                 
#     │               └─SecurityGroupsReady                               True                                   2m58s                                 
#     └─Machine/capa-test-md-0-67b9597f8c-zbcb4                            True                                   2m58s                                 
#       │           ├─BootstrapReady                                      True                                   3m16s                                 
#       │           ├─InfrastructureReady                                 True                                   2m58s                                 
#       │           └─NodeHealthy                                         False  Warning   NodeConditionsFailed  2m17s  Node condition Ready is False. 
#       ├─BootstrapConfig - KubeadmConfig/capa-test-md-0-q25rq             True                                   3m16s                                 
#       │             ├─CertificatesAvailable                             True                                   3m16s                                 
#       │             └─DataSecretAvailable                               True                                   3m16s                                 
#       └─MachineInfrastructure - AWSMachine/capa-test-md-0-mf8p4          True                                   2m58s                                 
#                     ├─InstanceReady                                      True                                   2m58s                                 
#                     └─SecurityGroupsReady                                True                                   2m58s 
```

> CNI 배포 후 `NodeHealthy` 부분은 `True`로 변경됩니다.

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
# awsclusters                                    infrastructure.cluster.x-k8s.io/v1alpha3   true         AWSCluster
# awsmachinepools                                infrastructure.cluster.x-k8s.io/v1alpha3   true         AWSMachinePool
# awsmachines                                    infrastructure.cluster.x-k8s.io/v1alpha3   true         AWSMachine
# awsmachinetemplates                            infrastructure.cluster.x-k8s.io/v1alpha3   true         AWSMachineTemplate
# awsmanagedclusters                awsmc        infrastructure.cluster.x-k8s.io/v1alpha3   true         AWSManagedCluster
# awsmanagedmachinepools                         infrastructure.cluster.x-k8s.io/v1alpha3   true         AWSManagedMachinePool

# kubectl get cl -A
kubectl get cluster -A
# NAMESPACE   NAME        PHASE
# default     capa-test   Provisioned

# kubectl get kcp -A
kubectl get kubeadmcontrolplane -A
# NAMESPACE   NAME                      INITIALIZED   API SERVER AVAILABLE   VERSION    REPLICAS   READY   UPDATED   UNAVAILABLE
# default     capa-test-control-plane   true                                 v1.18.15   1                  1         1

# 아래에서 "CNI 솔루션 배포"까지 실행하면 API SERVER가 true로 바뀝니다.

# kubectl get ma -A
kubectl get machine -A
# NAMESPACE   NAME                              PROVIDERID                                   PHASE     VERSION
# default     capa-test-control-plane-7kx42     aws:///ap-northeast-2c/i-048d85d5c372f0bd3   Running   v1.18.15
# default     capa-test-md-0-67b9597f8c-f58d7   aws:///ap-northeast-2a/i-05bd148f247547ae8   Running   v1.18.15
# default     capa-test-md-0-67b9597f8c-zbcb4   aws:///ap-northeast-2a/i-0f905a5027d4d12ac   Running   v1.18.15

# kubectl get po -A
kubectl get pods -A
# NAMESPACE                           NAME                                                             READY   STATUS    RESTARTS   AGE
# capa-system                         capa-controller-manager-9c8d86fd5-nkvfd                          2/2     Running   0          13m
# capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-859d5f5b95-f4l2g       2/2     Running   0          13m
# capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-65b965795b-lm25q   2/2     Running   0          13m
# capi-system                         capi-controller-manager-6f58d487c6-9qqc7                         2/2     Running   0          13m
# capi-webhook-system                 capa-controller-manager-cb9775c5c-nltn7                          2/2     Running   0          13m
# capi-webhook-system                 capi-controller-manager-8594f758d7-tz2m4                         2/2     Running   0          13m
# capi-webhook-system                 capi-kubeadm-bootstrap-controller-manager-764fbdf7db-lw66s       2/2     Running   0          13m
# capi-webhook-system                 capi-kubeadm-control-plane-controller-manager-8f4744fbc-h8lfs    2/2     Running   0          13m
# cert-manager                        cert-manager-578cd6d964-4cn42                                    1/1     Running   0          13m
# cert-manager                        cert-manager-cainjector-5ffff9dd7c-hbxct                         1/1     Running   0          13m
# cert-manager                        cert-manager-webhook-556b9d7dfd-czrtz                            1/1     Running   0          13m
# ...
```

- 로그 확인

```bash
kubectl get ev
# LAST SEEN   TYPE      REASON                                          OBJECT                                     MESSAGE
# 7m27s       Warning   Failed to retrieve Node by ProviderID           machine/capa-test-control-plane-7kx42      the cache is not started, can not read objects
# 4m43s       Normal    SuccessfulSetNodeRef                            machine/capa-test-control-plane-7kx42      ip-10-0-216-238.ap-northeast-2.compute.internal
# 10m         Normal    SuccessfulCreate                                awsmachine/capa-test-control-plane-ttws5   Created new control-plane instance with id "i-048d85d5c372f0bd3"
# 10m         Normal    SuccessfulAttachControlPlaneELB                 awsmachine/capa-test-control-plane-ttws5   Control plane instance "i-048d85d5c372f0bd3" is registered with load balancer
# 4m43s       Normal    SuccessfulDeleteEncryptedBootstrapDataSecrets   awsmachine/capa-test-control-plane-ttws5   AWS Secret entries containing userdata deleted
# 16m         Normal    NodeHasSufficientMemory                         node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeHasSufficientMemory
# 16m         Normal    NodeHasNoDiskPressure                           node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeHasNoDiskPressure
# 16m         Normal    NodeHasSufficientPID                            node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeHasSufficientPID
# 16m         Normal    Starting                                        node/capa-test-control-plane               Starting kubelet.
# 16m         Normal    NodeAllocatableEnforced                         node/capa-test-control-plane               Updated Node Allocatable limit across pods
# 16m         Normal    NodeHasSufficientMemory                         node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeHasSufficientMemory
# 16m         Normal    NodeHasNoDiskPressure                           node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeHasNoDiskPressure
# 16m         Normal    NodeHasSufficientPID                            node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeHasSufficientPID
# 15m         Normal    RegisteredNode                                  node/capa-test-control-plane               Node capa-test-control-plane event: Registered Node capa-test-control-plane in Controller
# 15m         Warning   readOnlySysFS                                   node/capa-test-control-plane               CRI error: /sys is read-only: cannot modify conntrack limits, problems may arise later (If running Docker, see docker issue #24000)
# 15m         Normal    Starting                                        node/capa-test-control-plane               Starting kube-proxy.
# 15m         Normal    NodeReady                                       node/capa-test-control-plane               Node capa-test-control-plane status is now: NodeReady
# 6m42s       Normal    SuccessfulCreate                                awsmachine/capa-test-md-0-5dvcf            Created new node instance with id "i-05bd148f247547ae8"
# 6m1s        Normal    SuccessfulDeleteEncryptedBootstrapDataSecrets   awsmachine/capa-test-md-0-5dvcf            AWS Secret entries containing userdata deleted
# 6m1s        Normal    SuccessfulSetNodeRef                            machine/capa-test-md-0-67b9597f8c-f58d7    ip-10-0-85-153.ap-northeast-2.compute.internal
# 6m1s        Normal    SuccessfulSetNodeRef                            machine/capa-test-md-0-67b9597f8c-zbcb4    ip-10-0-127-68.ap-northeast-2.compute.internal
# 14m         Normal    SuccessfulCreate                                machineset/capa-test-md-0-67b9597f8c       Created machine "capa-test-md-0-67b9597f8c-f58d7"
# 14m         Normal    SuccessfulCreate                                machineset/capa-test-md-0-67b9597f8c       Created machine "capa-test-md-0-67b9597f8c-zbcb4"
# 6m42s       Normal    SuccessfulCreate                                awsmachine/capa-test-md-0-mf8p4            Created new node instance with id "i-0f905a5027d4d12ac"
# 6m1s        Normal    SuccessfulDeleteEncryptedBootstrapDataSecrets   awsmachine/capa-test-md-0-mf8p4            AWS Secret entries containing userdata deleted
# 14m         Normal    SuccessfulCreate                                machinedeployment/capa-test-md-0           Created MachineSet "capa-test-md-0-67b9597f8c"
# 15m         Normal    NodeHasSufficientMemory                         node/capa-test-worker                      Node capa-test-worker status is now: NodeHasSufficientMemory
# 15m         Normal    NodeHasNoDiskPressure                           node/capa-test-worker                      Node capa-test-worker status is now: NodeHasNoDiskPressure
# 15m         Normal    NodeHasSufficientPID                            node/capa-test-worker                      Node capa-test-worker status is now: NodeHasSufficientPID
# 15m         Normal    RegisteredNode                                  node/capa-test-worker                      Node capa-test-worker event: Registered Node capa-test-worker in Controller
# 15m         Warning   readOnlySysFS                                   node/capa-test-worker                      CRI error: /sys is read-only: cannot modify conntrack limits, problems may arise later (If running Docker, see docker issue #24000)
# 15m         Normal    Starting                                        node/capa-test-worker                      Starting kube-proxy.
# 15m         Normal    NodeReady                                       node/capa-test-worker                      Node capa-test-worker status is now: NodeReady
# 14m         Normal    SuccessfulCreateVPC                             awscluster/capa-test                       Created new managed VPC "vpc-03c90323c19032d73"
# 14m         Normal    SuccessfulSetVPCAttributes                      awscluster/capa-test                       Set managed VPC attributes for "vpc-03c90323c19032d73"
# 14m         Normal    SuccessfulCreateSubnet                          awscluster/capa-test                       Created new managed Subnet "subnet-03fe84405cf21b915"
# 14m         Normal    SuccessfulModifySubnetAttributes                awscluster/capa-test                       Modified managed Subnet "subnet-03fe84405cf21b915" attributes
# 14m         Normal    SuccessfulCreateSubnet                          awscluster/capa-test                       Created new managed Subnet "subnet-0079d39b3c4fc87a9"
# 14m         Normal    SuccessfulCreateSubnet                          awscluster/capa-test                       Created new managed Subnet "subnet-062e26c8f22e5e517"
# 14m         Normal    SuccessfulModifySubnetAttributes                awscluster/capa-test                       Modified managed Subnet "subnet-062e26c8f22e5e517" attributes
# 14m         Normal    SuccessfulCreateSubnet                          awscluster/capa-test                       Created new managed Subnet "subnet-0a0aa6f30eaf47664"
# 14m         Normal    SuccessfulCreateSubnet                          awscluster/capa-test                       Created new managed Subnet "subnet-0fc15c95918abc4ae"
# 14m         Normal    SuccessfulModifySubnetAttributes                awscluster/capa-test                       Modified managed Subnet "subnet-0fc15c95918abc4ae" attributes
# 14m         Normal    SuccessfulCreateSubnet                          awscluster/capa-test                       Created new managed Subnet "subnet-0d2925fb81fe1b384"
# 14m         Normal    SuccessfulCreateInternetGateway                 awscluster/capa-test                       Created new managed Internet Gateway "igw-074170e6a56b63d25"
# 14m         Normal    SuccessfulAttachInternetGateway                 awscluster/capa-test                       Internet Gateway "igw-074170e6a56b63d25" attached to VPC "vpc-03c90323c19032d73"
# 14m         Normal    SuccessfulCreateNATGateway                      awscluster/capa-test                       Created new NAT Gateway "nat-0e9b9940dfcd3208e"
# 14m         Normal    SuccessfulCreateNATGateway                      awscluster/capa-test                       Created new NAT Gateway "nat-00341ffd082a64d45"
# 14m         Normal    SuccessfulCreateNATGateway                      awscluster/capa-test                       Created new NAT Gateway "nat-0f42bea5f3b0205c9"
# 12m         Normal    SuccessfulCreateRouteTable                      awscluster/capa-test                       Created managed RouteTable "rtb-099bb7cee3f99812f"
# 12m         Normal    SuccessfulCreateRoute                           awscluster/capa-test                       Created route {
#   DestinationCidrBlock: "0.0.0.0/0",
#   GatewayId: "igw-074170e6a56b63d25"
# } for RouteTable "rtb-099bb7cee3f99812f"
# 12m         Normal    SuccessfulAssociateRouteTable                   awscluster/capa-test                       Associated managed RouteTable "rtb-099bb7cee3f99812f" with subnet "subnet-03fe84405cf21b915"
# 12m         Normal    SuccessfulCreateRouteTable                      awscluster/capa-test                       Created managed RouteTable "rtb-061cae3f2a57d9a06"
# 12m         Normal    SuccessfulCreateRoute                           awscluster/capa-test                       Created route {
#   DestinationCidrBlock: "0.0.0.0/0",
#   NatGatewayId: "nat-0f42bea5f3b0205c9"
# } for RouteTable "rtb-061cae3f2a57d9a06"
# 12m         Normal    SuccessfulAssociateRouteTable                   awscluster/capa-test                       Associated managed RouteTable "rtb-061cae3f2a57d9a06" with subnet "subnet-0079d39b3c4fc87a9"
# 12m         Normal    SuccessfulCreateRouteTable                      awscluster/capa-test                       Created managed RouteTable "rtb-0576b70025ef842e7"
# 12m         Normal    SuccessfulCreateRoute                           awscluster/capa-test                       Created route {
#   DestinationCidrBlock: "0.0.0.0/0",
#   GatewayId: "igw-074170e6a56b63d25"
# } for RouteTable "rtb-0576b70025ef842e7"
# 12m         Normal    SuccessfulAssociateRouteTable                   awscluster/capa-test                       Associated managed RouteTable "rtb-0576b70025ef842e7" with subnet "subnet-062e26c8f22e5e517"
# 12m         Normal    SuccessfulCreateRouteTable                      awscluster/capa-test                       Created managed RouteTable "rtb-0b9d2227e6136c220"
# 12m         Normal    SuccessfulCreateRoute                           awscluster/capa-test                       Created route {
#   DestinationCidrBlock: "0.0.0.0/0",
#   NatGatewayId: "nat-0e9b9940dfcd3208e"
# } for RouteTable "rtb-0b9d2227e6136c220"
# 12m         Normal    SuccessfulAssociateRouteTable                   awscluster/capa-test                       Associated managed RouteTable "rtb-0b9d2227e6136c220" with subnet "subnet-0a0aa6f30eaf47664"
# 12m         Normal    SuccessfulCreateRouteTable                      awscluster/capa-test                       Created managed RouteTable "rtb-06f95a514c92c6756"
# 12m         Normal    SuccessfulCreateRoute                           awscluster/capa-test                       Created route {
#   DestinationCidrBlock: "0.0.0.0/0",
#   GatewayId: "igw-074170e6a56b63d25"
# } for RouteTable "rtb-06f95a514c92c6756"
# 12m         Normal    SuccessfulAssociateRouteTable                   awscluster/capa-test                       Associated managed RouteTable "rtb-06f95a514c92c6756" with subnet "subnet-0fc15c95918abc4ae"
# 12m         Normal    SuccessfulCreateRouteTable                      awscluster/capa-test                       Created managed RouteTable "rtb-09ef2696159bcb2af"
# 12m         Normal    SuccessfulCreateRoute                           awscluster/capa-test                       Created route {
#   DestinationCidrBlock: "0.0.0.0/0",
#   NatGatewayId: "nat-00341ffd082a64d45"
# } for RouteTable "rtb-09ef2696159bcb2af"
# 12m         Normal    SuccessfulAssociateRouteTable                   awscluster/capa-test                       Associated managed RouteTable "rtb-09ef2696159bcb2af" with subnet "subnet-0d2925fb81fe1b384"
# 12m         Normal    SuccessfulCreateSecurityGroup                   awscluster/capa-test                       Created managed SecurityGroup "sg-04fac49fa4331260d" for Role "bastion"
# 12m         Normal    SuccessfulCreateSecurityGroup                   awscluster/capa-test                       Created managed SecurityGroup "sg-047f918e31c321220" for Role "apiserver-lb"
# 12m         Normal    SuccessfulCreateSecurityGroup                   awscluster/capa-test                       Created managed SecurityGroup "sg-05c0b74455475b0b1" for Role "lb"
# 12m         Normal    SuccessfulCreateSecurityGroup                   awscluster/capa-test                       Created managed SecurityGroup "sg-09e6fdf261879ff05" for Role "controlplane"
# 12m         Normal    SuccessfulCreateSecurityGroup                   awscluster/capa-test                       Created managed SecurityGroup "sg-05fc6828785345171" for Role "node"
# 12m         Normal    SuccessfulAuthorizeSecurityGroupIngressRules    awscluster/capa-test                       Authorized security group ingress rules [protocol=tcp/range=[179-179]/description=bgp (calico) protocol=4/range=[-1-65535]/description=IP-in-IP (calico) protocol=tcp/range=[22-22]/description=SSH protocol=tcp/range=[6443-6443]/description=Kubernetes API protocol=tcp/range=[2379-2379]/description=etcd protocol=tcp/range=[2380-2380]/description=etcd peer] for SecurityGroup "sg-09e6fdf261879ff05"
# 12m         Normal    SuccessfulAuthorizeSecurityGroupIngressRules    awscluster/capa-test                       Authorized security group ingress rules [protocol=tcp/range=[179-179]/description=bgp (calico) protocol=4/range=[-1-65535]/description=IP-in-IP (calico) protocol=tcp/range=[22-22]/description=SSH protocol=tcp/range=[30000-32767]/description=Node Port Services protocol=tcp/range=[10250-10250]/description=Kubelet API] for SecurityGroup "sg-05fc6828785345171"
# 12m         Normal    SuccessfulAuthorizeSecurityGroupIngressRules    awscluster/capa-test                       Authorized security group ingress rules [protocol=tcp/range=[22-22]/description=SSH] for SecurityGroup "sg-04fac49fa4331260d"
# 12m         Normal    SuccessfulAuthorizeSecurityGroupIngressRules    awscluster/capa-test                       Authorized security group ingress rules [protocol=tcp/range=[6443-6443]/description=Kubernetes API] for SecurityGroup "sg-047f918e31c321220"

kubectl cluster-info dump > dump.json
less dump.json
```

### workload cluster 확인하기

- kubeconfig

```bash
clusterctl get kubeconfig capa-test > capa-test.kubeconfig
kubectl --kubeconfig=./capa-test.kubeconfig get pods -A
# NAMESPACE     NAME                                                                      READY   STATUS    RESTARTS   AGE
# kube-system   coredns-66bff467f8-6swm9                                                  0/1     Pending   0          93m
# kube-system   coredns-66bff467f8-pnt6s                                                  0/1     Pending   0          93m
# kube-system   etcd-ip-10-0-220-242.ap-northeast-2.compute.internal                      1/1     Running   0          94m
# kube-system   kube-apiserver-ip-10-0-220-242.ap-northeast-2.compute.internal            1/1     Running   0          94m
# kube-system   kube-controller-manager-ip-10-0-220-242.ap-northeast-2.compute.internal   1/1     Running   0          94m
# kube-system   kube-proxy-2pds2                                                          1/1     Running   0          92m
# kube-system   kube-proxy-5246w                                                          1/1     Running   0          92m
# kube-system   kube-proxy-c8ghl                                                          1/1     Running   0          93m
# kube-system   kube-scheduler-ip-10-0-220-242.ap-northeast-2.compute.internal            1/1     Running   0          94m
```

### CNI 솔루션 배포

```bash
kubectl --kubeconfig=./capa-test.kubeconfig \
  apply -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml

kubectl --kubeconfig=./capa-test.kubeconfig get nodes
# NAME                                              STATUS   ROLES    AGE    VERSION
# ip-10-0-123-138.ap-northeast-2.compute.internal   Ready    <none>   101m   v1.18.15
# ip-10-0-127-50.ap-northeast-2.compute.internal    Ready    <none>   101m   v1.18.15
# ip-10-0-220-242.ap-northeast-2.compute.internal   Ready    master   103m   v1.18.15
```

- API SERVER 값이 `true`로 변경됨

```bash
kubectl get kcp
# NAME                      INITIALIZED   API SERVER AVAILABLE   VERSION    REPLICAS   READY   UPDATED   UNAVAILABLE
# capa-test-control-plane   true          true                   v1.18.15   1          1       1
```

## Clean up

```bash
kubectl delete cluster capa-test
```

- 위 명령어를 실행하고 (EC2 대시보드, VPC 대시보드, kubernete event log) 확인해보면 아래 순서대로 제거되었는데 실제로 비동기로 동작하는 건지는 찾아봐야겠습니다.
  - EC2 Instance(워커 노드)
  - Dedicated Hosts
  - EC2 Instance(컨트롤 플레인)
  - Volume
  - Elastic Load Balancing (ELB)
  - Security Group
  - NAT Gateways
  - Virtual Private Cloud (VPC)
  - Elastic IP address (EIP)
  - Route Tables (RTB)
- 시간이 꽤 걸립니다.

```bash
clusterctl delete --infrastructure aws
# Deleting Provider="infrastructure-aws" Version="" TargetNamespace="capa-system"
```

```bash
kind delete cluster --name capa-test
```
