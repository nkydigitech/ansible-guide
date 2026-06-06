# Chapter 6: Variables

## Learning Objectives

- Understand what Ansible variables are and why they make playbooks flexible and reusable
- Learn the 17 levels of variable precedence (simplified to the ones you will encounter most)
- Define variables in playbooks, inventory files, `group_vars/`, `host_vars/`, and via command line
- Use magic variables and registered variables to capture and reuse task output
- Apply variable syntax correctly inside templates and task arguments

## Explanation

Variables are the backbone of flexible Ansible playbooks. As you learned in Chapter 5, a playbook maps tasks to hosts. Variables let you parameterize those tasks so the same playbook can target different environments (dev, staging, production) without rewriting it.

Think of a variable as a named container that holds a value. You define it once and reference it everywhere. When Ansible runs, it resolves variables to their actual values before executing tasks.

### Defining Variables in a Playbook

The most common way to define variables is directly inside a play using the `vars` keyword:

```yaml
---
- name: Configure web server
  hosts: webservers
  vars:
    app_version: "2.1.0"
    http_port: 8080
    enabled: true
  tasks:
    - name: Install nginx
      package:
        name: nginx
        state: present

    - name: Configure nginx port
      lineinfile:
        path: /etc/nginx/nginx.conf
        regexp: "^listen"
        line: "listen {{ http_port }};"
```

In this example, `app_version`, `http_port`, and `enabled` are variables defined at the play level. The task `Configure nginx port` references `{{ http_port }}` — Ansible substitutes `8080` when it runs.

### Variable Precedence (Simplified)

Ansible has 17 levels of variable precedence. The general rule is: **the most specific source wins**. Here are the precedence levels you will encounter most, ordered from lowest to highest priority:

1. **Role defaults** (`roles/myrole/defaults/main.yml`) — lowest, meant to be overridden
2. **Inventory vars** (from your inventory file, defined at group or host level)
3. **Group variables** (`group_vars/` directory)
4. **Host variables** (`host_vars/` directory)
5. **Play vars** (variables defined directly in the play with `vars:`)
6. **Play vars_files** (`vars_files:` directive)
7. **Register variables** (variables captured from task output with `register`)
8. **Extra vars** (`-e` or `--extra-vars` on the command line) — highest priority

> **Pro Tip**: In production, you will often use `group_vars/` and `host_vars/` for environment-specific configuration and `extra_vars` for one-off overrides at runtime. Remember that extra vars always win — this is useful for emergency overrides but can be dangerous if used carelessly.

### Inventory Variables

Variables can be defined directly in your inventory file. Recall from Chapter 4 that we had groups and hosts. You can attach variables to them:

```ini
# inventory/hosts
[webservers]
web01.example.com http_port=8080
web02.example.com http_port=9090

[webservers:vars]
nginx_version="1.18.0"
```

In YAML inventory format:

```yaml
---
all:
  children:
    webservers:
      hosts:
        web01.example.com:
          http_port: 8080
        web02.example.com:
          http_port: 9090
      vars:
        nginx_version: "1.18.0"
```

### group_vars/ and host_vars/

Ansible looks for variable files in the `group_vars/` and `host_vars/` directories at the same level as your inventory file. This approach keeps your inventory file clean and is the recommended way to manage environment-specific variables.

```bash
inventory/
├── hosts
├── group_vars/
│   ├── all.yml          # Variables for ALL groups
│   ├── webservers.yml   # Variables for webservers group
│   └── databases.yml    # Variables for databases group
└── host_vars/
    ├── web01.example.com.yml
    └── web02.example.com.yml
```

```yaml
# inventory/group_vars/webservers.yml
---
nginx_version: "1.18.0"
app_user: www-data
max_connections: 2048
```

```yaml
# inventory/host_vars/web01.example.com.yml
---
http_port: 8080
server_name: web01.example.com
```

### Extra Variables (`--extra-vars`)

You can override any variable at runtime using the `-e` or `--extra-vars` flag:

```bash
ansible-playbook site.yml -e "http_port=9000 env=production"
```

You can also pass a YAML or JSON file:

```bash
ansible-playbook site.yml -e @vars/override.yml
```

```yaml
# vars/override.yml
---
http_port: 9000
env: production
```

> **Pro Tip**: Using `-e @file.yml` is common in CI/CD pipelines where you generate an override file from secrets management (like HashiCorp Vault, AWS Secrets Manager, or CyberArk) before running your playbook.

### Magic Variables

Ansible provides built-in "magic" variables that are always available:

| Variable | Description |
|---|---|
| `hostvars` | Access variables for all hosts in the inventory |
| `groups` | List of all groups in the inventory |
| `inventory_hostname` | The hostname of the current host as defined in inventory |
| `ansible_facts` | Discovered facts about the current host (CPU, memory, OS, etc.) |
| `play_hosts` | List of hosts in the current play (excluding those limited out) |
| `role_names` | List of role names applied to the current host |

Example using `inventory_hostname`:

```yaml
- name: Configure per-host settings
  hosts: webservers
  tasks:
    - name: Display the current host
      debug:
        msg: "Configuring {{ inventory_hostname }}"

    - name: Check memory on this host
      debug:
        msg: "Memory: {{ ansible_facts['memtotal_mb'] }} MB"
```

Example using `hostvars` to reference another host's variable:

```yaml
- name: Configure load balancer
  hosts: loadbalancers
  tasks:
    - name: Get webserver IP from hostvars
      debug:
        msg: "Backend server: {{ hostvars['web01.example.com']['ansible_facts']['default_ipv4']['address'] }}"
```

> **Pro Tip**: `ansible_facts` are gathered automatically at the start of every play (unless you set `gather_facts: no`). These facts contain a wealth of information about your target hosts — OS version, CPU count, network interfaces, mounted disks, and much more. Always run with facts gathering enabled unless you have a specific reason not to (it adds a small amount of time but saves huge debugging effort).

### Registered Variables

When a task runs, it produces a result. You can capture that result using `register` and then use it in subsequent tasks:

```yaml
- name: Check disk space
  hosts: webservers
  tasks:
    - name: Get disk usage
      command: df -h
      register: disk_output

    - name: Display disk usage
      debug:
        var: disk_output.stdout_lines

    - name: Alert if disk is nearly full
      debug:
        msg: "Disk usage is high!"
      when: disk_output.stdout_lines[0] is search('Use%') == false
```

A registered variable contains the entire result object, not just the output. The object includes:

- `stdout` — standard output as a string
- `stdout_lines` — standard output as a list (one line per element)
- `stderr` — standard error as a string
- `rc` — return code (0 usually means success)
- `changed` — boolean indicating whether the task made changes

### Variable Syntax in Detail

Inside a Jinja2 expression (`{{ }}`), the variable evaluates to its value. But you can also use filters (covered in Chapter 9) and tests:

```yaml
# Basic variable substitution
msg: "Running {{ app_version }}"

# With a filter (uppercase)
msg: "Server {{ inventory_hostname }} is {{ ansible_facts['distribution'] | upper }}"

# With a default value (if the variable is undefined)
msg: "Config path: {{ config_path | default('/etc/myapp.conf') }}"

# Quoting: always quote the entire expression when it starts a string
# WRONG:  line: "{{ http_port }} is the port"   # Jinja2 sees ":8080 is the port" as dict syntax
# RIGHT: line: "'{{ http_port }}' is the port"
```

> **Pro Tip**: Always quote task arguments that start with `{{` to prevent YAML from misinterpreting the curly braces. Ansible will warn you if you forget, but getting in the habit of quoting prevents confusing errors.

## Examples

### Example 1: Multi-Environment Deployment

```yaml
# site.yml
---
- name: Deploy application to {{ env }} environment
  hosts: webservers
  vars:
    env: dev
    app_path: /opt/myapp
  tasks:
    - name: Create application directory
      file:
        path: "{{ app_path }}"
        state: directory
        owner: www-data
        mode: '0755'

    - name: Deploy application files
      copy:
        src: files/myapp/
        dest: "{{ app_path }}/"
```

Run against dev: `ansible-playbook site.yml`
Run against prod: `ansible-playbook site.yml -e "env=prod"`

### Example 2: Registered Variable for Conditional Restart

```yaml
# configure-db.yml
---
- name: Configure PostgreSQL
  hosts: databases
  tasks:
    - name: Update postgresql.conf
      lineinfile:
        path: /etc/postgresql/14/main/postgresql.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: "^max_connections", line: "max_connections = {{ max_db_connections }}" }
        - { regexp: "^shared_buffers", line: "shared_buffers = {{ shared_buffers }}" }
      register: pg_conf_changed

    - name: Restart PostgreSQL
      service:
        name: postgresql
        state: restarted
      when: pg_conf_changed is changed

    - name: Verify PostgreSQL is running
      service:
        name: postgresql
        state: started
      enabled: true
```

### Example 3: Hostvars to Build a Hosts File

```yaml
# generate-hosts-file.yml
---
- name: Generate /etc/hosts entries
  hosts: localhost
  gather_facts: no
  vars:
    all_hosts: "{{ groups['all'] }}"
  tasks:
    - name: Build hosts file content
      set_fact:
        hosts_content: |
          127.0.0.1 localhost
          ::1 localhost ip6-localhost ip6-loopback

    - name: Add all inventory hosts
      set_fact:
        hosts_content: "{{ hosts_content }}\n{{ hostvars[item]['ansible_facts']['default_ipv4']['address'] }} {{ item }}"
      loop: "{{ groups['all'] }}"
      when: hostvars[item]['ansible_facts']['default_ipv4'] is defined

    - name: Write hosts file
      copy:
        content: "{{ hosts_content }}\n"
        dest: /tmp/hosts-generated
```

## Hands-On Exercises

### Exercise 1: Variable Precedence Demo
**Goal**: Demonstrate that extra vars override everything, and play-level vars override role defaults.

1. Create a role scaffold: `ansible-galaxy init --init-path roles/demo-role roles/demo-role`
2. In `roles/demo-role/defaults/main.yml`, set: `message: "from defaults"`
3. In `roles/demo-role/tasks/main.yml`, add a task: `debug: msg: "{{ message }}"`
4. Create a playbook that applies the role and also sets `vars: { message: "from play" }`
5. Run the playbook and observe: `ansible-playbook test-precedence.yml`
6. Now run with `ansible-playbook test-precedence.yml -e "message=from extra vars"`
7. Observe the different outputs based on precedence.

**Expected outcome**: First run prints "from play", second run prints "from extra vars".

**Hint**: Use `ansible-playbook -v` for more detail on which value Ansible resolved for each variable.

---

### Exercise 2: Inventory Variables and group_vars
**Goal**: Use group_vars to configure different settings for dev vs. prod environments.

1. Create an inventory file with two groups: `dev_servers` and `prod_servers`, each with one host.
2. Create `group_vars/dev_servers.yml` with `environment: dev` and `log_level: debug`
3. Create `group_vars/prod_servers.yml` with `environment: prod` and `log_level: error`
4. Create `group_vars/all.yml` with `app_name: mywebapp`
5. Write a playbook that targets both groups and uses `debug` to display all three variables.
6. Run the playbook with `-l dev_servers` and observe which values are resolved.

**Expected outcome**: When targeting `dev_servers`, `environment=dev`, `log_level=debug`, `app_name=mywebapp`. When targeting `prod_servers`, `environment=prod`, `log_level=error`, `app_name=mywebapp`.

**Hint**: Variables from `all.yml` apply to every group. The more specific group variable (dev_servers vs all) takes precedence for the same key.

---

### Exercise 3: Register and Reuse Task Output
**Goal**: Capture command output and use it in a subsequent task.

1. Create a playbook targeting `localhost`.
2. Run `date` command and register the output as `current_date`.
3. Register the output of `whoami` as `current_user`.
4. Use a `debug` task to display both: "Current date: [date], running as: [user]"
5. Add a conditional: only show a message if the user is `root` or `nkydigitech`.

**Expected outcome**: The playbook runs successfully on your current user, displaying the current date and username. If run as a different user, the conditional message is suppressed.

**Hint**: Registered variables contain `.stdout`, `.stdout_lines`, `.stderr`, and `.rc`. Use `.stdout_lines` for line-based output and `.stdout` for the full string.

---

### Exercise 4: Magic Variables with hostvars
**Goal**: Use `hostvars` and `groups` to dynamically reference other hosts.

1. Create an inventory with at least 2 hosts in the `webservers` group.
2. In a playbook, target `localhost` (or one webserver).
3. Use `debug` to print:
   - A list of all hosts in the `webservers` group
   - The `ansible_facts['hostname']` of each webserver (using `hostvars[item]`)
4. Use a loop over `groups['webservers']` to print each host's memory.

**Expected outcome**: The playbook outputs information about all webservers, even though the play only targets one host. This demonstrates that `hostvars` lets you query facts from hosts not currently running in the play.

**Hint**: When looping over `groups['webservers']`, each `item` is a hostname string. Use `hostvars[item]` to access that host's variables and facts.

---

### Exercise 5: Default Values with Jinja2 Filters
**Goal**: Handle undefined variables gracefully using the `default` filter.

1. Create a playbook with a task that references a variable `db_port` that is NOT defined anywhere.
2. Run the playbook and observe the error.
3. Now modify the task to use `{{ db_port | default(5432) }}`.
4. Run again — the task should succeed, using `5432`.
5. Override `db_port` via `-e "db_port=5433"` and verify the override wins.

**Expected outcome**: First run succeeds with default 5432. Second run uses override 5433. This pattern is essential for writing playbooks that work across environments where some variables may not be defined.

**Hint**: The `default` filter is one of the most used Jinja2 filters in Ansible. Always use it for variables that might not be defined in all environments.

## Summary

- Ansible variables let you parameterize playbooks, making them reusable across environments and hosts.
- Variable precedence determines which value wins when the same variable is defined in multiple places.
- Variables can be defined in playbooks, inventory, `group_vars/`, `host_vars/`, and via `--extra-vars`.
- Magic variables (`hostvars`, `groups`, `inventory_hostname`, `ansible_facts`) are always available.
- Registered variables capture task results for use in subsequent tasks.
- Always quote expressions starting with `{{` to avoid YAML parsing errors.
- Use the `default` filter to handle undefined variables gracefully.

## Additional Resources

- [Ansible Documentation: Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html) — Official documentation covering all variable topics.
- [Ansible Documentation: Understanding Variable Precedence](https://docs.ansible.com/ansible/latest/tips_tricks.html#setting-different-values-for-different-hosts) — Explains the 17 levels with practical examples.
- [Ansible by Red Hat — Variables Deep Dive (Blog)](https://www.ansible.com/blog/ansible-best-practices-variables) — Real-world patterns for managing variables at scale.