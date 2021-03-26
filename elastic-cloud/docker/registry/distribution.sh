#!/usr/bin/env bash

# https://hub.docker.com/_/registry
docker run \
--detach \
--publish 5000:5000 \
--restart=always \
--name registry \
--env REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/root/images \
registry:2.7.1

--env REGISTRY_STORAGE_DELETE_ENABLED=true \

# https://docs.docker.com/registry/spec/api/#detail
curl -XGET localhost:5000/v2/_catalog
# {"repositories":[]}

# curl -XGET localhost:5000/v2/<name>/tags/list

# curl -XGET localhost:5000/v2/<name>/manifests/<reference>
# curl -XPUT localhost:5000/v2/<name>/manifests/<reference>
# curl -XDELETE localhost:5000/v2/<name>/manifests/<reference>

# curl -XGET localhost:5000/v2/<name>/blobs/<digest>
# curl -XPUT localhost:5000/v2/<name>/blobs/<digest>
# curl -XDELETE localhost:5000/v2/<name>/blobs/<digest>

# curl -XGET localhost:5000/v2/<name>/blobs/uploads/<uuid>
# curl -XPATCH localhost:5000/v2/<name>/blobs/uploads/<uuid>
# curl -XPUT localhost:5000/v2/<name>/blobs/uploads/<uuid>
# curl -XDELETE localhost:5000/v2/<name>/blobs/uploads/<uuid>
