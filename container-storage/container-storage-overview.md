# 컨테이너 스토리지 톺아보기

> FIXME: 아직 스토리지 부분은 잘 모르겠다.

- [컨테이너 스토리지 톺아보기](#컨테이너-스토리지-톺아보기)
  - [참고 자료](#참고-자료)
  - [Kubernetes Storage API](#kubernetes-storage-api)
    - [PersistentVolume](#persistentvolume)
    - [PersistentVolumeClaim](#persistentvolumeclaim)
    - [StorageClass](#storageclass)
  - [스토리지(Storage)와 볼륨(Volume)의 차이](#스토리지storage와-볼륨volume의-차이)
  - [스토리지 종류](#스토리지-종류)

## 참고 자료

- [Container Storage Interface (CSI) for Kubernetes GA](https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/)
- [CSI Driver List](https://kubernetes-csi.github.io/docs/drivers.html)
- [CSI NFS Driver](https://github.com/kubernetes-csi/csi-driver-nfs)
- [Getting Started with Kubernetes | Storage Architecture and Plug-ins](https://www.alibabacloud.com/blog/getting-started-with-kubernetes-%7C-storage-architecture-and-plug-ins_596307) - Kan Junbao
- [What Is Kubernetes Storage? How Persistent Storage Works](https://www.enterprisestorageforum.com/cloud/kubernetes-storage/) - Sean Michael Kerner
- [Introduction to Kubernetes Storage and NVMe-oF Support](https://01.org/kubernetes/blogs/qwang10/2019/introduction-kubernetes-storage-and-nvme-support) - Shane Wang
- [CSI](https://github.com/kodekloudhub/certified-kubernetes-administrator-course/blob/master/docs/08-Storage/05-Container.Storage-Interface.md) - KodeKloud

## Kubernetes Storage API

### PersistentVolume

### PersistentVolumeClaim

### StorageClass

## 스토리지(Storage)와 볼륨(Volume)의 차이

## 스토리지 종류

- [파일 스토리지, 블록 스토리지 또는 오브젝트 스토리지](https://www.redhat.com/ko/topics/data-storage/file-block-object-storage) - RedHat
- [오브젝트 스토리지, 파일 스토리지, 블록 스토리지의 차이](https://www.alibabacloud.com/ko/knowledge/difference-between-object-storage-file-storage-block-storage) - Alibaba Cloud
