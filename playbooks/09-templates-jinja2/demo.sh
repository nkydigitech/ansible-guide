#!/bin/bash
# Module 09: Templates & Jinja2 Demo (localhost-safe)

set -e

echo "=================================================="
echo " Module 09: Templates & Jinja2"
echo "=================================================="
echo ""

echo "--- 1. Syntax check ---"
ansible-playbook template-demo.yml --syntax-check
echo ""

echo "--- 2. List tasks ---"
ansible-playbook template-demo.yml --list-tasks
echo ""

echo "--- 3. Dry run ---"
ansible-playbook template-demo.yml --check --diff
echo ""

echo "--- 4. Real run (renders template to /tmp) ---"
ansible-playbook template-demo.yml
echo ""

echo "--- 5. Show rendered file ---"
cat /tmp/ansible-template-demo/app_config.conf
echo ""

echo "--- 6. Exercises ---"
ansible-playbook exercise-01/playbook.yml
echo ""
ansible-playbook exercise-02/playbook.yml
echo ""
ansible-playbook exercise-03/playbook.yml
echo ""
ansible-playbook exercise-04/playbook.yml
echo ""
ansible-playbook exercise-05/playbook.yml
echo ""

echo "=================================================="
echo " Module 09 demo complete!"
echo "=================================================="
