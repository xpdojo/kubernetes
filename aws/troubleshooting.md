# AWS 테스트 환경 트러블슈팅

- [공식 문서](https://cluster-api-aws.sigs.k8s.io/topics/troubleshooting.html)
- [Amazon EKS에 대한 kubelet 또는 CNI 플러그인 문제는 어떻게 해결합니까?](https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-cni-plugin-troubleshooting/)
- [EKS FAQ](https://aws.amazon.com/ko/eks/faqs/)
- [EKS Best Practice](https://aws.github.io/aws-eks-best-practices/reliability/docs/controlplane/)

## 환경 변수

```bash
# Error: failed to get provider components for the "aws-eks" provider: failed to perform variable substitution: value for variables [AWS_B64ENCODED_CREDENTIALS] is not set. Please set the value using os environment variables or the clusterctl config file
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)
```

## `NatGatewaysReconciliationFailed`

- 클러스터 생성 중 SIGINT(`^C`)로 중단하고 다시 클러스터 생성 명령어를 실행하면 아래와 같은 오류가 발생합니다.
- 이벤트 로그를 보고 AWS 콘솔에서 NAT Gateway와 Elastic IP를 제거해주면 됩니다.

```bash
clusterctl describe cluster capi-aws
# NAME                                                           READY  SEVERITY  REASON                           SINCE  MESSAGE
# /capi-aws                                                      False  Error     NatGatewaysReconciliationFailed  21m    3 of 7 completed
# ├─ClusterInfrastructure - AWSCluster/capi-aws                False  Error     NatGatewaysReconciliationFailed  21m    3 of 7 completed
# ├─ControlPlane - KubeadmControlPlane/capi-aws-control-plane
# └─Workers
#   └─MachineDeployment/capi-aws-md-0
#     └─2 Machines...                                          False  Info      WaitingForClusterInfrastructure  22m    See capi-aws-md-0-79d657658-84cwb, capi-aws-md-0-79d657658-zmbw5

kubectl get ev
# 4m20s       Warning   FailedAllocateEIP                  awscluster/capi-aws                   (combined from similar events): Failed to allocate Elastic IP for "apiserver": AddressLimitExceeded: The maximum number of addresses has been reached.
#             status code: 400, request id: 19ebef8a-3e05-4be6-ae49-5aa39dc6af9f
# 30m         Normal    NodeHasSufficientMemory            node/clusterapi-control-plane         Node clusterapi-control-plane status is now: NodeHasSufficientMemory
# 30m         Normal    NodeHasNoDiskPressure              node/clusterapi-control-plane         Node clusterapi-control-plane status is now: NodeHasNoDiskPressure
# 30m         Normal    NodeHasSufficientPID               node/clusterapi-control-plane         Node clusterapi-control-plane status is now: NodeHasSufficientPID
```

## Controller Manager

- EKS 클러스터 생성 시 EC2보다 bootstrap이 느립니다.

```bash
kubectl apply -f $script_dir/eks.yaml
# Create Workload Cluster...
# /Users/changsuim/testlocal/cluster-api/aws/scripts
# awsmanagedcluster.infrastructure.cluster.x-k8s.io/capa-test created
# eksconfigtemplate.bootstrap.cluster.x-k8s.io/capa-test-md-0 created
# Error from server (InternalError): error when creating "/Users/changsuim/testlocal/cluster-api/aws/scripts/eks.yaml": Internal error occurred: failed calling webhook "default.cluster.cluster.x-k8s.io": Post https://capi-webhook-service.capi-webhook-system.svc:443/mutate-cluster-x-k8s-io-v1alpha3-cluster?timeout=30s: dial tcp 10.96.54.22:443: connect: connection refused
# Error from server (InternalError): error when creating "/Users/changsuim/testlocal/cluster-api/aws/scripts/eks.yaml": Internal error occurred: failed calling webhook "default.awsmanagedcontrolplanes.controlplane.cluster.x-k8s.io": Post https://capa-eks-control-plane-webhook-service.capi-webhook-system.svc:443/mutate-controlplane-cluster-x-k8s-io-v1alpha3-awsmanagedcontrolplane?timeout=30s: dial tcp 10.96.59.44:443: connect: connection refused
# Error from server (InternalError): error when creating "/Users/changsuim/testlocal/cluster-api/aws/scripts/eks.yaml": Internal error occurred: failed calling webhook "default.machinedeployment.cluster.x-k8s.io": Post https://capi-webhook-service.capi-webhook-system.svc:443/mutate-cluster-x-k8s-io-v1alpha3-machinedeployment?timeout=30s: dial tcp 10.96.54.22:443: connect: connection refused
# Error from server (InternalError): error when creating "/Users/changsuim/testlocal/cluster-api/aws/scripts/eks.yaml": Internal error occurred: failed calling webhook "validation.awsmachinetemplate.infrastructure.x-k8s.io": Post https://capa-webhook-service.capi-webhook-system.svc:443/validate-infrastructure-cluster-x-k8s-io-v1alpha3-awsmachinetemplate?timeout=30s: dial tcp 10.96.244.134:443: connect: connection refused
# make: *** [eks-init] Error 1
```

- 모든 Controller Manager 상태가 준비되길 기다렸다가 다시 생성해주면 됩니다.

```bash
kubectl get pods \
  --selector control-plane=controller-manager \
  --all-namespaces
# NAMESPACE                           NAME                                                             READY   STATUS    RESTARTS   AGE
# capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-859d5f5b95-f4l2g       2/2     Running   0          17m
# capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-65b965795b-lm25q   2/2     Running   0          17m
# capi-system                         capi-controller-manager-6f58d487c6-9qqc7                         2/2     Running   0          17m
# capi-webhook-system                 capi-controller-manager-8594f758d7-tz2m4                         2/2     Running   0          17m
# capi-webhook-system                 capi-kubeadm-bootstrap-controller-manager-764fbdf7db-lw66s       2/2     Running   0          17m
# capi-webhook-system                 capi-kubeadm-control-plane-controller-manager-8f4744fbc-h8lfs    2/2     Running   0          17m

kubectl apply -f $script_dir/eks.yaml
# cluster.cluster.x-k8s.io/capa-test unchanged
# awsmanagedcluster.infrastructure.cluster.x-k8s.io/capa-test unchanged
# awsmanagedcontrolplane.controlplane.cluster.x-k8s.io/capa-test-control-plane configured
# machinedeployment.cluster.x-k8s.io/capa-test-md-0 unchanged
# awsmachinetemplate.infrastructure.cluster.x-k8s.io/capa-test-md-0 created
# eksconfigtemplate.bootstrap.cluster.x-k8s.io/capa-test-md-0 unchanged

kubectl api-resources | grep cluster
kubectl describe machinedeployments capa-test-md-0
# Events:
# Type     Reason            Age                 From                          Message
# ----     ------            ----                ----                          -------
# Warning  ReconcileError    30m (x18 over 41m)  machinedeployment-controller  failed to retrieve AWSMachineTemplate external object "default"/"capa-test-md-0": awsmachinetemplates.infrastructure.cluster.x-k8s.io "capa-test-md-0" not found
# Normal   SuccessfulCreate  23m                 machinedeployment-controller  Created MachineSet "capa-test-md-0-d88b79d65"
```

## Machine 생성 오류

- credential 환경 변수 등록 후 클러스터 재생성

```bash
kubectl get events
# 31s         Warning   FailedCreate                                   awsmachine/capa-test-md-0-wt5kx                  (combined from similar events): Failed to create instance: failed to run instance: Blocked: This account is currently blocked and not recognized as a valid account. Please contact aws-verification@amazon.com if you have questions.
#             status code: 400, request id: a9c64ae3-d3a8-4b06-989c-a687f53af383
```

## 클러스터 생성 시 오류

- 해결 못함
- https://github.com/kubernetes/kubernetes/blob/master/cmd/kube-proxy/app/server.go#L692
- https://github.com/moby/moby/issues/24000

```bash
kubeclt get events
# 36m         Warning   readOnlySysFS                                  node/clusterapi-worker                          CRI error: /sys is read-only: cannot modify conntrack limits, problems may arise later (If running Docker, see docker issue #24000)
```
