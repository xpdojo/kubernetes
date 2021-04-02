# test crawler

- [test crawler](#test-crawler)
  - [Python3 설치](#python3-설치)
    - [이미 scrapy 프로젝트가 있을 경우](#이미-scrapy-프로젝트가-있을-경우)
    - [새로운 scrapy 프로젝트 생성해야 할 경우](#새로운-scrapy-프로젝트-생성해야-할-경우)
  - [도커 이미지 빌드](#도커-이미지-빌드)
  - [`docker-compose`](#docker-compose)
  - [쿠버네티스 클러스터에 배포](#쿠버네티스-클러스터에-배포)
  - [docker registry](#docker-registry)
    - [NFS Provisioner](#nfs-provisioner)
    - [Elasticsearch](#elasticsearch)
    - [CronJob](#cronjob)
    - [크론 스케줄 문법](#크론-스케줄-문법)

## Python3 설치

> 테스트 환경: macOS Catalina 10.15.7

```bash
which python
ls -al /usr/bin/python*
# lrwxr-xr-x  1 root  wheel     75  3 28  2020 /usr/bin/python -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/python2.7
# lrwxr-xr-x  1 root  wheel     82  3 28  2020 /usr/bin/python-config -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/python2.7-config
# lrwxr-xr-x  1 root  wheel     75  3 28  2020 /usr/bin/python2 -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/python2.7
# lrwxr-xr-x  1 root  wheel     75  3 28  2020 /usr/bin/python2.7 -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/python2.7
# lrwxr-xr-x  1 root  wheel     82  3 28  2020 /usr/bin/python2.7-config -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/python2.7-config
# -rwxr-xr-x  1 root  wheel  31488  9 22  2020 /usr/bin/python3
# lrwxr-xr-x  1 root  wheel     76  3 28  2020 /usr/bin/pythonw -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/pythonw2.7
# lrwxr-xr-x  1 root  wheel     76  3 28  2020 /usr/bin/pythonw2.7 -> ../../System/Library/Frameworks/Python.framework/Versions/2.7/bin/pythonw2.7
```

```bash
# `rm` 하지 말 것!!! rm -rf /System/Library/Frameworks/Python.framework
brew install python3
```

```bash
which pip
# /usr/local/bin/pip
which pip3
# /usr/local/bin/pip3
ln -s -f /usr/local/bin/pip3 /usr/local/bin/pip

pip --version
# pip 21.0.1 from /usr/local/lib/python3.9/site-packages/pip (python 3.9)
```

```bash
which python
# /usr/bin/python
which python3
# /usr/bin/python3
ln -s -f /usr/bin/python3 /usr/bin/python
# ln: /usr/bin/python: Read-only file system
# ???
```

### 이미 scrapy 프로젝트가 있을 경우

dependency 모듈을 자동으로 requirements.txt 파일로 추출해주는 `pipreqs`

```bash
# pip3 freeze > requirements.txt
pip3.9 install pipreqs
pipreqs --force ./yna_crawler
```

dependencies 모듈을 설치합니다.

```bash
pip3.9 install -r requirements.txt

scrapy version
# Scrapy 2.4.1
```

`crawl` 명령어를 실행합니다.

```bash
# python3.9 scraper/runner.py
cd yna_crawler
scrapy crawl yna_spider
```

### 새로운 scrapy 프로젝트 생성해야 할 경우

```bash
pip3 install scrapy
scrapy startproject yna_crawler
cd yna_crawler/yna_crawler/spiders
scrapy genspider -t crawl yna https://www.yna.co.kr/news?site=navi_latest_depth01
```

```bash
cd ../..
scrapy crawl --set=ROBOTSTXT_OBEY='True' yna_spdiers
```

## 도커 이미지 빌드

```bash
docker build . -t 192.168.7.191:5000/edge-crawler:0.1.0
docker push 192.168.7.191:5000/edge-crawler:0.1.0
```

## `docker-compose`

```bash
# docker builder prune
# docker container prune
# docker image prune

docker-compose up
docker-compose down
```

```bash
# {"type":"log","@timestamp":"2021-04-02T04:57:56+00:00","tags":["info","savedobjects-service"],"pid":7,"message":"Starting saved objects migrations"}
# {"type":"log","@timestamp":"2021-04-02T04:57:56+00:00","tags":["info","savedobjects-service"],"pid":7,"message":"Creating index .kibana_task_manager_1."}
# {"type":"log","@timestamp":"2021-04-02T04:57:57+00:00","tags":["info","savedobjects-service"],"pid":7,"message":"Creating index .kibana_1."}
# {"type":"log","@timestamp":"2021-04-02T04:57:58+00:00","tags":["warning","savedobjects-service"],"pid":7,"message":"Unable to connect to Elasticsearch. Error: resource_already_exists_exception"}
# {"type":"log","@timestamp":"2021-04-02T04:57:59+00:00","tags":["warning","savedobjects-service"],"pid":7,"message":"Another Kibana instance appears to be migrating the index. Waiting for that migration to complete. If no other Kibana instance is attempting migrations, you can get past this message by deleting index .kibana_1 and restarting Kibana."}
rm -rf data01 data02
docker-compose up
# docker-compose down
```

## 쿠버네티스 클러스터에 배포

## docker registry

```bash
docker run \
--detach \
--publish 5000:5000 \
--restart=always \
--name registry \
--env REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/root/images \
--env REGISTRY_STORAGE_DELETE_ENABLED=true \
registry:2.7.1
```

- [Docker Docs](https://docs.docker.com/registry/insecure/)
- `vim /etc/docker/daemon.json`

```json
{
  "insecure-registries": ["192.168.7.191:5000"]
}
```

```bash
systemctl restart docker

docker build . -t 192.168.7.191:5000/yna-crawler
docker push 192.168.7.191:5000/yna-crawler
```

### NFS Provisioner

```bash
# apt-get install -y nfs-common
yum install -y nfs-utils

helm --kubeconfig=$KUBE_CONFIG install storage stable/nfs-client-provisioner \
--set nfs.server='192.168.88.11' \
--set nfs.path='/volume2/backups/nfs_esxi05'
```

- troubleshooting

```bash
# Warning  FailedMount  57s (x9 over 3m5s)  kubelet            MountVolume.SetUp failed for volume "nfs-client-root" : mount failed: exit status 32
# Mounting command: mount
# Mounting arguments: -t nfs 192.168.88.11:/volume2/backups/nfs_esxi05 /var/lib/kubelet/pods/23362ae2-3eae-4793-a67d-6a36df96eb8e/volumes/kubernetes.io~nfs/nfs-client-root
# Output: mount: wrong fs type, bad option, bad superblock on 192.168.88.11:/volume2/backups/nfs_esxi05,
#        missing codepage or helper program, or other error
#        (for several filesystems (e.g. nfs, cifs) you might
#        need a /sbin/mount.<type> helper program)
#
#        In some cases useful info is found in syslog - try
#        dmesg | tail or so.

dmesg | tail
# [  141.427031] IPVS: [sh] scheduler registered.
# [  144.968739] TECH PREVIEW: eBPF syscall may not be fully supported.
# Please review provided documentation for limitations.
# [  144.985426] ipip: IPv4 over IPv4 tunneling driver
# [  145.024535] ip_set: protocol 7
# [ 3790.125645] SELinux: 2048 avtab hash slots, 113528 rules.
# [ 3790.154087] SELinux: 2048 avtab hash slots, 113528 rules.
# [ 3790.169571] SELinux:  8 users, 14 roles, 5057 types, 318 bools, 1 sens, 1024 cats
# [ 3790.169573] SELinux:  130 classes, 113528 rules
# [ 3790.171194] SELinux:  Converting 2270 SID table entries...
```

### Elasticsearch

- Elasticsearch

### CronJob

```bash
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: yna-crawler
  labels:
    app: yna-crawler
spec:
  schedule: "0 * * * *" # hourly (https://crontab.guru/)
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: yna-crawler
              image: 192.168.7.191/yna-crawler:0.1.0
              imagePullPolicy: Always
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
EOF
```

### 크론 스케줄 문법

- [공식 문서](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax) - Kubernetes
