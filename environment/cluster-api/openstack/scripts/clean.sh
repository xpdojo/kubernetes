#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source $script_dir/.env

kubectl delete cluster=$cluster_name
clusterctl delete --infrastructure=openstack
kind delete cluster --name=$cluster_name
