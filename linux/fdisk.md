# 디스크 마운트

## CentOS 7

```bash
fdisk -l
# Disk /dev/sdb: 30.0 GB, 30016659456 bytes, 58626288 sectors
# Units = sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# Disk label type: dos
# Disk identifier: 0x00051ac3
# 
#    Device Boot      Start         End      Blocks   Id  System
# /dev/sdb1   *        2048     2099199     1048576   83  Linux
# /dev/sdb2         2099200    58626047    28263424   8e  Linux LVM
# 
# Disk /dev/sda: 3840.8 GB, 3840755982336 bytes, 7501476528 sectors
# Units = sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 4096 bytes
# I/O size (minimum/optimal): 4096 bytes / 4096 bytes
# Disk label type: dos
# Disk identifier: 0x00000000
# 
#    Device Boot      Start         End      Blocks   Id  System
# /dev/sda1               1  4294967294  2147483647   ee  GPT
# Partition 1 does not start on physical sector boundary.
# 
# Disk /dev/mapper/centos-root: 25.9 GB, 25937575936 bytes, 50659328 sectors
# Units = sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# 
# 
# Disk /dev/mapper/centos-swap: 3003 MB, 3003121664 bytes, 5865472 sectors
# Units = sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
```

Delete a partition

```bash
fdisk /dev/sda
Command (m for help): d
# Selected partition 1
# Partition 1 is deleted
```

```bash
blkid
# [...]
# /dev/sda1: LABEL="EFI" UUID="67E3-17ED" TYPE="vfat" PARTLABEL="EFI System Partition" PARTUUID="51176fd3-7ce8-4324-832e-9a9114dbd8d8"
# /dev/sda2: PARTUUID="67a84f63-5d6a-4ad3-917f-d06b903793ef"
```

Build a Linux filesystem

```bash
# mkfs.ext4 /dev/sda
mkfs -t ext4 /dev/sda
# mke2fs 1.42.9 (28-Dec-2013)
# /dev/sda is entire device, not just one partition!
# Proceed anyway? (y,n) y
# Discarding device blocks: 118493184/937684566

# done
# Filesystem label=
# OS type: Linux
# Block size=4096 (log=2)
# Fragment size=4096 (log=2)
# Stride=0 blocks, Stripe width=0 blocks
# 234422272 inodes, 937684566 blocks
# 46884228 blocks (5.00%) reserved for the super user
# First data block=0
# Maximum filesystem blocks=3087007744
# 28616 block groups
# 32768 blocks per group, 32768 fragments per group
# 8192 inodes per group
# Superblock backups stored on blocks:
#   32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
#   4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
#   102400000, 214990848, 512000000, 550731776, 644972544
# 
# Allocating group tables: done
# Writing inode tables: done
# Creating journal (32768 blocks): done
# Writing superblocks and filesystem accounting information: done
```

```bash
blkid
# [...]
# /dev/sda: UUID="03567edc-f6d3-4895-ac9d-17ff6ed1022e" TYPE="ext4"
```

```bash
mkdir /data
mount -t ext4 /dev/sda /data

# man fstab
echo "UUID=03567edc-f6d3-4895-ac9d-17ff6ed1022e /data ext4  defaults  1 2" >> /etc/fstab 

df -h
# [...]
# /dev/sda                 3.5T   89M  3.3T   1% /data
```
