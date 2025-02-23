--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
# KVM

Manually create a set of VMs and install OS and use these VM templates to clone other guest VMs
The VM templates have entire OS and SSH configured tso allow KVM host access using user kenneth 

## Table of Contents
- [Set up ssh keys](#set-keygen | kvm_host)
- [Install a new OS manually](#virt-install | kvm_host)
- [Clone the new VM with fully installed OS for safe keep](#virt-clone | kvm_host)
- [Used the clone VM to clone a new VM for project](#virt-clone-1 | kvm_host)
- [Update the hostname for the new VM](#virt-sysprep | kvm_host)
- [Login to new VM to find the IP address](#virt-manager-run-open | guest vm)
- [Update inventory/inventory.ini file](#update-inventory-inventory.ini-file-with-new-ip-address | kvm_host)
- [ Playbook Execution](#ansible-playbook | kvm_host)


--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Set up SSH keys (kvm_host)

--------------------------------------------------------------------------------------------------
```bash
ssh-keygen -t ed25519 -C "Kenneth Wong"
    # paraphase: 1....
```

--------------------------------------------------------------------------------------------------
```bash
ssh-keygen -t ed25519 -C "ansible"
    # paraphase:
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Install a new OS manually]

### virt-install (kvm_host)

This is an one time manual operation and then we use virt-clone to save a copy of them from accidential modification

--------------------------------------------------------------------------------------------------
```bash
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-a1-1-u2004-6 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu20.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-20.04.6-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-a1-1-u2004-6.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc
```

--------------------------------------------------------------------------------------------------
```bash
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-a1-2-u2204-5 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu22.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-22.04.5-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-a1-2-u2204-5.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc
```

--------------------------------------------------------------------------------------------------
```bash
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-a1-3-u2404-1 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu24.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-24.04-1-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-a1-3-u2404.1.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc
```

--------------------------------------------------------------------------------------------------
```bash
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-a1-4-u2410 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu24.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-24.10-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-a1-4-u2410.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Clone the new VM with fully installed OS for safe keep](#virt-clone)

### virt-clone (kvm_host)

--------------------------------------------------------------------------------------------------
Used the original VM to clone a new template VM for the projects

```bash
sudo virt-clone --original kvm-master-a1-1-u2004-6 --name kvm-master-a1-1-u2004-6-clone --file /var/lib/libvirt/images/kvm-master-a1-1-u2004-6-clone.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5 --name kvm-master-a1-2-u2204-5-clone --file /var/lib/libvirt/images/kvm-master-a1-2-u2204-5-clone.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1 --name kvm-master-a1-3-u2404-1-clone --file /var/lib/libvirt/images/kvm-master-a1-3-u2404-1-clone.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410 --name kvm-master-a1-4-u2410-clone     --file /var/lib/libvirt/images/kvm-master-a1-4-u2410-clone.qcow2
```

--------------------------------------------------------------------------------------------------
### Update the template VM hostname

```bash
sudo virt-sysprep -d kvm-master-a1-1-u2004-6-clone --hostname kvm-master-a1-1-u2004-6-clone
sudo virt-sysprep -d kvm-master-a1-2-u2204-5-clone --hostname kvm-master-a1-2-u2204-5-clone
sudo virt-sysprep -d kvm-master-a1-3-u2404-1-clone --hostname kvm-master-a1-3-u2404-1-clone
sudo virt-sysprep -d kvm-master-a1-4-u2410-clone   --hostname kvm-master-a1-4-u2410-clone
```

-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
### virt-manager/Run/Open (kvm_host)

kvm-master-a1-1-u2004-6-clone
kvm-master-a1-2-u2204-5-clone
kvm-master-a1-3-u2404-1-clone
kvm-master-a1-4-u2410-clone

### Give kenneth user the sudo permission (kvm guest vm)

--------------------------------------------------------------------------------------------------
```bash
sudo visudo
kenneth ALL=(ALL) NOPASSWD: ALL
``` 
    
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
### Login to new VM to find the IP address (kvm guest vm)
    
Install openssh-server (guest vm)

--------------------------------------------------------------------------------------------------
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server
```

### Enable SSH (guest vm)

--------------------------------------------------------------------------------------------------
```bash
sudo systemctl status ssh
sudo systemctl enable ssh
sudo systemctl start  ssh
sudo systemctl status ssh
```

--------------------------------------------------------------------------------------------------
```bash
ip a
``` 
--------------------------------------------------------------------------------------------------
### ssh-copy-id (kvm_host)

```bash
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.51
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.53
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.54
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.55

ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.51
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.53
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.54
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.55
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Used the clone VM to clone a new VM for project](#virt-clone-1)


``bash
sudo virt-clone --original kvm-master-a1-1-u2004-6-clone --name kvm-a1-1-u2004-6 --file /var/lib/libvirt/images/kvm-a1-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5-clone --name kvm-a1-2-u2204-5 --file /var/lib/libvirt/images/kvm-a1-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1-clone --name kvm-a1-3-u2404-1 --file /var/lib/libvirt/images/kvm-a1-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410-clone   --name kvm-a1-4-u2410   --file /var/lib/libvirt/images/kvm-a1-4-u2410.qcow2

sudo virt-clone --original kvm-master-a1-1-u2004-6-clone --name kvm-a2-1-u2004-6 --file /var/lib/libvirt/images/kvm-a2-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5-clone --name kvm-a2-2-u2204-5 --file /var/lib/libvirt/images/kvm-a2-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1-clone --name kvm-a2-3-u2404-1 --file /var/lib/libvirt/images/kvm-a2-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410-clone   --name kvm-a2-4-u2410   --file /var/lib/libvirt/images/kvm-a2-4-u2410.qcow2
```

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
## Update the hostname for the new VM](#virt-sysprep | kvm_host)

``bash
sudo virt-sysprep -d  kvm-a1-1-u2004-6 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a1-2-u2204-5 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a1-3-u2404-1 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a1-4-u2410   --operations defaults,-ssh-hostkeys,-ssh-userdir

sudo virt-sysprep -d  kvm-a2-1-u2004-6 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a2-2-u2204-5 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a2-3-u2404-1 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a2-4-u2410   --operations defaults,-ssh-hostkeys,-ssh-userdir
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Login to new VM to find the IP address](#virt-manager-run-open | kvm_host)

```bash
ip a
``` 

## Update inventory/inventory.ini

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Playbook Execution (kvm_host)

--------------------------------------------------------------------------------------------------
```bash

ssh kenneth@kvm-master-a1-1-u2004-6.local

ansible kvm_guests_group1  -m ping
ansible kvm_guests_group2  -m ping
ansible kvm_guests_group3  -m ping
ansible all -m ping
ansible all  -m debug -a "var=ansible_host"

time ansible-playbook kvm_guest_vms.yml

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
