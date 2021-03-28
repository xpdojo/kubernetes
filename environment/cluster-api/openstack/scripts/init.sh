#!/usr/bin/env bash

set -Eeuo pipefail

# abspath() {
#   { [ "$(printf %.1s "${1}")" = "/" ] && echo "${1}"; } || echo "${OLD_DIR}/${1}"
# }
# $(abspath openstack/scripts)

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source $script_dir/.env

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}
setup_colors

msg() {
  echo >&2 -e "${1-}"
}

check_command() {
  for i in "$@"; do
    cmd=$i
    if ! command -v $cmd &>/dev/null; then
      msg "${RED}[Not Installed] $cmd"
      exit 0
    else
      msg "${GREEN}[Installed] ${NOFORMAT}$cmd"
    fi
  done
}

msg "${YELLOW}Check Commands...${NOFORMAT}"
check_command kind kubectl clusterctl
msg "✅ Complete\n---"

msg "${YELLOW}Create Kind Cluster...${NOFORMAT}"
if kind get clusters | grep -q $cluster_name; then
  msg "${CYAN}Cluster \"$cluster_name\" already exists${NOFORMAT}"
else
  kind create cluster --name $cluster_name --config=$kind_config_path
  msg "✅ Complete\n---"
fi

msg "${YELLOW}Setting Required Configurations...${NOFORMAT}"

source $script_dir/env.rc $script_dir/etc/openstack/clouds.yaml devstack

export CLUSTER_NAME=$cluster_name
export OPENSTACK_CONTROL_PLANE_MACHINE_FLAVOR=$openstack_control_plane_machine_flavor
export OPENSTACK_NODE_MACHINE_FLAVOR=$openstack_node_machine_flavor
export CONTROL_PLANE_MACHINE_COUNT=$control_plane_machine_count
export WORKER_MACHINE_COUNT=$worker_machine_count
export KUBERNETES_VERSION=$kubernetes_version
export NAMESPACE=$cluster_name
export OPENSTACK_DNS_NAMESERVERS=$dns_nameservers
export OPENSTACK_SSH_KEY_NAME=$ssh_key_name
export OPENSTACK_CLUSTER_TEMPLATE=$cluster_template
export OPENSTACK_FAILURE_DOMAIN=$failure_domain
export OPENSTACK_IMAGE_NAME=$image_name
msg "✅ Complete\n---"

msg "${YELLOW}Initialize Management Cluster...${NOFORMAT}"
if kubectl get providers -n capo-system | grep -q InfrastructureProvider; then
  msg "${CYAN}InfrastructureProvider already exists${NOFORMAT}"
else
  clusterctl init --infrastructure=openstack -v 4
  msg "✅ Complete\n---"
fi

msg "${YELLOW}Providers List...${NOFORMAT}"
kubectl get providers --all-namespaces
kubectl get po --all-namespaces
msg "✅ Complete\n---"

msg "${YELLOW}Create Workload Cluster...${NOFORMAT}"

function checkWebhookStatus() {
  local status=$(
    kubectl get pods \
      --selector control-plane=controller-manager \
      --all-namespaces \
      --output jsonpath='{.items[*].status.containerStatuses[*].ready}'
  )

  for ready in $status; do
    if [[ $ready == "false" ]]; then
      ret=false
      msg "ready: $ret"
      return
    fi
  done
  ret=true
  msg "ready: $ret"
}

while true; do
  checkWebhookStatus
  if $ret; then
    break
  else
    msg "${CYAN}Waiting for Controller Managers to be ready...${NOFORMAT}"
    sleep 5
  fi
done

clusterctl config cluster $cluster_name > $script_dir/$cluster_name.yaml
kubectl apply -f $script_dir/$cluster_name.yaml
msg "✅ Complete\n---"

clusterctl describe cluster --show-conditions=all --disable-grouping --disable-no-echo $cluster_name

# TODO: CNI
