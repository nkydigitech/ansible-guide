# Module 06: Variables

Runnable companion code for [docs/06-variables.md](../../docs/06-variables.md).
There are two playbooks: one that is **safe to run on localhost** (great for screenshots),
and one that targets a **real server** (e.g. a free-tier EC2 instance).

---

## Part A: Localhost-safe playbook (run this first)

`variables-demo.yml` creates a directory under `/tmp`, deploys a config file driven
by variables, reads it back, and shows extra vars overriding play-level vars.
No sudo, no package installs, so it always works in Codespaces.

### Run the guided demo
```bash
cd playbooks/06-variables
bash demo.sh
```

The demo walks through the real workflow: `--syntax-check`, `--list-tasks`,
`--check --diff` (dry run), the real run, a second run to prove **idempotency**
(`changed=0`), then an extra-vars run to show **overrides**.

### Try extra vars yourself
```bash
cd playbooks/06-variables
# Default version is 1.0.0
ansible-playbook -i ../../inventory/hosts.ini variables-demo.yml

# Override the version variable at runtime
ansible-playbook -i ../../inventory/hosts.ini variables-demo.yml -e "demo_version=2.0.0"
```

Watch the debug output: the first run shows `Version: 1.0.0`. The second run shows
`Version: 2.0.0` because extra vars have the highest precedence.

---

## Part B: Real server playbook (EC2)

`webserver-with-vars.yml` installs Nginx on a remote Ubuntu host and deploys a
landing page whose title and color are controlled by variables. **Do not run this against
your Codespace localhost** (it needs sudo and a real package manager).

### Cost warning (read before launching EC2)
AWS Free Tier covers **750 hours/month of a `t2.micro`/`t3.micro` for 12 months**. To stay free:
- Launch **one** `t3.micro` (or `t2.micro`) with the Ubuntu AMI.
- **Stop or terminate** the instance when you finish.
- Do not attach an unused Elastic IP, and keep storage at the default 8 GB.

### 1. Launch an EC2 instance
- Ubuntu Server LTS, instance type `t3.micro`.
- Create/download a key pair (e.g. `ansible-key.pem`), `chmod 400 ansible-key.pem`.
- Security group: allow SSH (22) from your IP, and HTTP (80) from anywhere (to view the page).

### 2. Create the EC2 inventory
Create `inventory/ec2.ini` in the repo root (do NOT commit real IPs/keys):
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
cd playbooks/06-variables
ansible-playbook -i ../../inventory/ec2.ini webserver-with-vars.yml --check --diff   # preview
ansible-playbook -i ../../inventory/ec2.ini webserver-with-vars.yml                  # apply
```

### 5. See the result
Open `http://<EC2_PUBLIC_IP>/` in your browser. You should see the
variable-driven landing page with the title and color defined in the playbook.
**Then terminate the instance to avoid charges.**

### 6. Experiment with variables
Edit the `vars:` block in `webserver-with-vars.yml` to change `page_title` or
`page_color`, then run the playbook again. Watch Nginx restart only when the
page actually changes (handlers in action).

---

## Part C: Exercise Playbooks

Five self-contained exercise playbooks live in this directory. Each matches one
hands-on exercise from [docs/06-variables.md](../../docs/06-variables.md). Run them
in order:

| # | File | What it teaches |
|---|------|-----------------|
| 1 | `exercise-01-precedence.yml` | Extra vars beat play vars, which beat role defaults |
| 2 | `exercise-02-group-vars.yml` | Different settings per environment using `group_vars/` |
| 3 | `exercise-03-register.yml` | Capturing and reusing task output |
| 4 | `exercise-04-hostvars.yml` | Accessing facts from other hosts |
| 5 | `exercise-05-defaults.yml` | Graceful handling of missing variables |

### Quick run (all exercises)
```bash
cd playbooks/06-variables

# Exercise 1 — default vs override
ansible-playbook -i ../../inventory/hosts.ini exercise-01-precedence.yml
ansible-playbook -i ../../inventory/hosts.ini exercise-01-precedence.yml -e 'demo_message="from extra vars"'

# Exercise 2 — dev environment
ansible-playbook -i exercise-02/inventory/hosts exercise-02-group-vars.yml -l dev_servers

# Exercise 3 — register output
ansible-playbook -i ../../inventory/hosts.ini exercise-03-register.yml

# Exercise 4 — hostvars
ansible-playbook -i exercise-04/inventory/hosts exercise-04-hostvars.yml

# Exercise 5 — default filter
ansible-playbook -i ../../inventory/hosts.ini exercise-05-defaults.yml
ansible-playbook -i ../../inventory/hosts.ini exercise-05-defaults.yml -e "db_port=5433"
```

---

## What to screenshot

### 1. Demo script output
- The `demo.sh` banner showing `--- 1. Syntax check ---`
- The `--list-tasks` output showing all 6 tasks
- The `--check --diff` dry run showing `changed=0`
- The real run showing `changed=2` (directory + file created)
- The idempotency re-run showing `changed=0`
- The extra-vars run showing `Version: 2.0.0` and `changed=1` (file updated)

### 2. Variable override demonstration
- Run `variables-demo.yml` with no extra vars: debug shows `Version: 1.0.0`
- Run with `-e "demo_version=2.0.0"`: debug shows `Version: 2.0.0`
- This proves that **extra vars override play-level vars**

### 3. Real server (EC2)
- The live Nginx page in your browser showing the variable-driven title and color.
- The Ansible output showing the handler restarting nginx.
- The `uri` task reporting `status: 200` (proves the site is live).
