#!/usr/bin/env bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
source $script_dir/.env

kubectl delete cluster $cluster_name
clusterctl delete --infrastructure aws --control-plane aws-eks --bootstrap aws-eks
kind delete cluster --name $cluster_name
