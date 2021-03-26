#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
. $script_dir/.env

kubectl --namespace=default get secret $cluster_name-kubeconfig \
  -o jsonpath={.data.value} | base64 --decode \
  >$script_dir/$cluster_name.kubeconfig

kubectl --kubeconfig=$script_dir/$cluster_name.kubeconfig \
  apply -f $calico_manifests

kubectl --kubeconfig=$script_dir/$cluster_name.kubeconfig get nodes
