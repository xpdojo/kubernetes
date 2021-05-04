# Docker Distribution

- [Docker Distribution](#docker-distribution)
  - [참고](#참고)
  - [Private Registry 단독 실행](#private-registry-단독-실행)
  - [HTTP API V2](#http-api-v2)
    - [repositories](#repositories)
    - [repository tags](#repository-tags)
    - [manifests](#manifests)
    - [blobs](#blobs)

## 참고

- [Docker Hub](https://hub.docker.com/_/registry)
- [GitHub](https://github.com/distribution/distribution)
  - This repository's main product is the Open Source Registry implementation for storing and distributing container images using the OCI Distribution Specification.
- [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec)

## Private Registry 단독 실행

```bash
docker run \
  --detach \
  --publish 5000:5000 \
  --restart always \
  --name docker-dist \
  --env REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data/images \
  --env REGISTRY_STORAGE_DELETE_ENABLED=true \
  registry:2.7.1
```

## HTTP API V2

- [Docs](https://docs.docker.com/registry/spec/api/#detail)

### repositories

```bash
curl -XGET localhost:5000/v2/_catalog
# {"repositories":[]}
```

### repository tags

```bash
curl -XGET localhost:5000/v2/<name>/tags/list
```

### manifests

```bash
curl -XGET localhost:5000/v2/<name>/manifests/<reference>
curl -XPUT localhost:5000/v2/<name>/manifests/<reference>
curl -XDELETE localhost:5000/v2/<name>/manifests/<reference>
```

### blobs

```bash
curl -XGET localhost:5000/v2/<name>/blobs/<digest>
curl -XPUT localhost:5000/v2/<name>/blobs/<digest>
curl -XDELETE localhost:5000/v2/<name>/blobs/<digest>
```

```bash
curl -XGET localhost:5000/v2/<name>/blobs/uploads/<uuid>
curl -XPATCH localhost:5000/v2/<name>/blobs/uploads/<uuid>
curl -XPUT localhost:5000/v2/<name>/blobs/uploads/<uuid>
curl -XDELETE localhost:5000/v2/<name>/blobs/uploads/<uuid>
```
