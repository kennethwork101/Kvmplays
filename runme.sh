#!/bin/bash
#
time ansible-playbook load_uvprog2025.yml -i inventory/inventory_big.ini -v -e "target_vm=['kvm-a-big-u2204-5']"
time ansible-playbook load_uvprog2025.yml -i inventory/inventory_big.ini -v -e "target_vm=['kvm-a-big-u2404-1']"
time ansible-playbook load_uvprog2025.yml -i inventory/inventory_big.ini -v -e "target_vm=['kvm-a-big-u2410']"
time ansible-playbook load_uvprog2025.yml -i inventory/inventory_big.ini -v
time ansible-playbook load_uvprog2025.yml -i inventory/inventory_big.ini -v -e "target_vm=['kvm-a-big-u2410']" -e "include_testme=false"
