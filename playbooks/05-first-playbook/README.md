# Module 05: Your First Ansible Playbook

Runnable companion code for [docs/05-first-playbook.md](../../docs/05-first-playbook.md).
There are two playbooks: one that is **safe to run on localhost** (great for screenshots),
and one that targets a **real server** (e.g. a free-tier EC2 instance).

---

## Part A: Localhost-safe playbook (run this first)

`first-playbook.yml` creates a directory under `/tmp`, copies a config file, reads it back,
and fires a handler. No sudo, no package installs, so it always works in Codespaces.

### Run the guided demo
```bash
cd playbooks/05-first-playbook
bash demo.sh
```

The demo walks through the real workflow: `--syntax-check`, `--list-tasks`,
`--check --diff` (dry run), the real run, then a second run to prove **idempotency**
(the second run should report `changed=0`).

### See a handler fire on change
1. Edit `files/sample.conf` (change `max_connections = 100` to `200`).
2. Run `ansible-playbook -i ../../inventory/hosts.ini first-playbook.yml`.
3. The copy task reports `changed`, and the **handler runs**. Run once more: no change, no handler.

---

## Part B: Real server playbook (EC2)

`webserver.yml` installs and starts Nginx on a remote Ubuntu host. **Do not run this against
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
cd playbooks/05-first-playbook
ansible-playbook -i ../../inventory/ec2.ini webserver.yml --check --diff   # preview
ansible-playbook -i ../../inventory/ec2.ini webserver.yml                  # apply
```

### 5. See the result
Open `http://<EC2_PUBLIC_IP>/` in your browser. You should see the
"Deployed by Ansible" page. **Then terminate the instance to avoid charges.**

---

## What to screenshot for clients
- The `demo.sh` output showing the dry run and the `changed=0` idempotent re-run.
- The handler firing after you edit `sample.conf`.
- The live Nginx page served from your EC2 instance.
