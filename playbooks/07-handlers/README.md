# Module 07: Handlers

Runnable companion code for [docs/07-handlers.md](../../docs/07-handlers.md).
This module teaches how to restart services only when configuration actually changes.

---

## Part A: Localhost-safe handler demo (run this first)

`handler-demo.yml` creates `/tmp/ansible-handler-demo/`, deploys a config, lets the handler fire at the end of the play, then modifies the config again and uses `meta: flush_handlers` to force an **immediate** restart.

No sudo. No packages. Works in Codespaces.

### Run the guided demo
```bash
cd playbooks/07-handlers
bash demo.sh
```

The demo shows:
- `--syntax-check` and `--list-tasks`
- `--check --diff` dry run (no handlers fire)
- First run: handler fires at end because config is new (`changed=2`, handler runs)
- Idempotent re-run: handler does **NOT** fire (`changed=0`)
- `meta: flush_handlers` forces the handler mid-play

### Try it yourself
```bash
cd playbooks/07-handlers
# First run — watch handler fire at the end
ansible-playbook handler-demo.yml

# Second run — nothing changed, handler stays silent
ansible-playbook handler-demo.yml

# Check the restart log
ls -la /tmp/ansible-handler-demo/restart.log
```

---

## Part B: Real server playbook (EC2)

`webserver-with-handlers.yml` installs nginx on Ubuntu via the `package` module, deploys a config, and uses a **real** handler to restart nginx. **Do not run against localhost.**

### Prerequisites
- Ubuntu EC2 instance (t3.micro)
- SSH key configured
- Inventory at `inventory/ec2.ini`

### Run
```bash
cd playbooks/07-handlers
ansible-playbook -i ../../inventory/ec2.ini webserver-with-handlers.yml --check --diff
ansible-playbook -i ../../inventory/ec2.ini webserver-with-handlers.yml
```

Browse to `http://<EC2_IP>` — edit the `copy` task, re-run, watch the handler fire.

---

## Part C: Exercise Playbooks

| # | File | What it teaches |
|---|------|-----------------|
| 1 | `exercise-01/` | Handler fires on change, stays silent on idempotency |
| 2 | `exercise-02/` | `meta: flush_handlers` runs handler mid-play |
| 3 | `exercise-03/` | `listen:` pattern triggers multiple handlers |
| 4 | `exercise-04/` | Handler dependencies — order matters |
| 5 | `exercise-05/` | `changed_when: false` suppresses handler notifications |

### Quick run
```bash
cd playbooks/07-handlers

ansible-playbook exercise-01/playbook.yml    # Run twice to see no handler on second run
ansible-playbook exercise-02/playbook.yml    # flush_handlers mid-play
ansible-playbook exercise-03/playbook.yml    # multiple handlers with listen
ansible-playbook exercise-04/playbook.yml    # handler order + dependencies
ansible-playbook exercise-05/playbook.yml    # changed_when suppresses handlers
```

---

## What to screenshot

1. **First run vs second run**
   - First: `changed=2`, handler debug message appears
   - Second: `changed=0`, no handler message — this is idempotency

2. **flush_handlers**
   - The handler fires **before** the final `stat` task, proving it ran mid-play

3. **Real server (EC2)**
   - `changed: [my-ec2]` on the config task
   - `RUNNING HANDLER [Restart nginx]`
   - Browser showing "Handler Demo Active" page
