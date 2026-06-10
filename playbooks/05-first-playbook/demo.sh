#!/bin/bash
# Module 05: First Playbook Demo (localhost-safe)
# Mirrors the workflow taught in docs/05-first-playbook.md:
#   syntax-check -> list-tasks -> dry run (--check --diff) -> real run -> idempotency

set -e
INVENTORY="-i ../../inventory/hosts.ini"
PLAY="first-playbook.yml"

echo "=================================================="
echo " Module 05: Your First Playbook"
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

echo "--- 4. Real run (creates dir + config, fires handler) ---"
ansible-playbook $INVENTORY $PLAY
echo ""

echo "--- 5. Run again to prove idempotency (changed should be 0) ---"
ansible-playbook $INVENTORY $PLAY
echo ""

echo "=================================================="
echo " Module 05 demo complete!"
echo "=================================================="
