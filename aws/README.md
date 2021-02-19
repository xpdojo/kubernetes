# EC2 기반의 workload cluster 생성하기

- EKS 기반의 클러스터 생성하기 👉 [EKS.README.md](EKS.README.md)

## [`aws`](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/install-cliv2-mac.html)

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
# aws-cli/2.1.26 Python/3.7.4 Darwin/19.6.0 exe/x86_64 prompt/off
```

## 필수 Configuration

- https://cluster-api.sigs.k8s.io/user/quick-start.html#initialization-for-common-providers
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

### [SSH Key pair 생성](https://cluster-api-aws.sigs.k8s.io/topics/using-clusterawsadm-to-fulfill-prerequisites.html#create-a-new-key-pair)

> 아래처럼 aws 명령어로 지정한 config는 clusterctl에서 읽지 못합니다.

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
aws ec2 import-key-pair \
  --key-name aws-provider \
  --public-key-material fileb://$HOME/.ssh/aws-provider.pub

export AWS_SSH_KEY_NAME=aws-provider
```

- [콘솔에서 Key pair 확인하기](https://ap-northeast-2.console.aws.amazon.com/ec2/v2/home?region=ap-northeast-2#KeyPairs:)
- [모든 AWS 리전에 대해 단일 SSH 키 페어를 사용하려면 어떻게 해야 합니까?](https://aws.amazon.com/ko/premiumsupport/knowledge-center/ec2-ssh-key-pair-regions/)

### `clusterawsadm`

- [kubernetes-sigs/cluster-api-provider-aws](https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases)

```bash
curl -L https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.6.4/clusterawsadm-$(uname)-amd64 -o clusterawsadm
chmod +x clusterawsadm
mv ./clusterawsadm /usr/local/bin/clusterawsadm
clusterawsadm version
```

### base64 인코딩 방식의 credentials 설정

- This command uses your environment variables and encodes them in a value to be stored in a Kubernetes Secret.

```bash
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)
```

## EC2 기반의 workload cluster 생성하기

### Initialize the management cluster

- [clusterctl Configuration File](https://cluster-api.sigs.k8s.io/clusterctl/configuration.html)
- [verbosity 5](https://github.com/kubernetes-sigs/cluster-api/issues/3351#issuecomment-660290631)
- [Enabling EKS Support](https://cluster-api-aws.sigs.k8s.io/topics/eks/enabling.html)

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

```bash
clusterctl config cluster capi-aws > capi-aws.yaml

# VPC Dashboard: Security Group, EIP, ELB, VPC, NAT Gateway, Subnets, Route Tables, Internet Gateways, Network ACL
# EC2 Dashboard: Instances -> Volume
sudo kubectl apply -f capi-aws.yaml
# NAME                                                           READY  SEVERITY  REASON                   SINCE  MESSAGE                                                         
# /capi-aws                                                      False  Info      WaitingForKubeadmInit    4m7s                                                                   
# ├─ClusterInfrastructure - AWSCluster/capi-aws                True                                      4m29s                                                                  
# ├─ControlPlane - KubeadmControlPlane/capi-aws-control-plane  False  Info      WaitingForKubeadmInit    4m7s                                                                   
# │ └─Machine/capi-aws-control-plane-lbhzg                    True                                      4m7s                                                                   
# └─Workers                                                                                                                                                                     
#   └─MachineDeployment/capi-aws-md-0                                                                                                                                           
#     └─2 Machines...

# 약 15분 뒤...
sudo kubectl apply -f capi-aws.yaml
# NAME                                                           READY  SEVERITY  REASON  SINCE  MESSAGE
# /capi-aws                                                      True                     11m
# ├─ClusterInfrastructure - AWSCluster/capi-aws                True                     13m
# ├─ControlPlane - KubeadmControlPlane/capi-aws-control-plane  True                     11m
# │ └─Machine/capi-aws-control-plane-s7jln                    True                     13m
# └─Workers
#   └─MachineDeployment/capi-aws-md-0
#     └─2 Machines...                                          True                     10m    See capi-aws-md-0-79d657658-b5grc, capi-aws-md-0-79d657658-xq2x6

kubectl api-resources | grep cluster.x-k8s.io
# NAME                              SHORTNAMES   APIVERSION                                 NAMESPACED   KIND
# clusterresourcesetbindings                     addons.cluster.x-k8s.io/v1alpha3           true         ClusterResourceSetBinding
# clusterresourcesets                            addons.cluster.x-k8s.io/v1alpha3           true         ClusterResourceSet
# kubeadmconfigs                                 bootstrap.cluster.x-k8s.io/v1alpha3        true         KubeadmConfig
# kubeadmconfigtemplates                         bootstrap.cluster.x-k8s.io/v1alpha3        true         KubeadmConfigTemplate
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
# default     capi-aws    Provisioning

# kubectl get kcp -A
kubectl get kubeadmcontrolplane -A
# NAMESPACE   NAME                     INITIALIZED   API SERVER AVAILABLE   VERSION    REPLICAS   READY   UPDATED   UNAVAILABLE
# default     capi-aws-control-plane   true                                 v1.18.15   1                  1         1

# 아래에서 "CNI 솔루션 배포"까지 실행하면 API SERVER가 true로 바뀝니다.

# kubectl get ma -A
kubectl get machine -A
# NAMESPACE   NAME                            PROVIDERID                                   PHASE     VERSION
# default     capi-aws-control-plane-s7jln    aws:///ap-northeast-2c/i-013ca34fa0bae548d   Running   v1.18.15
# default     capi-aws-md-0-79d657658-b5grc   aws:///ap-northeast-2a/i-0f40db68af2fffbe4   Running   v1.18.15
# default     capi-aws-md-0-79d657658-xq2x6   aws:///ap-northeast-2a/i-0f3e818bec335902d   Running   v1.18.15

# kubectl get po -A
kubectl get pod -A
# NAMESPACE                           NAME                                                             READY   STATUS    RESTARTS   AGE
# capa-system                         capa-controller-manager-9c8d86fd5-4fncv                          2/2     Running   0          84m
# capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-859d5f5b95-pvzrf       2/2     Running   0          85m
# capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-65b965795b-nclbp   2/2     Running   0          84m
# capi-system                         capi-controller-manager-6f58d487c6-tv6mm                         2/2     Running   0          85m
# capi-webhook-system                 capa-controller-manager-cb9775c5c-gh6gx                          2/2     Running   0          84m
# capi-webhook-system                 capi-controller-manager-8594f758d7-x5m5p                         2/2     Running   0          85m
# capi-webhook-system                 capi-kubeadm-bootstrap-controller-manager-764fbdf7db-6hd55       2/2     Running   0          85m
# capi-webhook-system                 capi-kubeadm-control-plane-controller-manager-8f4744fbc-qxt4j    2/2     Running   0          84m
# cert-manager                        cert-manager-578cd6d964-wg2mz                                    1/1     Running   0          86m
# cert-manager                        cert-manager-cainjector-5ffff9dd7c-mvs8h                         1/1     Running   0          86m
# cert-manager                        cert-manager-webhook-556b9d7dfd-kqbhh                            1/1     Running   0          86m
# kube-system                         coredns-66bff467f8-lq7kg                                         1/1     Running   0          98m
# kube-system                         coredns-66bff467f8-xks8x                                         1/1     Running   0          98m
# kube-system                         etcd-clusterapi-control-plane                                    1/1     Running   0          98m
# kube-system                         kindnet-69j7p                                                    1/1     Running   0          98m
# kube-system                         kindnet-6cwpl                                                    1/1     Running   0          98m
# kube-system                         kindnet-rmx6f                                                    1/1     Running   0          98m
# kube-system                         kube-apiserver-clusterapi-control-plane                          1/1     Running   0          98m
# kube-system                         kube-controller-manager-clusterapi-control-plane                 1/1     Running   0          98m
# kube-system                         kube-proxy-6sqvg                                                 1/1     Running   0          98m
# kube-system                         kube-proxy-g7stq                                                 1/1     Running   0          98m
# kube-system                         kube-proxy-ttsj2                                                 1/1     Running   0          98m
# kube-system                         kube-scheduler-clusterapi-control-plane                          1/1     Running   0          98m
# local-path-storage                  local-path-provisioner-5b4b545c55-n8wjh                          1/1     Running   0          98m
```

- 로그 확인

```bash
kubectl get ev
# LAST SEEN   TYPE     REASON                                          OBJECT                                    MESSAGE
# 59m         Normal   SuccessfulCreate                                awsmachine/capi-aws-control-plane-lhzcr   Created new control-plane instance with id "i-013ca34fa0bae548d"
# 59m         Normal   SuccessfulAttachControlPlaneELB                 awsmachine/capi-aws-control-plane-lhzcr   Control plane instance "i-013ca34fa0bae548d" is registered with load balancer
# 57m         Normal   SuccessfulDeleteEncryptedBootstrapDataSecrets   awsmachine/capi-aws-control-plane-lhzcr   AWS Secret entries containing userdata deleted
# 57m         Normal   SuccessfulSetNodeRef                            machine/capi-aws-control-plane-s7jln      ip-10-0-220-242.ap-northeast-2.compute.internal
# 55m         Normal   SuccessfulSetNodeRef                            machine/capi-aws-md-0-79d657658-b5grc     ip-10-0-123-138.ap-northeast-2.compute.internal
# 55m         Normal   SuccessfulSetNodeRef                            machine/capi-aws-md-0-79d657658-xq2x6     ip-10-0-127-50.ap-northeast-2.compute.internal
# 56m         Normal   SuccessfulCreate                                awsmachine/capi-aws-md-0-rfst2            Created new node instance with id "i-0f3e818bec335902d"
# 55m         Normal   SuccessfulDeleteEncryptedBootstrapDataSecrets   awsmachine/capi-aws-md-0-rfst2            AWS Secret entries containing userdata deleted
# 56m         Normal   SuccessfulCreate                                awsmachine/capi-aws-md-0-vqpdb            Created new node instance with id "i-0f40db68af2fffbe4"
# 55m         Normal   SuccessfulDeleteEncryptedBootstrapDataSecrets   awsmachine/capi-aws-md-0-vqpdb            AWS Secret entries containing userdata deleted

kubectl cluster-info dump > dump.json
less dump.json
```

### workload cluster 확인하기

- kubeconfig

```bash
clusterctl get kubeconfig capi-aws > capi-aws.kubeconfig
kubectl --kubeconfig=./capi-aws.kubeconfig get pods -A
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
kubectl --kubeconfig=./capi-aws.kubeconfig \
  apply -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml

kubectl --kubeconfig=./capi-aws.kubeconfig get nodes
# NAME                                              STATUS   ROLES    AGE    VERSION
# ip-10-0-123-138.ap-northeast-2.compute.internal   Ready    <none>   101m   v1.18.15
# ip-10-0-127-50.ap-northeast-2.compute.internal    Ready    <none>   101m   v1.18.15
# ip-10-0-220-242.ap-northeast-2.compute.internal   Ready    master   103m   v1.18.15
```

- API SERVER 값이 `true`로 변경됨

```bash
kubectl get kcp
# NAME                     INITIALIZED   API SERVER AVAILABLE   VERSION    REPLICAS   READY   UPDATED   UNAVAILABLE
# capi-aws-control-plane   true          true                   v1.18.15   1          1       1
```

## Clean up

```bash
kubectl delete cluster capi-aws
```

- 위 명령어를 실행하고 EC2 대시보드를 확인해보면 워커 노드->볼륨->컨트롤 플레인->ELB->보안그룹->EIB순으로 제거되었는데 실제로 비동기로 동작하는 건지는 찾아봐야겠습니다.
- 시간이 꽤 걸립니다.

```bash
clusterctl delete --infrastructure aws
# Deleting Provider="infrastructure-aws" Version="" TargetNamespace="capa-system"
```

```bash
kind delete cluster --name clusterapi
```
