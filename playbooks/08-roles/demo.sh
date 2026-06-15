#!/bin/bash
# Module 08: Roles Demo (localhost-safe)
# Mirrors the workflow: syntax-check -> list-tasks -> dry run -> real run -> idempotency

set -e

echo "=================================================="
echo " Module 08: Roles"
echo "=================================================="
echo ""

echo "--- 1. Syntax check ---"
ansible-playbook role-demo.yml --syntax-check
echo ""

echo "--- 2. List tasks (what will run) ---"
ansible-playbook role-demo.yml --list-tasks
echo ""

echo "--- 3. Dry run with diff (no changes made) ---"
ansible-playbook role-demo.yml --check --diff
echo ""

echo "--- 4. Real run (role tasks + pre_tasks + post_tasks + handler) ---"
ansible-playbook role-demo.yml
echo ""

echo "--- 5. Run again to prove idempotency (changed=0) ---"
ansible-playbook role-demo.yml
echo ""

echo "--- 6. Override role defaults with extra vars ---"
ansible-playbook role-demo.yml -e "demo_app_name=OverriddenApp" -e "demo_version=3.0.0"
echo ""

echo "=================================================="
echo " Module 08 demo complete!"
echo "=================================================="
