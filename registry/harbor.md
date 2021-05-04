# Harbor

- [Harbor](#harbor)
  - [참고](#참고)
  - [설치](#설치)
    - [Prerequisite](#prerequisite)
    - [Installation](#installation)
  - [LDAP 설정](#ldap-설정)
  - [`Projects`](#projects)
    - [Docker Image](#docker-image)
    - [Helm Chart](#helm-chart)
  - [Clean up](#clean-up)
  - [Restart](#restart)

## 참고

- [Harbor 홈페이지](https://goharbor.io/)
- [Private Docker Registry를 구축하기 위한 오픈소스 Harbor 도입기](https://engineering.linecorp.com/ko/blog/harbor-for-private-docker-registry/) - Line

## [설치](https://goharbor.io/docs/2.2.0/install-config/)

### [Prerequisite](https://goharbor.io/docs/latest/install-config/installation-prereqs/)

### [Installation](https://goharbor.io/docs/latest/install-config/download-installer/)

```bash
# online
curl -LO https://github.com/goharbor/harbor/releases/download/v2.2.1/harbor-online-installer-v2.2.1.tgz
curl -LO https://github.com/goharbor/harbor/releases/download/v2.2.1/harbor-online-installer-v2.2.1.tgz.asc
```

```bash
# on Ubuntu
gpg --keyserver hkps://keyserver.ubuntu.com --receive-keys 644FF454C0B4115C

# on CentOS 7
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 644FF454C0B4115C
# gpg: requesting key C0B4115C from hkps server keyserver.ubuntu.com
# gpg: /root/.gnupg/trustdb.gpg: trustdb created
# gpg: key C0B4115C: public key "Harbor-sign (The key for signing Harbor build) <jiangd@vmware.com>" imported
# gpg: Total number processed: 1
# gpg:               imported: 1  (RSA: 1)
```

```bash
ls
# harbor-online-installer-v2.2.1.tgz  harbor-online-installer-v2.2.1.tgz.asc

# .tgz 파일과 .tgz.asc 파일이 같은 경로에 있어야 합니다.
gpg -v --keyserver hkps://keyserver.ubuntu.com --verify harbor-online-installer-v2.2.1.tgz.asc
# gpg: assuming signed data in `harbor-online-installer-v2.2.1.tgz'
# gpg: Signature made 2021년 03월 26일 (금)  using RSA key ID C0B4115C
# gpg: using PGP trust model
# gpg: Good signature from "Harbor-sign (The key for signing Harbor build) <jiangd@vmware.com>"
# gpg: WARNING: This key is not certified with a trusted signature!
# gpg:          There is no indication that the signature belongs to the owner.
# Primary key fingerprint: 7722 D168 DAEC 4578 06C9  6FF9 644F F454 C0B4 115C
# gpg: binary signature, digest algorithm SHA512

tar zxvf harbor-online-installer-v2.2.1.tgz
cd harbor
```

```bash
cp harbor.yml.tmpl harbor.yml
vi harbor.yml
```

```bash
export HARBOR_HOST=192.168.213.10
```

```yaml
# 호스트 도메인명 혹은 IP 지정
hostname: 192.168.213.10

# https 주석 처리
# https:
#  port: 443

# admin 패스워드 지정
harbor_admin_password: Harbor12345

data_volume: /data/harbor
```

```bash
sudo ./install.sh
```

```bash
sudo docker-compose ps
#       Name                     Command                  State                 Ports
# ---------------------------------------------------------------------------------------------
# harbor-core         /harbor/entrypoint.sh            Up (healthy)
# harbor-db           /docker-entrypoint.sh            Up (healthy)
# harbor-jobservice   /harbor/entrypoint.sh            Up (healthy)
# harbor-log          /bin/sh -c /usr/local/bin/ ...   Up (healthy)   127.0.0.1:1514->10514/tcp
# harbor-portal       nginx -g daemon off;             Up (healthy)
# nginx               nginx -g daemon off;             Up (healthy)   0.0.0.0:80->8080/tcp
# redis               redis-server /etc/redis.conf     Up (healthy)
# registry            /home/harbor/entrypoint.sh       Up (healthy)
# registryctl         /home/harbor/start.sh            Up (healthy)

sudo docker ps --size
# CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS                    PORTS                       NAMES               SIZE
# 76fb2a94b29e        goharbor/nginx-photon:v2.2.1         "nginx -g 'daemon of…"   14 minutes ago      Up 14 minutes (healthy)   0.0.0.0:80->8080/tcp        nginx               2B (virtual 40.3MB)
# 5af0ac8829b2        goharbor/harbor-jobservice:v2.2.1    "/harbor/entrypoint.…"   14 minutes ago      Up 14 minutes (healthy)                               harbor-jobservice   1.64MB (virtual 165MB)
# 97186c1733df        goharbor/harbor-core:v2.2.1          "/harbor/entrypoint.…"   14 minutes ago      Up 14 minutes (healthy)                               harbor-core         1.64MB (virtual 149MB)
# 7daefbdb726e        goharbor/registry-photon:v2.2.1      "/home/harbor/entryp…"   14 minutes ago      Up 14 minutes (healthy)                               registry            1.64MB (virtual 78.9MB)
# d2d444e41e83        goharbor/harbor-registryctl:v2.2.1   "/home/harbor/start.…"   14 minutes ago      Up 14 minutes (healthy)                               registryctl         1.64MB (virtual 130MB)
# 5373bd72bd3a        goharbor/harbor-portal:v2.2.1        "nginx -g 'daemon of…"   14 minutes ago      Up 14 minutes (healthy)                               harbor-portal       2B (virtual 51MB)
# 08583263ba9b        goharbor/redis-photon:v2.2.1         "redis-server /etc/r…"   14 minutes ago      Up 14 minutes (healthy)                               redis               0B (virtual 68.9MB)
# f61895452b30        goharbor/harbor-db:v2.2.1            "/docker-entrypoint.…"   14 minutes ago      Up 14 minutes (healthy)                               harbor-db           59B (virtual 175MB)
# 15d128416b55        goharbor/harbor-log:v2.2.1           "/bin/sh -c /usr/loc…"   14 minutes ago      Up 14 minutes (healthy)   127.0.0.1:1514->10514/tcp   harbor-log          0B (virtual 108MB)
```

```bash
curl ${HARBOR_HOST}
```

## LDAP 설정

- `http://${HOSTNAME}/harbor/configs`
- `Administration`
- `Configuration`
- `Authentication` - `Auth Mode` - `LDAP`

## `Projects`

```bash
export PROJECT_REPO=dist
docker login http://${HARBOR_HOST}/${PROJECT_REPO} -u admin -p Harbor12345
```

### Docker Image

```bash
# docker tag SOURCE_IMAGE[:TAG] ${HARBOR_HOST}/${PROJECT_REPO}/REPOSITORY[:TAG]
docker tag registry:2.7.1 ${HARBOR_HOST}/${PROJECT_REPO}/registry:2.7.1

# docker push ${HARBOR_HOST}/${PROJECT_REPO}/REPOSITORY[:TAG]
docker push ${HARBOR_HOST}/${PROJECT_REPO}/registry:2.7.1
```

```bash
docker pull ${HARBOR_HOST}/${PROJECT_REPO}/registry:2.7.1
```

### Helm Chart

## Clean up

```bash
docker-compose down
```

## Restart

```bash
docker-copmose up -d
```
