# Module 03: Ansible Ad-Hoc Commands

## What Are Ad-Hoc Commands?
Ad-hoc commands let you run a single Ansible task directly from the terminal — no playbook needed.
Use them for quick, one-off tasks like checking connectivity, gathering facts, or managing files.

## Syntax
```bash
ansible <host-pattern> -i <inventory> -m <module> -a "<arguments>"
```

| Part | Meaning |
|------|---------|
| `<host-pattern>` | Target hosts: `all`, `webservers`, `localhost` |
| `-i` | Path to your inventory file |
| `-m` | Module to use (ping, command, copy, file, setup) |
| `-a` | Arguments passed to the module |

---

## Understanding the Output

### SUCCESS vs CHANGED
- **`SUCCESS`** + `"changed": false` → Task ran, nothing was modified (e.g., ping)
- **`CHANGED`** + `"changed": true` → Task ran and modified something (e.g., created a file)

---

## Commands Demonstrated

### 1. Ping — Test Connectivity
```bash
ansible all -i inventory/hosts.ini -m ping
```
> Verifies Ansible can reach the host. Returns `pong` on success.

### 2. Check Uptime
```bash
ansible all -i inventory/hosts.ini -m command -a "uptime"
```
> Runs a shell command. Note: `command` module does NOT support pipes (`|`) or redirects (`>`).

### 3. Gather Facts (Filtered)
```bash
ansible all -i inventory/hosts.ini -m setup -a "filter=ansible_distribution*"
```
> Collects system info. Use `filter=` to narrow results. Useful for conditionals in playbooks.

### 4. Create a File
```bash
ansible all -i inventory/hosts.ini -m file -a "path=/tmp/ansible-test.txt state=touch"
```
> `state=touch` creates an empty file. Other states: `absent` (delete), `directory` (create dir).

### 5. Write Content to a File
```bash
ansible all -i inventory/hosts.ini -m copy -a "content='Hello from Ansible!' dest=/tmp/ansible-test.txt"
```
> The `copy` module is **idempotent** — running it twice won't create duplicates.

### 6. Delete a File
```bash
ansible all -i inventory/hosts.ini -m file -a "path=/tmp/ansible-test.txt state=absent"
```

---

## Key Concepts to Remember

| Concept | Explanation |
|---------|-------------|
| **Idempotency** | Running the same command multiple times gives the same result |
| **`command` vs `shell`** | Use `shell` when you need pipes (`\|`) or redirects (`>`) |
| **Inventory** | Without `-i`, Ansible only sees implicit `localhost` (you'll see a WARNING) |
| **Modules** | Ansible's building blocks — each does one specific job safely |

---

## Run the Demo
```bash
cd playbooks/03-ad-hoc
bash demo.sh
```

