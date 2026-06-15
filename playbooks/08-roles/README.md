# Module 08: Roles

Runnable companion code for [docs/08-roles.md](../../docs/08-roles.md).
This module shows how to organize playbooks into reusable, shareable roles.

---

## Part A: Localhost-safe role demo (run this first)

`role-demo.yml` uses `demo-role` to create `/tmp/ansible-role-demo/`, deploys a templated config, copies a static file, and fires a handler. No sudo, no package installs.

It also shows **`pre_tasks`**, **`post_tasks`**, and **handler execution order**.

### Run the guided demo
```bash
cd playbooks/08-roles
bash demo.sh
```

The demo walks through: `--syntax-check` → `--list-tasks` → `--check --diff` (dry run) → real run → idempotency re-run (`changed=0`) → extra-vars override.

### Try extra vars yourself
```bash
cd playbooks/08-roles
# Default values
ansible-playbook role-demo.yml

# Override role defaults at runtime
ansible-playbook role-demo.yml -e "demo_app_name=OverriddenApp" -e "demo_version=3.0.0"
```

Watch the debug output: the first run shows defaults, the second run shows overrides.

---

## Part B: Real server playbook (EC2)

`webserver-with-role.yml` deploys nginx on a remote Ubuntu host via the `ec2-web` role.
**Do not run against localhost** — it needs sudo and a real package manager.

### Cost warning (read before launching EC2)
AWS Free Tier covers **750 hours/month of a `t2.micro`/`t3.micro` for 12 months**.

### 1. Launch an EC2 instance
- Ubuntu Server LTS, instance type `t3.micro`.
- Create/download a key pair (`ansible-key.pem`), `chmod 400 ansible-key.pem`.
- Security group: allow SSH (22) from your IP, and HTTP (80) from anywhere.

### 2. Create EC2 inventory
```ini
[webservers]
my-ec2 ansible_host=<EC2_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/ansible-key.pem

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### 3. Verify connectivity
```bash
ansible -i inventory/ec2.ini webservers -m ping
```

### 4. Preview, then apply
```bash
cd playbooks/08-roles
ansible-playbook -i ../../inventory/ec2.ini webserver-with-role.yml --check --diff
ansible-playbook -i ../../inventory/ec2.ini webserver-with-role.yml
```

### 5. See the result
Open `http://<EC2_PUBLIC_IP>/` in your browser. You should see the role-driven landing page with the title and color defined in the playbook vars.

### 6. Experiment with roles
Edit the `vars:` block in `webserver-with-role.yml` to change `page_title` or `page_color`, then re-run. The handler restarts nginx only when the page actually changes.

---

## Part C: Exercise Playbooks

Five self-contained exercises. Each matches a hands-on exercise from [docs/08-roles.md](../../docs/08-roles.md).

| # | File / Directory | What it teaches |
|---|------------------|-----------------|
| 1 | `exercise-01-create-role/` | Create a role from scratch (tasks, handlers, templates) |
| 2 | `exercise-02-dependencies/` | Role dependencies via `meta/main.yml` |
| 3 | `exercise-03-galaxy/` | Use a Galaxy-style role locally |
| 4 | `exercise-04-pretasks/` | Execution order: pre_tasks → roles → tasks → post_tasks |
| 5 | `exercise-05-refactor/` | Refactor a monolithic playbook into a role |

### Quick run (all exercises)
```bash
cd playbooks/08-roles

# Exercise 1 — create a role
ansible-playbook exercise-01-create-role/playbook.yml

# Exercise 2 — role dependencies (common auto-runs before app-role)
ansible-playbook exercise-02-dependencies/playbook.yml

# Exercise 3 — use a Galaxy-style role
ansible-playbook exercise-03-galaxy/playbook.yml

# Exercise 4 — execution order
ansible-playbook exercise-04-pretasks/playbook.yml

# Exercise 5A — before refactor (monolithic)
ansible-playbook exercise-05-refactor/monolithic.yml

# Exercise 5B — after refactor (using role)
ansible-playbook exercise-05-refactor/playbook.yml
```

---

## What to screenshot

1. **Demo script output**
   - The `demo.sh` banner showing syntax check and list-tasks
   - The `--check --diff` dry run showing `changed=0`
   - The real run showing `changed=2` (directory + template)
   - The idempotency re-run showing `changed=0`
   - The extra-vars run showing overridden variables

2. **Role directory structure**
   - `tree playbooks/08-roles/roles/demo-role/` showing the standard Galaxy layout

3. **Real server (EC2)**
   - The live Nginx page in your browser showing the role-driven title and color.
   - The Ansible output showing the handler restarting nginx.
