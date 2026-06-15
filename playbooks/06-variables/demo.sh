#!/bin/bash
# Module 06: Variables Demo (localhost-safe)
# Mirrors the workflow taught in docs/06-variables.md:
#   syntax-check -> list-tasks -> dry run (--check --diff) -> real run -> idempotency

set -e
INVENTORY="-i ../../inventory/hosts.ini"
PLAY="variables-demo.yml"

echo "=================================================="
echo " Module 06: Variables"
echo "=================================================="
echo ""

echo "--- 1. Syntax check ---"
ansible-playbook $INVENTORY $PLAY --syntax-check
echo ""

echo "--- 2. List tasks (what will run) ---"
ansible-playbook $INVENTORY $PLAY --list-tasks
echo ""

echo "--- 3. Dry run with diff (no changes made) ---"
ansible-playbook $INVENTORY $PLAY --check --diff
echo ""

echo "--- 4. Real run (creates dir + file, shows variables) ---"
ansible-playbook $INVENTORY $PLAY
echo ""

echo "--- 5. Run again to prove idempotency (changed should be 0) ---"
ansible-playbook $INVENTORY $PLAY
echo ""

echo "--- 6. Run with extra vars to show override ---"
ansible-playbook $INVENTORY $PLAY -e "demo_version=2.0.0"
echo ""

echo "=================================================="
echo " Module 06 demo complete!"
echo "=================================================="
