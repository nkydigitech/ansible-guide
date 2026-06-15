#!/bin/bash
# Module 07: Handlers Demo (localhost-safe)

set -e

echo "=================================================="
echo " Module 07: Handlers"
echo "=================================================="
echo ""

echo "--- 1. Syntax check ---"
ansible-playbook handler-demo.yml --syntax-check
echo ""

echo "--- 2. List tasks (shows pre_tasks, role tasks, tasks, handlers) ---"
ansible-playbook handler-demo.yml --list-tasks
echo ""

echo "--- 3. Dry run (no changes, no handlers) ---"
ansible-playbook handler-demo.yml --check --diff
echo ""

echo "--- 4. First real run (handler fires ONCE at end) ---"
ansible-playbook handler-demo.yml
echo ""

echo "--- 5. Idempotent re-run (handler does NOT fire) ---"
ansible-playbook handler-demo.yml
echo ""

echo "--- 6. Exercises ---"
echo "Exercise 1 — handler fires on change only:"
ansible-playbook exercise-01/playbook.yml
echo ""

echo "Exercise 2 — flush_handlers:"
ansible-playbook exercise-02/playbook.yml
echo ""

echo "Exercise 3 — multiple handlers with listen:"
ansible-playbook exercise-03/playbook.yml
echo ""

echo "Exercise 4 — handler dependencies:"
ansible-playbook exercise-04/playbook.yml
echo ""

echo "Exercise 5 — changed_when suppresses handlers:"
ansible-playbook exercise-05/playbook.yml
echo ""

echo "=================================================="
echo " Module 07 demo complete!"
echo "=================================================="
