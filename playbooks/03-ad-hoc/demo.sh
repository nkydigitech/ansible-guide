#!/bin/bash
# Module 03: Ad-hoc Commands Demo
# Run this script to see all ad-hoc command examples in action

INVENTORY="-i ../../inventory/hosts.ini"

echo "=================================================="
echo " Module 03: Ansible Ad-hoc Commands"
echo "=================================================="
echo ""

echo "--- 1. Ping all hosts ---"
ansible all $INVENTORY -m ping
echo ""

echo "--- 2. Check uptime ---"
ansible all $INVENTORY -m command -a "uptime"
echo ""

echo "--- 3. Check disk space ---"
ansible all $INVENTORY -m command -a "df -h"
echo ""

echo "--- 4. Check free memory ---"
ansible all $INVENTORY -m command -a "free -m"
echo ""

echo "--- 5. Gather facts (just OS info) ---"
ansible all $INVENTORY -m setup -a "filter=ansible_distribution*"
echo ""

echo "--- 6. Create a test file ---"
ansible all $INVENTORY -m file -a "path=/tmp/ansible-test.txt state=touch"
echo ""

echo "--- 7. Write content to file ---"
ansible all $INVENTORY -m copy -a "content='Hello from Ansible ad-hoc!' dest=/tmp/ansible-test.txt"
echo ""

echo "--- 8. Read the file back ---"
ansible all $INVENTORY -m command -a "cat /tmp/ansible-test.txt"
echo ""

echo "--- 9. Delete the test file ---"
ansible all $INVENTORY -m file -a "path=/tmp/ansible-test.txt state=absent"
echo ""

echo "=================================================="
echo " All ad-hoc demos complete!"
echo "=================================================="
