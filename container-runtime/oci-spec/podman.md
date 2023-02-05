# RedHat Podman, Buildahbrew install podman

- [RedHat Podman, Buildahbrew install podman](#redhat-podman-buildahbrew-install-podman)
  - [설치](#설치)
    - [Linux](#linux)
    - [macOS](#macos)
  - [macOS, Windows VM 관리](#macos-windows-vm-관리)
  - [컨테이너 관리](#컨테이너-관리)
  - [Compose](#compose)
    - [podman-compose 설치](#podman-compose-설치)
    - [컨테이너 생성](#컨테이너-생성)
    - [컨테이너 제거](#컨테이너-제거)

## 설치

- [Podman Installation Instructions](https://podman.io/getting-started/installation)

### Linux

```sh
yum install podman
```

```sh
apt install podman
```

### macOS

```sh
brew update && brew upgrade && brew cleanup
```

```sh
brew install podman
# To restart podman after an upgrade:
#   brew services restart podman
# Or, if you don't want/need a background service you can just run:
#   /opt/homebrew/opt/podman/bin/podman system service --time=0
```

```sh
podman info
# host:
#   arch: arm64
#   buildahVersion: 1.28.0
# ...
```

## macOS, Windows VM 관리

```sh
podman machine -h
```

```sh
Manage a virtual machine

Description:
  Manage a virtual machine. Virtual machines are used to run Podman.

Usage:
  podman machine [command]

Available Commands:
  info        Display machine host info
  init        Initialize a virtual machine
  inspect     Inspect an existing machine
  list        List machines
  rm          Remove an existing machine
  set         Sets a virtual machine setting
  ssh         SSH into an existing machine
  start       Start an existing machine
  stop        Stop an existing machine
```

VM 설정 시 볼륨 마운트를 하지 않으면
컨테이너 생성 시 로컬 환경에서 볼륨 마운트를 할 수 없다.
VM 안에서 직접 마운트해야 한다.
꼭 VM 초기화할 때 볼륨을 설정해주자.

```sh
# podman machine init [options] [NAME]
podman machine init -v $HOME:$HOME
```

```sh
Downloading VM image: fedora-coreos-37.20230122.2.0-qemu.aarch64.qcow2.xz: done
Extracting compressed file
Image resized.
Machine init complete
```

```sh
podman machine start
```

```sh
Starting machine "podman-machine-default"
Waiting for VM ...
Mounting volume... /Users/markruler:/Users/markruler

This machine is currently configured in rootless mode. If your containers
require root permissions (e.g. ports < 1024), or if you run into compatibility
issues with non-podman clients, you can switch using the following command:

  podman machine set --rootful

API forwarding listening on: /Users/markruler/.local/share/containers/podman/machine/podman-machine-default/podman.sock

The system helper service is not installed; the default Docker API socket
address can't be used by podman. If you would like to install it run the
following commands:

  sudo /opt/homebrew/Cellar/podman/4.3.1/bin/podman-mac-helper install
  podman machine stop; podman machine start

You can still connect Docker API clients by setting DOCKER_HOST using the
following command in your terminal session:

  export DOCKER_HOST='unix:///Users/markruler/.local/share/containers/podman/machine/podman-machine-default/podman.sock'

Machine "podman-machine-default" started successfully
```

```sh
podman machine ls
# NAME                     VM TYPE     CREATED         LAST UP            CPUS        MEMORY      DISK SIZE
# podman-machine-default*  qemu        42 minutes ago  Currently running  1           2.147GB     107.4GB
```

```sh
podman machine stop
```

```sh
podman machine rm
```

## 컨테이너 관리

`docker` 명령어를 그대로 사용할 수 있다.
명령어 이름만 `podman`으로 변경하면 된다.

```sh
# docker run --name=redis-local -d --restart=always -p 6379:6379 redis:5.0.13
podman run --name=redis-local -d --restart=always -p 6379:6379 redis:5.0.13
```

## Compose

- [Compose Spec](https://github.com/compose-spec/compose-spec)
- [podman-compose](https://github.com/containers/podman-compose)

### podman-compose 설치

```sh
pip3 install podman-compose
```

### 컨테이너 생성

```sh
podman-compose up -d
```

### 컨테이너 제거

```sh
podman-compose down
```
