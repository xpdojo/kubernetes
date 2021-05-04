# 네트워크 인터페이스 설정

- [네트워크 인터페이스 설정](#네트워크-인터페이스-설정)
  - [CentOS 7](#centos-7)
    - [Network scripts](#network-scripts)
    - [nmtui](#nmtui)
  - [Ubuntu 18.04](#ubuntu-1804)
    - [netplan](#netplan)

## CentOS 7

### Network scripts

- [참고](https://www.lesstif.com/system-admin/centos-network-centos-static-ip-13631535.html)

```bash
vi /etc/sysconfig/network-scripts/ifcfg-eno1
# 수정 후
systemctl restart network
```

```bash
# 네트워크를 사용하는 명령어를 통해 정상 동작 여부 확인
yum check-update
```

### nmtui

Text User Interface for controlling NetworkManager

```bash
nmtui
```

## Ubuntu 18.04

### netplan

```bash
vi /etc/netplan/00-ens160
```

```bash
netplan apply
ip -br -c -4 a
```
