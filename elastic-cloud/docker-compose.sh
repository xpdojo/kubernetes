#!/usr/bin/env bash

sudo -i

sysctl -w vm.max_map_count=262144

# if bind mounts
# mkdir data01 data02 data03
# chmod g+w data0*

docker-compose -f ./docker-compose-bind.yaml up -d

docker-compose down
