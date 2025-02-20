--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
# Project Title

Manually create a VM and install OS

## Table of Contents
- [ssh-keygen](Set up ssh keys)
- [virt-install](Install a new OS manually)
- [virt-clone](Clone the new VM with fully installed OS for safe keep)
- [virt-clone](Used the clone VM to clone a new VM for project)
- [virt-sysprep](Update the hostname for the new VM)
- [virt-manager/Run, Open](Login to new VM to find the IP address)
= [Update inventory/inventory.ini file](with new IP address)

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Set up ssh keys (kvm_host)

--------------------------------------------------------------------------------------------------
ssh-keygen -t ed25519 -C "Kenneth Wong"
    paraphase: 1....

--------------------------------------------------------------------------------------------------
ssh-keygen -t ed25519 -C "ansible"
    paraphase:

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## virt-install (kvm_host)

Do it one time only and then virt-clone to save a copy as this is a labor intensive operation to install OS

--------------------------------------------------------------------------------------------------
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-1-1-u2004.6 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu20.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-20.04.6-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-1-1-u2004.6.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc

--------------------------------------------------------------------------------------------------
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-1-2-u2204.5 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu22.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-22.04.5-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-1-2-u2204.5.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc

--------------------------------------------------------------------------------------------------
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-1-3-u2404.1 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu24.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-24.04.1-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-1-3-u2404.1.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc

--------------------------------------------------------------------------------------------------
sudo virt-install \
    --virt-type=kvm \
    --name kvm-master-1-4-u2410 \
    --memory 10240 \
    --vcpus=8 \
    --os-variant ubuntu24.04 \
    --hvm \
    --cdrom /home/kenneth-wong/Downloads/ISO/ubuntu-24.10-desktop-amd64.iso \
    --network=bridge=bridge0,model=virtio \
    --graphics spice,listen=127.0.0.1 \
    --video qxl \
    --disk size=100,path=/var/lib/libvirt/images/kvm-master-1-4-u2410.qcow2,bus=virtio,format=qcow2 \
    --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    --channel spicevmc

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## virt-clone (kvm_host)

Clone the new VM with fully installed OS for safe keep

--------------------------------------------------------------------------------------------------
sudo virt-clone --original kvm-master-1-1-u2004.6 --name kvm-master-u2004-6-clone --file /var/lib/libvirt/images/kvm-master-u2004-6-clone.qcow2
sudo virt-clone --original kvm-master-1-2-u2204.5 --name kvm-master-u2204-5-clone --file /var/lib/libvirt/images/kvm-master-u2204-5-clone.qcow2
sudo virt-clone --original kvm-master-1-3-u2404.1 --name kvm-master-u2404-1-clone --file /var/lib/libvirt/images/kvm-master-u2404-1-clone.qcow2
sudo virt-clone --original kvm-master-1-4-u2410 --name kvm-master-u2410-clone --file /var/lib/libvirt/images/kvm-master-u2410-clone.qcow2

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## virt-clone (kvm_host)

Used the clone VM to clone a new VM for project

--------------------------------------------------------------------------------------------------
sudo virt-clone --original kvm-master-u2004-6-clone --name kvm-a1-1-u2004-6 --file /var/lib/libvirt/images/kvm-a1-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-u2204-5-clone --name kvm-a1-2-u2204-5 --file /var/lib/libvirt/images/kvm-a1-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-u2404-1-clone --name kvm-a1-3-u2404-1 --file /var/lib/libvirt/images/kvm-a1-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-u2410-clone --name kvm-a1-4-u2410 --file /var/lib/libvirt/images/kvm-a1-4-u2410.qcow2

sudo virt-clone --original kvm-master-u2004-6-clone --name kvm-a2-1-u2004-6 --file /var/lib/libvirt/images/kvm-a2-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-u2204-5-clone --name kvm-a2-2-u2204-5 --file /var/lib/libvirt/images/kvm-a2-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-u2404-1-clone --name kvm-a2-3-u2404-1 --file /var/lib/libvirt/images/kvm-a2-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-u2410-clone --name kvm-a2-4-u2410 --file /var/lib/libvirt/images/kvm-a2-4-u2410.qcow2

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## virt-sysprep (kvm_host)

Update the hostname for the new VM

--------------------------------------------------------------------------------------------------
sudo virt-sysprep -d kvm-a1-1-u2004-6 --hostname kvm-a1-1-u2004-6
sudo virt-sysprep -d kvm-a1-2-u2204-5 --hostname kvm-a1-2-u2204-5
sudo virt-sysprep -d kvm-a1-3-u2404-1 --hostname kvm-a1-3-u2404-1
sudo virt-sysprep -d kvm-a1-4-u2410 --hostname kvm-a1-4-u2410

sudo virt-sysprep -d kvm-a2-1-u2004-6 --hostname kvm-a2-1-u2004-6
sudo virt-sysprep -d kvm-a2-2-u2204-5 --hostname kvm-a2-2-u2204-5
sudo virt-sysprep -d kvm-a2-3-u2404-1 --hostname kvm-a2-3-u2404-1
sudo virt-sysprep -d kvm-a2-4-u2410 --hostname kvm-a2-4-u2410

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## virt-manager/Run, Open (kvm_host)

### Ensure user kenneth has proper permission to sudo

--------------------------------------------------------------------------------------------------
- Start vm and
sudo visudo
kenneth ALL=(ALL) NOPASSWD: ALL

### Login to new VM to find the IP address (guest vm)
--------------------------------------------------------------------------------------------------
ip a

### Install openssh-server (guest vm)

--------------------------------------------------------------------------------------------------
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server

### Enable ssh (guest vm)

--------------------------------------------------------------------------------------------------
sudo systemctl status ssh
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Update inventory/inventory.ini file with new IP address

--------------------------------------------------------------------------------------------------
[kvm_guests_group1]

kvm-1-1-u2004-6 ansible_host=192.168.1.22
kvm-1-2-u2204-5 ansible_host=192.168.1.23
kvm-1-3-u2404-1 ansible_host=192.168.1.14
kvm-1-4-u2410 ansible_host=192.168.1.24

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## ssh-copy-id (kvm_host)

ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.18
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.17
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.19
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.20

ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.218
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.217
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.19
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.20

ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.25
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.26
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.17
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.15

ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.25
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.26
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.17
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_ansible.pub kenneth@192.168.1.15

ssh kenneth@192.168.1.22
ssh kenneth@192.168.1.23
ssh kenneth@192.168.1.14
ssh kenneth@192.168.1.24

==================================================================================================
==================================================================================================
==================================================================================================
[playbook] (kvm_host)

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ssh kenneth@kvm-master-a1-1-u2004-6.local

ansible kvm_guests_group1  -m ping
ansible kvm_guests_group2  -m ping
ansible kvm_guests_group3  -m ping
ansible  all -m ping
ansible all  -m debug -a "var=ansible_host"

### XXXXXXXXXX---------------------------
time ansible-playbook kvm_guest_vms.yml

==================================================================================================
==================================================================================================
==================================================================================================
