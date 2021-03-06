#!/usr/bin/env bash

set -Eeuo pipefail
# trap cleanup SIGINT SIGTERM ERR EXIT

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
check_command kind kubectl clusterctl clusterawsadm # aws
msg "✅ Complete\n---"

msg "${YELLOW}Create Kind Cluster...${NOFORMAT}"
if kind get clusters | grep -q $cluster_name; then
  msg "${CYAN}Cluster \"$cluster_name\" already exists${NOFORMAT}"
else
  kind create cluster --name $cluster_name --config=$kind_config_path
  msg "✅ Complete\n---"
fi

msg "${YELLOW}Setting Required Configurations...${NOFORMAT}"
# https://github.com/kubernetes-sigs/cluster-api-provider-aws/blob/master/templates/cluster-template-eks.yaml
export EXP_EKS=false
export EXP_EKS_IAM=false
export EXP_EKS_ADD_ROLES=false

export AWS_SSH_KEY_NAME=$ssh_key_name
export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_REGION=$aws_region
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)

export KUBERNETES_VERSION=$kubernetes_version
export CONTROL_PLANE_MACHINE_COUNT=$control_plane_machine_count
export WORKER_MACHINE_COUNT=$worker_machine_count
export AWS_CONTROL_PLANE_MACHINE_TYPE=$aws_control_plane_machine_type
export AWS_NODE_MACHINE_TYPE=$aws_node_machine_type
msg "✅ Complete\n---"

msg "${YELLOW}Initialize Management Cluster...${NOFORMAT}"
if kubectl get providers -n capa-system | grep -q InfrastructureProvider; then
  msg "${CYAN}InfrastructureProvider already exists${NOFORMAT}"
else
  clusterctl init --infrastructure aws -v 4
  msg "✅ Complete\n---"
fi

msg "${YELLOW}Providers List...${NOFORMAT}"
kubectl get providers -A
kubectl get po -A
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

clusterctl config cluster $cluster_name >$script_dir/$cluster_name.yaml
kubectl apply -f $script_dir/$cluster_name.yaml
msg "✅ Complete\n---"

clusterctl describe cluster --show-conditions=all --disable-grouping --disable-no-echo $cluster_name
