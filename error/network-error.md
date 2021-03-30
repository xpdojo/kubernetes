# 에러 모음

- [에러 모음](#에러-모음)
  - [calico/node is not ready: BIRD is not ready: BGP not established](#caliconode-is-not-ready-bird-is-not-ready-bgp-not-established)
    - [Solution](#solution)

## calico/node is not ready: BIRD is not ready: BGP not established

- [Docs](https://docs.projectcalico.org/maintenance/troubleshoot/troubleshooting)
- [projectcalico/calico#2561](https://github.com/projectcalico/calico/issues/2561)

```bash
journalctl -fxu kubelet
#  3월 29 16:47:49 mec01 kubelet[2927]: I0329 16:47:49.368947    2927 prober.go:124] Readiness probe for "calico-node-lfsbw_kube-system(d6230a41-4137-43cd-9ad6-1f8b95459693):calico-node" failed (failure): 2021-03-29 07:47:49.350 [INFO][9740] confd/health.go 180: Number of node(s) with BGP peering established = 0
#  3월 29 16:47:49 mec01 kubelet[2927]: calico/node is not ready: BIRD is not ready: BGP not established with 192.168.7.192,192.168.7.193,192.168.7.194
```

```bash
kubectl logs -f calico-node-lfsbw -n kube-system
# 2021-03-29 07:54:16.311 [INFO][48] felix/int_dataplane.go 848: Linux interface addrs changed. addrs=set.mapSet{"127.0.0.0":set.empty{}, "127.0.0.1":set.empty{}, "::1":set.empty{}, "fe80::84a3:8169:c147:fbe5":set.empty{}, "fe80::ecee:eeff:feee:eeee":set.empty{}} ifaceName="lo"
# 2021-03-29 07:54:16.312 [INFO][48] felix/int_dataplane.go 1205: Received interface addresses update msg=&intdataplane.ifaceAddrsUpdate{Name:"lo", Addrs:set.mapSet{"127.0.0.0":set.empty{}, "127.0.0.1":set.empty{}, "::1":set.empty{}, "fe80::84a3:8169:c147:fbe5":set.empty{}, "fe80::ecee:eeff:feee:eeee":set.empty{}}}
# 2021-03-29 07:54:16.312 [INFO][48] felix/hostip_mgr.go 84: Interface addrs changed. update=&intdataplane.ifaceAddrsUpdate{Name:"lo", Addrs:set.mapSet{"127.0.0.0":set.empty{}, "127.0.0.1":set.empty{}, "::1":set.empty{}, "fe80::84a3:8169:c147:fbe5":set.empty{}, "fe80::ecee:eeff:feee:eeee":set.empty{}}}
# 2021-03-29 07:54:16.312 [INFO][48] felix/ipsets.go 119: Queueing IP set for creation family="inet" setID="this-host" setType="hash:ip"
# 2021-03-29 07:54:16.312 [INFO][48] felix/int_dataplane.go 1300: Applying dataplane updates
# 2021-03-29 07:54:16.312 [INFO][48] felix/ipsets.go 749: Doing full IP set rewrite family="inet" numMembersInPendingReplace=6 setID="this-host"
# 2021-03-29 07:54:16.319 [INFO][48] felix/int_dataplane.go 1314: Finished applying updates to dataplane. msecToApply=7.392088
# 2021-03-29 07:54:20.207 [INFO][49] monitor-addresses/startup.go 597: Using IPv4 address from environment: IP=192.168.7.191
# 2021-03-29 07:54:20.208 [INFO][49] monitor-addresses/startup.go 630: IPv4 address 192.168.7.191 discovered on interface ens192
# 2021-03-29 07:51:27.615 [INFO][48] felix/int_dataplane.go 1300: Applying dataplane updates
# 2021-03-29 07:51:27.615 [INFO][48] felix/route_table.go 398: Queueing a resync of routing table. ifaceRegex="^cali.*" ipVersion=0x4
# 2021-03-29 07:51:27.615 [INFO][48] felix/wireguard.go 534: Queueing a resync of wireguard configuration
# 2021-03-29 07:51:27.615 [INFO][48] felix/route_table.go 398: Queueing a resync of routing table. ifaceRegex="^wireguard.cali$" ipVersion=0x4
# 2021-03-29 07:51:27.615 [INFO][48] felix/route_rule.go 172: Queueing a resync of routing rules. ipVersion=4
# 2021-03-29 07:51:27.620 [INFO][48] felix/int_dataplane.go 1314: Finished applying updates to dataplane. msecToApply=5.042048
# 2021-03-29 07:51:36.244 [INFO][48] felix/int_dataplane.go 1300: Applying dataplane updates
# 2021-03-29 07:51:36.244 [INFO][48] felix/ipsets.go 223: Asked to resync with the dataplane on next update. family="inet"
# 2021-03-29 07:51:36.244 [INFO][48] felix/ipsets.go 306: Resyncing ipsets with dataplane. family="inet"
# 2021-03-29 07:51:36.247 [INFO][48] felix/ipsets.go 356: Finished resync family="inet" numInconsistenciesFound=0 resyncDuration=2.967277ms
# 2021-03-29 07:51:36.247 [INFO][48] felix/int_dataplane.go 1314: Finished applying updates to dataplane. msecToApply=3.2024850000000002
```

```bash
systemctl status kubelet
#  3월 30 09:41:16 mec02 kubelet[972]: W0330 09:41:16.663201     972 cni.go:179] Error loading CNI config file /etc/cni/net.d/00-multus.conf: error parsing configuration: invalid character '\n' in string literal
```

```bash
kubectl get events --sort-by='.metadata.creationTimestamp' -A | tail -10
# kube-system            95s         Warning   Unhealthy                         pod/calico-node-px2m7                             (combined from similar events): Readiness probe failed: 2021-03-30 01:27:08.608 [INFO][3745] confd/health.go 180: Number of node(s) with BGP peering established = 0
# calico/node is not ready: BIRD is not ready: BGP not established with 10.10.10.1
# kube-system            100s        Warning   Unhealthy                         pod/calico-node-kxtvl                             (combined from similar events): Readiness probe failed: 2021-03-30 01:27:03.899 [INFO][3785] confd/health.go 180: Number of node(s) with BGP peering established = 0
# calico/node is not ready: BIRD is not ready: BGP not established with 192.168.7.222
```

```bash
# on 192.168.7.221
calicoctl node status
# Calico process is running.
#
# IPv4 BGP status
# +---------------+-------------------+-------+----------+---------+
# | PEER ADDRESS  |     PEER TYPE     | STATE |  SINCE   |  INFO   |
# +---------------+-------------------+-------+----------+---------+
# | 192.168.7.222 | node-to-node mesh | start | 01:51:38 | Passive |
# +---------------+-------------------+-------+----------+---------+
```

### Solution

- `eth0`나 `eno0` 같은 인터페이스만 감지할 수 있는지 모르겠지만...호스트 머신의 이더넷 인터페이스를 명시해주면 된다.
- 만약 리눅스 배포판이 다르고 인터페이스명이 다르다면?
- [Docs](https://docs.projectcalico.org/networking/node) - Calico

```diff
  # https://docs.projectcalico.org/manifests/calico.yaml
  # Cluster type to identify the deployment type
  - name: CLUSTER_TYPE
    value: "k8s,bgp"
+ - name: IP_AUTODETECTION_METHOD # or IP6_AUTODETECTION_METHOD
+   value: "cidr=192.168.0.0/16" # "interface=eno.*,eth0", "can-reach=8.8.8.8"
  # Auto-detect the BGP IP address.
  - name: IP
    value: "autodetect"
  # Enable IPIP
  - name: CALICO_IPV4POOL_IPIP
    value: "Always"
  # Enable or Disable VXLAN on the default IP pool.
  - name: CALICO_IPV4POOL_VXLAN
    value: "Never"
```

- [소스 코드](https://github.com/projectcalico/node/blob/v3.18.1/pkg/startup/autodetection/filtered.go#L25-L52)

```go
// FilteredEnumeration performs basic IP and IPNetwork discovery by enumerating
// all interfaces and filtering in/out based on the supplied filter regex.
//
// The incl and excl slice of regex strings may be nil.
func FilteredEnumeration(incl, excl []string, cidrs []net.IPNet, version int) (*Interface, *net.IPNet, error) {
  interfaces, err := GetInterfaces(incl, excl, version)
  if err != nil {
    return nil, nil, err
  }
  if len(interfaces) == 0 {
    return nil, nil, errors.New("no valid host interfaces found")
  }

  // Find the first interface with a valid matching IP address and network.
  // We initialise the IP with the first valid IP that we find just in
  // case we don't find an IP *and* network.
  for _, i := range interfaces {
    log.WithField("Name", i.Name).Debug("Check interface")
    for _, c := range i.Cidrs {
      log.WithField("CIDR", c).Debug("Check address")
      if c.IP.IsGlobalUnicast() && matchCIDRs(c.IP, cidrs) {
        return &i, &c, nil
      }
    }
  }

  return nil, nil, fmt.Errorf("no valid IPv%d addresses found on the host interfaces", version)
}
```

```bash
# on 192.168.7.221
calicoctl node status
# Calico process is running.
#
# IPv4 BGP status
# +---------------+-------------------+-------+----------+-------------+
# | PEER ADDRESS  |     PEER TYPE     | STATE |  SINCE   |    INFO     |
# +---------------+-------------------+-------+----------+-------------+
# | 192.168.7.222 | node-to-node mesh | up    | 02:22:29 | Established |
# +---------------+-------------------+-------+----------+-------------+
```
