# KVM

Using KVM to create a test execution environment with a set of worker/guest VMs
to execute tests using ansible playbooks and pytest. The tests are downloaded
to the guest VMs via git clone. The generated test logs are copied back to the
KVM host.

Here is our test setup.
- Our localhost is the KVM host
- Create a set of VMs as templates that has ubuntu OS installed
- Clone a new set of worker/guest VMs from the template
- Add default "kenneth" to allow sudo access
- Add SSH support so ansible can access the guest VMs
- Locate IP address of guest VMs and update inventory/inventory.ini file
- Set up ssh-key on KVM host and upload them to guest VMs for remote access without passwd
- Clone a set of guest VMS using the templates
- Enable authorized_keys for target VMs

## Table of Contents
- [Install a new OS manually](#install-a-new-os-manually)
- [Clone the new VM with fully installed OS for safe keep](#clone-the-new-vm-with-fully-installed-os-for-safe-keep)
  - [Used the original VM to clone a new template VM for the projects](#used-the-original-vm-to-clone-a-new-template-vm-for-the-projects)
  - [Update the template VM hostname](#update-the-template-vm-hostname)
  - [VMs Templates](#virt-managerrun-open-kvm_host)
  - [Give kenneth user the sudo permission](#give-kenneth-user-the-sudo-permission-kvm-guest-vm)
  - [Login to new VM to find the IP address](#login-to-new-vm-to-find-the-ip-address-kvm-guest-vm)
  - [Enable SSH](#enable-ssh-guest-vm)
- [Login to new VM used as template to find the IP address](#login-to-new-vm-used-as-template-to-find-the-ip-address-virt-manager-run-open--kvm_host)
  - [Set up SSH keys](#set-up-ssh-keys)
  - [ssh-copy-id](#ssh-copy-id-kvm_host)
- [Used the clone VM to clone a new VM for project](#used-the-clone-vm-to-clone-a-new-vm-for-project-virt-clone-1)
- [Update the hostname for the new VM](#update-the-hostname-for-the-new-vm-virt-sysprep--kvm_host)
- [Login to new VM to find the IP address](#login-to-new-vm-to-find-the-ip-address-virt-manager-run-open--kvm_host-1)
- [Update inventory/inventory.ini](#update-inventoryinventoryini)
- [Authenticate the guest host by login and answer yes](#authenticate-the-guest-host-by-login-and-answer-yes)
- [Enable authorized_keys for target hosts](#enable-authorized_keys-for-target-hosts)
- [Playbook Execution](#playbook-execution-kvm_host)
- [Ansible Playbook Execution](#ansible-playbook-execution)
  - [kvm_guest_vms.yml Usage](#kvm_guest_vmsyml-usage)
  - [load_uvprog2025.yml Usage](#load_uvprog2025yml-usage)
  - [Available Options](#available-options)

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Install a new OS manually

- Perform an one time manual operation to install the OS
- Use virt-clone to save copies of template VMs to prevent them from accidential modification
-

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
## Clone the new VM with fully installed OS for safe keep(#virt-clone)

--------------------------------------------------------------------------------------------------
### Used the original VM to clone a new template VM for the projects

```bash
sudo virt-clone --original kvm-master-a1-1-u2004-6 --name kvm-master-a1-1-u2004-6-clone --file /var/lib/libvirt/images/kvm-master-a1-1-u2004-6-clone.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5 --name kvm-master-a1-2-u2204-5-clone --file /var/lib/libvirt/images/kvm-master-a1-2-u2204-5-clone.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1 --name kvm-master-a1-3-u2404-1-clone --file /var/lib/libvirt/images/kvm-master-a1-3-u2404-1-clone.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410   --name kvm-master-a1-4-u2410-clone   --file /var/lib/libvirt/images/kvm-master-a1-4-u2410-clone.qcow2
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
### virt-manager/Run/Open (kvm_host)

kvm-master-a1-1-u2004-6-clone
kvm-master-a1-2-u2204-5-clone
kvm-master-a1-3-u2404-1-clone
kvm-master-a1-4-u2410-clone

--------------------------------------------------------------------------------------------------
### Give kenneth user the sudo permission (kvm guest vm)

```bash
sudo visudo
kenneth ALL=(ALL) NOPASSWD: ALL
```

--------------------------------------------------------------------------------------------------
### Login to new VM to find the IP address (kvm guest vm)

Install openssh-server (guest vm)

--------------------------------------------------------------------------------------------------
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server
```

--------------------------------------------------------------------------------------------------
### Enable SSH (guest vm)

```bash
sudo systemctl status ssh
sudo systemctl enable ssh
sudo systemctl start  ssh
sudo systemctl status ssh
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Login to new VM used as template to find the IP address (#virt-manager-run-open | kvm_host)

```bash
ip a
```

--------------------------------------------------------------------------------------------------
### Set up SSH keys

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
### ssh-copy-id (kvm_host)

```bash
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.XXX
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.XXX
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.XXX
ssh-copy-id -f -i /home/kenneth/.ssh/id_ed25519_kenneth.pub kenneth@192.168.1.XXX
```

Up to this point all operations performed on the VMs templates.
It has a set of manual operations to configure the VMs templates.

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Used the clone VM to clone a new VM for project (#virt-clone-1)

``bash
sudo virt-clone --original kvm-master-a1-1-u2004-6-clone --name kvm-a1-1-u2004-6 --file /var/lib/libvirt/images/kvm-a1-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5-clone --name kvm-a1-2-u2204-5 --file /var/lib/libvirt/images/kvm-a1-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1-clone --name kvm-a1-3-u2404-1 --file /var/lib/libvirt/images/kvm-a1-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410-clone   --name kvm-a1-4-u2410   --file /var/lib/libvirt/images/kvm-a1-4-u2410.qcow2


sudo virt-clone --original kvm-master-a1-1-u2004-6-clone --name kvm-a2-1-u2004-6 --file /var/lib/libvirt/images/kvm-a2-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5-clone --name kvm-a2-2-u2204-5 --file /var/lib/libvirt/images/kvm-a2-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1-clone --name kvm-a2-3-u2404-1 --file /var/lib/libvirt/images/kvm-a2-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410-clone   --name kvm-a2-4-u2410   --file /var/lib/libvirt/images/kvm-a2-4-u2410.qcow2


sudo virt-clone --original kvm-master-a1-1-u2004-6-clone --name kvm-a3-1-u2004-6 --file /var/lib/libvirt/images/kvm-a3-1-u2004-6.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5-clone --name kvm-a3-2-u2204-5 --file /var/lib/libvirt/images/kvm-a3-2-u2204-5.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1-clone --name kvm-a3-3-u2404-1 --file /var/lib/libvirt/images/kvm-a3-3-u2404-1.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410-clone   --name kvm-a3-4-u2410   --file /var/lib/libvirt/images/kvm-a3-4-u2410.qcow2

sudo virt-clone --original kvm-master-a1-1-u2004-6-clone --name kvm-a-big-u2004-6 --file /var/lib/libvirt/images/kvm-a-big-u2004-6.qcow2
sudo virt-clone --original kvm-master-a1-2-u2204-5-clone --name kvm-a-big-u2204-5 --file /var/lib/libvirt/images/kvm-a-big-u2204-5.qcow2
sudo virt-clone --original kvm-master-a1-3-u2404-1-clone --name kvm-a-big-u2404-1 --file /var/lib/libvirt/images/kvm-a-big-u2404-1.qcow2
sudo virt-clone --original kvm-master-a1-4-u2410-clone   --name kvm-a-big-u2410   --file /var/lib/libvirt/images/kvm-a-big-u2410.qcow2
```


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
### Update the hostname for the new VM (#virt-sysprep | kvm_host)

``bash
sudo virt-sysprep -d  kvm-a1-1-u2004-6 --hostname kvm-a1-1-u2004-6 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a1-2-u2204-5 --hostname kvm-a2-2-u2204-5 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a1-3-u2404-1 --hostname kvm-a1-3-u2404-1 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a1-4-u2410   --hostname kvm-a1-4-u2410   --operations defaults,-ssh-hostkeys,-ssh-userdir

sudo virt-sysprep -d  kvm-a2-1-u2004-6 --hostname kvm-a2-1-u2004-6 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a2-2-u2204-5 --hostname kvm-a2-2-u2204-5 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a2-3-u2404-1 --hostname kvm-a2-3-u2404-1 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a2-4-u2410   --hostname kvm-a2-4-u2410   --operations defaults,-ssh-hostkeys,-ssh-userdir

sudo virt-sysprep -d  kvm-a3-1-u2004-6 --hostname kvm-a3-1-u2004-6 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a3-2-u2204-5 --hostname kvm-a3-2-u2204-5 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a3-3-u2404-1 --hostname kvm-a3-3-u2404-1 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a3-4-u2410   --hostname kvm-a3-4-u2410   --operations defaults,-ssh-hostkeys,-ssh-userdir

sudo virt-sysprep -d  kvm-a-big-u2004-6 --hostname kvm-a-big-u2004-6 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a-big-u2204-5 --hostname kvm-a-big-u2204-5 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a-big-u2404-1 --hostname kvm-a-big-u2404-1 --operations defaults,-ssh-hostkeys,-ssh-userdir
sudo virt-sysprep -d  kvm-a-big-u2410   --hostname kvm-a-big-u2410   --operations defaults,-ssh-hostkeys,-ssh-userdir
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
### Login to new VM to find the IP address (#virt-manager-run-open | kvm_host)

```bash
ip a
```

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
### Update inventory/inventory.ini

``bash
[kvm_guests_group1]
kvm-a1-1-u2004-6 ansible_host=192.168.1.56
kvm-a1-2-u2204-5 ansible_host=192.168.1.57
kvm-a1-3-u2404-1 ansible_host=192.168.1.58
kvm-a1-4-u2410 ansible_host=192.168.1.59

[kvm_guests_group2]
kvm-a2-1-u2004-6 ansible_host=192.168.1.60
kvm-a2-2-u2204-5 ansible_host=192.168.1.61
kvm-a2-3-u2404-1 ansible_host=192.168.1.62
kvm-a2-4-u2410 ansible_host=192.168.1.63

[kvm_guests_group3]
kvm-a3-1-u2004-6 ansible_host=192.168.1.11
kvm-a3-2-u2204-5 ansible_host=192.168.1.12
kvm-a3-3-u2404-1 ansible_host=192.168.1.54
kvm-a3-4-u2410 ansible_host=192.168.1.55

[kvm_guests:children]
kvm_guests_group1
kvm_guests_group2
kvm_guests_group3

[kvm_guests_a_big_group]
kvm-a-big-u2004-6 ansible_host=192.168.1.13
kvm-a-big-u2204-5 ansible_host=192.168.1.14
kvm-a-big-u2404-1 ansible_host=192.168.1.15
kvm-a-big-u2410   ansible_host=192.168.1.17
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Authenticate the guest host by login and answer yes

--------------------------------------------------------------------------------------------------
``bash
ssh kenneth@kvm-a1-1-u2004-6.local
ssh kenneth@kvm-a1-2-u2204-5.local
ssh kenneth@kvm-a1-3-u2404-1.local
ssh kenneth@kvm-a1-4-u2410.local

ssh kenneth@kvm-a2-1-u2004-6.local
ssh kenneth@kvm-a2-2-u2204-5.local
ssh kenneth@kvm-a2-3-u2404-1.local
ssh kenneth@kvm-a2-4-u2410.local

ssh kenneth@kvm-a3-1-u2004-6.local
ssh kenneth@kvm-a3-2-u2204-5.local
ssh kenneth@kvm-a3-3-u2404-1.local
ssh kenneth@kvm-a3-4-u2410.local

ssh kenneth@kvm-a-big-u2004-6.local
ssh kenneth@kvm-a-big-u2204-5.local
ssh kenneth@kvm-a-big-u2404-1.local
ssh kenneth@kvm-a-big-u2410.local
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Enable authorized_keys for target hosts

--------------------------------------------------------------------------------------------------
``bash
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a1-1-u2004-6.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a1-2-u2204-5.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a1-3-u2404-1.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a1-4-u2410.local'

ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a2-1-u2004-6.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a2-2-u2204-5.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a2-3-u2404-1.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a2-4-u2410.local'

ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a3-1-u2004-6.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a3-2-u2204-5.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a3-3-u2404-1.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a3-4-u2410.local'

ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a-big-u2004-6.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a-big-u2204-5.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a-big-u2404-1.local'
ssh-keygen -f '/home/kenneth/.ssh/known_hosts' -R 'kvm-a-big-u2410.local'
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Playbook Execution (kvm_host)

--------------------------------------------------------------------------------------------------
```bash
ssh kenneth@kvm-master-a1-1-u2004-6.local
ssh kenneth@kvm-a1-1-u2004-6.local
ssh kenneth@kvm-a2-1-u2004-6.local
ssh kenneth@kvm-a3-1-u2004-6.local
ansible kvm_guests_group1  -m ping
ansible kvm_guests_group2  -m ping
ansible kvm_guests_group3  -m ping
ansible kvm_guests_a_big_group  -m ping
ansible all -m ping
ansible all  -m debug -a "var=ansible_host"
time ansible-playbook kvm_guest_vms.yml
```

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
## Ansible Playbook Execution

--------------------------------------------------------------------------------------------------
### kvm_guest_vms.yml Usage

This playbook manages KVM guest VMs.

1. Standard run:
```bash
time ansible-playbook kvm_guest_vms.yml
time ansible-playbook kvm_guest_vms.yml -e "include_testme=true"
```

2. Run for specific target VMs:
```bash
time ansible-playbook kvm_guest_vms.yml -e "target_vm=['kvm-a1-4-u2410']"
time ansible-playbook kvm_guest_vms.yml -e "target_vm=['kvm-a2-4-u2410']"
time ansible-playbook kvm_guest_vms.yml -e "target_vm=['kvm-a3-4-u2410']"
```

3. Control whether to include testme tests:
```bash
time ansible-playbook kvm_guest_vms.yml -e "include_testme=true"
```

4. Combine multiple options with verbosity:
```bash
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a1-4-u2410']" -e "include_testme=true"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a2-4-u2410']" -e "include_testme=true"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a3-4-u2410']" -e "include_testme=true"

time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2004-6']" -e "include_testme=true"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2204-5']" -e "include_testme=true"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2404-1']" -e "include_testme=true"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2410']"   -e "include_testme=true"

time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2004-6']" -e "include_testme=false"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2204-5']" -e "include_testme=false"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2404-1']" -e "include_testme=false"
time ansible-playbook kvm_guest_vms.yml -v -e "target_vm=['kvm-a-big-u2410']"   -e "include_testme=false"
```

At this point all the guest VMs are configured with required packages to run test

--------------------------------------------------------------------------------------------------
### load_uvprog2025.yml Usage

This playbook manages Python environments and runs tests on guest VMs.

1. Standard run (delete repos, use default Python version for OS):
```bash
time ansible-playbook load_uvprog2025.yml -v
```

2. Run without deleting repositories:
```bash
time ansible-playbook load_uvprog2025.yml -v -e "nodelete=true"
```

3. Run with a specific Python version:
```bash
time ansible-playbook load_uvprog2025.yml -v -e "python_version_override=3.10"
```

4. Run for specific target VMs:
```bash
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-4-u2410']"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-4-u2410']"
```

5. Control whether to include testme tests:
```bash
time ansible-playbook load_uvprog2025.yml -v -e "include_testme=true"
time ansible-playbook load_uvprog2025.yml -v -e "include_testme=false"
```

6. Combine multiple options:
```bash
--------------------------------------------------------------------------------------------------
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-1-u2004-6']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-1-u2004-6']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-2-u2204-5']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-2-u2204-5']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-3-u2404-1']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-3-u2404-1']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-4-u2410']" -e "include_testme=true"    -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a1-4-u2410']" -e "include_testme=false"   -e "nodelete=false" -e "python_version_override=3.12"

--------------------------------------------------------------------------------------------------
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-1-u2004-6']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-1-u2004-6']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-2-u2204-5']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-2-u2204-5']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-3-u2404-1']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-3-u2404-1']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-4-u2410']" -e "include_testme=true"    -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-4-u2410']" -e "include_testme=true"    -e "nodelete=false" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-4-u2410']" -e "include_testme=false"   -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a2-4-u2410']" -e "include_testme=false"   -e "nodelete=false" -e "python_version_override=3.12"

--------------------------------------------------------------------------------------------------
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-1-u2004-6']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-1-u2004-6']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-2-u2204-5']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-2-u2204-5']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-3-u2404-1']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-3-u2404-1']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-4-u2410']" -e "include_testme=true"    -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-4-u2410']" -e "include_testme=true"    -e "nodelete=false" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-4-u2410']" -e "include_testme=false"   -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a3-4-u2410']" -e "include_testme=false"   -e "nodelete=false" -e "python_version_override=3.12"


time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a-big-u2410']" -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a-big-u2410']" -e "include_testme=true"  -e "nodelete=false" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a-big-u2410']" -e "include_testme=false" -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "target_vm=['kvm-a-big-u2410']" -e "include_testme=false" -e "nodelete=false" -e "python_version_override=3.12"

time ansible-playbook load_uvprog2025.yml -v -e "include_testme=true"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "include_testme=true"  -e "nodelete=false" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "include_testme=false"  -e "nodelete=true" -e "python_version_override=3.12"
time ansible-playbook load_uvprog2025.yml -v -e "include_testme=false"  -e "nodelete=false" -e "python_version_override=3.12"
```

--------------------------------------------------------------------------------------------------
### Available Options

| Option                    | Description                         | Default | Possible Values                             |
|---------------------------|-------------------------------------|---------|---------------------------------------------|
| `nodelete`                | Skip deleting existing repositories | `false` | `true`, `false`                             |
| `python_version_override` | Override default Python version     | (empty) | `3.11`, `3.12`                              |
| `target_vm`               | List of VMs to target | (all VMs)   | (empty) | List of VM names, e.g. `['kvm-a1-4-u2410']` |
| `include_testme`          | Include tests marked with 'testme'  | `true`  | `true`, `false`                             |

#### Concurrency Behavior

The playbooks include intelligent concurrency management:

- When `target_vm` is not specified: Tasks run on multiple VMs concurrently (up to 4 VMs at once)
- When `include_testme=true`: Tasks run on multiple VMs concurrently (up to concurrent_runs number of VMs at once)
- Otherwise: Tasks run on only one VM at a time for standard tests

This behavior allows for faster execution when targeting specific VMs or running testme tests, while providing more controlled execution for standard test runs.

#### Python Versions
- 3.11 (default for Ubuntu 20.04/22.04)
- 3.12 (default for Ubuntu 24.04/24.10)

#### Notes
- The `nodelete` and `python_version_override` options are primarily for the `load_uvprog2025.yml` playbook
- Both playbooks support targeting specific VMs and controlling testme test inclusion
- Python 3.10 may be available on some systems with the deadsnakes PPA but is not installed by default
- Using the `time` command before the playbook helps track execution duration
- The verbosity flag (`-v`) provides more detailed output during execution

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
