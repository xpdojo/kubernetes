# 도커 설치

- [도커 설치](#도커-설치)
  - [Ubuntu 18.04](#ubuntu-1804)
    - [설치](#설치)
    - [제거](#제거)
  - [CentOS 7](#centos-7)
    - [설치](#설치-1)
    - [제거](#제거-1)

## Ubuntu 18.04

### [설치](https://docs.docker.com/engine/install/ubuntu/)

```bash
sudo apt-get update

sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```bash
sudo apt-get update
apt-cache madison docker-ce
# docker-ce | 5:20.10.6~3-0~ubuntu-bionic | https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages
# [...]
# docker-ce | 5:19.03.15~3-0~ubuntu-bionic | https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages
# [...]
```

```bash
# latest
sudo apt-get install docker.io

# specific version
export DOCKER_VERSION=5:19.03.15~3-0~ubuntu-bionic
sudo apt-get install \
  docker-ce=${DOCKER_VERSION} \
  docker-ce-cli=${DOCKER_VERSION} \
  containerd.io
```

### 제거

```bash
sudo apt-get purge \
  docker-ce \
  docker-ce-cli \
  containerd.io
```

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## CentOS 7

### [설치](https://docs.docker.com/engine/install/centos/)

yum 리포지터리 추가

```bash
sudo yum update
sudo yum install -y yum-utils
sudo yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
```

Docker 설치

```bash
yum list docker-ce --showduplicates | sort -r
# docker-ce.x86_64            3:20.10.6-3.el7                     docker-ce-stable
# [...]
# docker-ce.x86_64            3:19.03.9-3.el7                     docker-ce-stable
# [...]

# latest
sudo yum install \
  docker-ce \
  docker-ce-cli \
  containerd.io

# specific version
export DOCKER_VERSION=19.03.9-3.el7

sudo yum install \
  docker-ce-${DOCKER_VERSION} \
  docker-ce-cli-${DOCKER_VERSION} \
  containerd.io

sudo systemctl start docker
```

`docker-compose` 설치

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose version
```

### 제거

```bash
sudo yum remove \
  docker-ce \
  docker-ce-cli \
  containerd.io
```

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```
