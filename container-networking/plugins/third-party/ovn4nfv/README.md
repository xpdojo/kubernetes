# OVN4NFV

## 용어

| term  | description                     |
| ----- | ------------------------------- |
| `OVS` | Open Virtual Switch (vSwitch)   |
| `OVN` | Open Virtual Network            |
| `NFN` | Network Function Network        |
| `NFV` | Network Function Virtualization |

## 아키텍처

![ovn4nfv-k8s-arch-block.png](../../../../images/networking/ovn4nfv-k8s-arch-block.png)

- OVN 컨트롤 플레인
  - OVN 구성을 저장하고 관리
- OVN 컨트롤러
  - 각 노드에서 OVN 설치 및 구성
- NFN 오퍼레이터
  - Exposes virtual, provider, chaining CRDs to external world
  - Programs OVN to create L2 switches
  - Watches for PODs being coming up
  - Assigns IP addresses for every network of the deployment
  - Looks for replicas and auto create routes for chaining to work
  - Create LBs for distributing the load across CNF replicas
- NFN 에이전트
  - Performs CNI operations.
  - Configures VLAN and Routes in Linux kernel (in case of routes, it could do it in both root and network namespaces)
  - Communicates with OVSDB to inform of provider interfaces. (creates ovs bridge and creates external-ids:ovn-bridge-mappings)
- ~~멀터스는 왜 없지...?~~

## 참고

- [akraino-edge-stack/icn-ovn4nfv-k8s-network-controller](https://github.com/akraino-edge-stack/icn-ovn4nfv-k8s-network-controller)
  - [Demo on Vagrant](demo-vagrant.md)
  - [기존 gerrit](https://gerrit.opnfv.org/gerrit/ovn4nfv-k8s-plugin.git)
  - [기존 GitHub](https://github.com/opnfv/ovn4nfv-k8s-plugin)
- 사용되는 컨테이너 이미지
  - [integratedcloudnative/ovn-images](https://hub.docker.com/r/integratedcloudnative/ovn-images): [Open vSwitch](https://github.com/akraino-icn/ovs)
    - ovn-controller
    - ovn-control-plane
  - [integratedcloudnative/ovn4nfv-k8s-plugin](https://hub.docker.com/r/integratedcloudnative/ovn4nfv-k8s-plugin)
    - ovn4nfv-cni
    - nfn-agent
  - [rtsood/nfn-operator](https://hub.docker.com/r/rtsood/nfn-operator)
    - nfn-operator
- [ovn-org/ovn-kubernetes](https://github.com/ovn-org/ovn-kubernetes)
- [k8snetworkplumbingwg/multus-cni](https://github.com/k8snetworkplumbingwg/multus-cni)
  - multus는 [멀터스](https://www.youtube.com/watch?v=FwhVJ_e8cW0&t=764s)라고 발음하는 것 같습니다.
