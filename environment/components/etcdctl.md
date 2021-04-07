# `etcdctl`

- [`etcdctl`](#etcdctl)
  - [`etcdctl` 설치](#etcdctl-설치)
  - [`etcdctl` 서브 커맨드](#etcdctl-서브-커맨드)
  - [key 불러오기](#key-불러오기)
  - [value 불러오기](#value-불러오기)
  - [스냅샷 백업](#스냅샷-백업)
  - [Clean up](#clean-up)

## `etcdctl` 설치

> [etcd-io/etcd](https://github.com/etcd-io/etcd/releases)

```bash
cat > etcdctl.sh << EOF
ETCD_VER=v3.4.14

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

/tmp/etcd-download-test/etcd --version
/tmp/etcd-download-test/etcdctl version
EOF
```

```bash
export ETCD_CTL="/tmp/etcd-download-test/etcdctl
--endpoints localhost:2379
--cacert /etc/kubernetes/ssl/etcd/ca.crt
--cert /etc/kubernetes/ssl/etcd/server.crt
--key /etc/kubernetes/ssl/etcd/server.key"
```

## `etcdctl` 서브 커맨드

```bash
ETCDCTL_API=3 etcdctl \
--endpoints localhost:2379 \
--cacert /etc/kubernetes/ssl/etcd/ca.crt \
--cert /etc/kubernetes/ssl/etcd/server.crt \
--key /etc/kubernetes/ssl/etcd/server.key \
--help

ETCDCTL_API=3 ${ETCD_CTL} --help

# API VERSION:
#   3.4
#
# COMMANDS: (하위명령 및 설명 생략)
#   alarm
#   auth
#   check
#   compaction
#   defrag
#   del
#   elect
#   endpoint
#   get
#   help
#   lease
#   lock
#   make-mirror
#   member
#   migrate
#   move-leader
#   put
#   role
#   snapshot
#   txn
#   user
#   version
#   watch

ETCDCTL_API=3 ${ETCD_CTL} help get
# NAME:
#   get - Gets the key or a range of keys
#
# USAGE:
#   etcdctl get [options] <key> [range_end] [flags]
#
# OPTIONS:
# ...
```

## key 불러오기

```bash
ETCDCTL_API=3 ${ETCD_CTL} \
get / \
--prefix=true \
--keys-only \
--write-out=simple \
--limit=3 \
--debug
# ETCDCTL_CACERT=/etc/kubernetes/ssl/etcd/ca.crt
# ETCDCTL_CERT=/etc/kubernetes/ssl/etcd/server.crt
# ETCDCTL_COMMAND_TIMEOUT=5s
# ETCDCTL_DEBUG=true
# ETCDCTL_DIAL_TIMEOUT=2s
# ETCDCTL_DISCOVERY_SRV=
# ETCDCTL_DISCOVERY_SRV_NAME=
# ETCDCTL_ENDPOINTS=[localhost:2379]
# ETCDCTL_HEX=false
# ETCDCTL_INSECURE_DISCOVERY=true
# ETCDCTL_INSECURE_SKIP_TLS_VERIFY=false
# ETCDCTL_INSECURE_TRANSPORT=true
# ETCDCTL_KEEPALIVE_TIME=2s
# ETCDCTL_KEEPALIVE_TIMEOUT=6s
# ETCDCTL_KEY=/etc/kubernetes/ssl/etcd/server.key
# ETCDCTL_PASSWORD=
# ETCDCTL_USER=
# ETCDCTL_WRITE_OUT=simple
# WARNING: 2021/02/03 11:00:22 Adjusting keepalive ping interval to minimum period of 10s
# WARNING: 2021/02/03 11:00:22 Adjusting keepalive ping interval to minimum period of 10s
# INFO: 2021/02/03 11:00:22 parsed scheme: "endpoint"
# INFO: 2021/02/03 11:00:22 ccResolverWrapper: sending new addresses to cc: [{localhost:2379  <nil> 0 <nil>}]
# /registry/apiextensions.k8s.io/customresourcedefinitions/bgpconfigurations.crd.projectcalico.org
# /registry/apiextensions.k8s.io/customresourcedefinitions/bgppeers.crd.projectcalico.org
# /registry/apiextensions.k8s.io/customresourcedefinitions/blockaffinities.crd.projectcalico.org

ETCDCTL_API=3 ${ETCD_CTL} \
get / \
--prefix=true \
--keys-only \
--write-out=json

# {"header":{"cluster_id":1095986356369666358,"member_id":5053623965055909283,"revision":4115662,"raft_term":2},
# "kvs":[
# {"key":"L3JlZ2lzdHJ5L2FwaWV4dGVuc2lvbnMuazhzLmlvL2N1c3RvbXJlc291cmNlZGVmaW5pdGlvbnMvYmdwY29uZmlndXJhdGlvbnMuY3JkLnByb2plY3RjYWxpY28ub3Jn","create_revision":4110876,"mod_revision":4110881,"version":3},
# {"key":"L3JlZ2lzdHJ5L2FwaWV4dGVuc2lvbnMuazhzLmlvL2N1c3RvbXJlc291cmNlZGVmaW5pdGlvbnMvYmdwcGVlcnMuY3JkLnByb2plY3RjYWxpY28ub3Jn","create_revision":4110879,"mod_revision":4110883,"version":3},
# {"key":"L3JlZ2lzdHJ5L2FwaWV4dGVuc2lvbnMuazhzLmlvL2N1c3RvbXJlc291cmNlZGVmaW5pdGlvbnMvYmxvY2thZmZpbml0aWVzLmNyZC5wcm9qZWN0Y2FsaWNvLm9yZw==","create_revision":4110882,"mod_revision":4110885,"version":3},
# ...

base64 --decode <<< L3JlZ2lzdHJ5L2FwaWV4dGVuc2lvbnMuazhzLmlvL2N1c3RvbXJlc291cmNlZGVmaW5pdGlvbnMvYmdwY29uZmlndXJhdGlvbnMuY3JkLnByb2plY3RjYWxpY28ub3Jn
# /registry/apiextensions.k8s.io/customresourcedefinitions/bgpconfigurations.crd.projectcalico.org
```

## value 불러오기

```bash
ETCDCTL_API=3 ${ETCD_CTL} \
get /registry/apiextensions.k8s.io/customresourcedefinitions/bgpconfigurations.crd.projectcalico.org \
--write-out=fields
# "ClusterID" : 1095986356369666358
# "MemberID" : 5053623965055909283
# "Revision" : 4117455
# "RaftTerm" : 2
# "Key" : "/registry/apiextensions.k8s.io/customresourcedefinitions/bgpconfigurations.crd.projectcalico.org"
# "CreateRevision" : 4110876
# "ModRevision" : 4110881
# "Version" : 3
# "Value" : "{\"kind\":\"CustomResourceDefinition\",\"apiVersion\":\"apiextensions.k8s.io/v1beta1\",\"metadata\":{
# ...

ETCDCTL_API=3 ${ETCD_CTL} \
get /registry/pods/kube-system/kube-apiserver-test \
--write-out=fields
# "ClusterID" : 1095986356369666358
# "MemberID" : 5053623965055909283
# "Revision" : 4118306
# "RaftTerm" : 2
# "Key" : "/registry/pods/kube-system/kube-apiserver-test"
# "CreateRevision" : 315
# "ModRevision" : 318
# "Version" : 2
# "Value" : "k8s\x00\n\t\n\x02v1\x12\x03Pod\x12\xf0)\n\x9e\x17\n\x13kube-apiserver-test
# ...

ETCDCTL_API=3 ${ETCD_CTL} \
get /registry/pods/kube-system/calico-node-6zrnd
# /registry/pods/kube-system/calico-node-6zrnd
# k8s
# ...

ETCDCTL_API=3 ${ETCD_CTL} \
del /registry/pods/kube-system/calico-node-6zrnd
# 1

ETCDCTL_API=3 ${ETCD_CTL} \
get /registry/pods/kube-system/calico-node-6zrnd
# 아무것도 출력되지 않는다.
kubectl get pods -n kube-system
# NAMESPACE     NAME                                       READY   STATUS     RESTARTS   AGE
# kube-system   calico-kube-controllers-7dbc97f587-wszzt   1/1     Running    0          135m
# kube-system   calico-node-whp5p                          0/1     Init:1/3   0          7s
```

- 컨트롤러에 의해 조정됨: calico-node-6zrnd -> calico-node-whp5p

## 스냅샷 백업

> [Operating etcd clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

```bash
# Built-in snapshot
ETCDCTL_API=3 ${ETCD_CTL} snapshot save snapshotdb
ETCDCTL_API=3 ${ETCD_CTL} --write-out=table snapshot status snapshotdb
# +----------+----------+------------+------------+
# |   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
# +----------+----------+------------+------------+
# | d9260b1c |  4114974 |       1615 |     3.2 MB |
# +----------+----------+------------+------------+
```

## Clean up

```bash
rm -rf /tmp/etcd-download-test
```
