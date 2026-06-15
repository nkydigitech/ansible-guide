# Chapter 6: Variables

## Learning Objectives

By the end of this chapter, you will be able to:

- Understand what Ansible variables are and why they make playbooks flexible and reusable
- Learn the 22 levels of variable precedence (simplified to the ones you will encounter most)
- Define variables in playbooks, inventory files, `group_vars/`, `host_vars/`, and via command line
- Use magic variables and registered variables to capture and reuse task output
- Apply variable syntax correctly inside templates and task arguments

## Explanation

In this chapter, you will learn how to use variables to make your playbooks smarter and more flexible. By the end, you will know how to store values, reuse them across tasks, and handle situations where variables might not be defined. Let's get started!

Variables are the backbone of flexible Ansible playbooks. As you learned in Chapter 5, a playbook maps tasks to hosts. Variables let you customize settings so the same playbook can target different environments (dev, staging, production) without rewriting it.

Think of a variable as a labeled box. You write a label on the box (that's the variable name), put something inside (that's the value), and later you can open the box to get what you stored. When Ansible runs, it looks up the label, finds the value inside, and uses that value in your tasks.

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
      ansible.builtin.package:
        name: nginx
        state: present

    - name: Configure nginx port
      ansible.builtin.lineinfile:
        path: /etc/nginx/nginx.conf
        regexp: "^listen"
        line: "listen {{ http_port }};"
```

In this example, `app_version`, `http_port`, and `enabled` are variables defined at the play level. The task `Configure nginx port` references `{{ http_port }}` — Ansible substitutes `8080` when it runs.

### Variable Precedence (Simplified)

**Variable precedence** means the order in which Ansible decides which value to use when the same variable is defined in multiple places. Think of it like a tie-breaker: if you set `http_port` in two different locations, which one wins? Ansible has 22 levels of precedence to handle this.

The general rule is: **the most specific source wins**. Here are the precedence levels you will encounter most, ordered from lowest to highest priority:

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

**Group variables** (stored in the `group_vars/` folder) let you define variables once for an entire group of servers. **Host variables** (stored in the `host_vars/` folder) let you set variables for a single specific server.

Ansible looks for variable files in these directories at the same level as your inventory file. This approach keeps your inventory file clean and is the recommended way to manage environment-specific variables.

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

**Extra vars** (short for "extra variables") are variables you pass directly on the command line when running a playbook. They have the highest precedence of all variable sources, which means they always win — useful for one-off overrides.

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

**Magic variables** are built-in variables that Ansible automatically provides. You do not need to define them — they are always available and contain useful information about your inventory and the current execution context.

| Variable | Description |
|---|---|
| `hostvars` | Access variables for all hosts in the inventory |
| `groups` | Dictionary of all groups in the inventory (group names mapped to lists of hosts) |
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
      ansible.builtin.debug:
        msg: "Configuring {{ inventory_hostname }}"

    - name: Check memory on this host
      ansible.builtin.debug:
        msg: "Memory: {{ ansible_facts['memtotal_mb'] }} MB"
```

Example using `hostvars` to reference another host's variable:

```yaml
- name: Configure load balancer
  hosts: loadbalancers
  tasks:
    - name: Get webserver IP from hostvars
      ansible.builtin.debug:
        msg: "Backend server: {{ hostvars['web01.example.com']['ansible_facts']['default_ipv4']['address'] }}"
```

> **Pro Tip**: `ansible_facts` are gathered automatically at the start of every play (unless you set `gather_facts: no`). These facts contain a wealth of information about your target hosts — OS version, CPU count, network interfaces, mounted disks, and much more. Always run with facts gathering enabled unless you have a specific reason not to (it adds a small amount of time but saves huge debugging effort).

> **Note**: To use `hostvars` to access another host's `ansible_facts`, those facts must have been gathered in a previous play (or via fact caching). If Ansible has not yet gathered facts for the target host, the `ansible_facts` key will be empty or undefined.

### Registered Variables

**Register** is a keyword that captures the output of a task and stores it in a variable. When a task runs, it produces a result (success/failure, output, whether it made changes). You can capture that result using `register` and then use it in subsequent tasks.

```yaml
- name: Check disk space
  hosts: webservers
  tasks:
    - name: Get disk usage
      ansible.builtin.command: df -h
      register: disk_output

    - name: Display disk usage
      ansible.builtin.debug:
        var: disk_output.stdout_lines

    - name: Alert if /dev/sda1 is nearly full
      ansible.builtin.debug:
        msg: "Disk usage is high!"
      when: disk_output.stdout is search('/dev/sda1')
```

A registered variable contains the entire result object, not just the output. The object includes:

- `stdout` — standard output as a string
- `stdout_lines` — standard output as a list (one line per element)
- `stderr` — standard error as a string
- `rc` — return code (0 usually means success)
- `changed` — boolean indicating whether the task made changes

### Variable Syntax in Detail

Ansible uses **Jinja2** (a templating language) for variable expressions. You write variables inside double curly braces `{{ variable_name }}`, and Ansible replaces them with the actual value when the playbook runs.

Inside a Jinja2 expression, the variable evaluates to its value. But you can also use filters (covered in Chapter 9) and tests:

```yaml
# Basic variable substitution
msg: "Running {{ app_version }}"

# With a filter (uppercase)
msg: "Server {{ inventory_hostname }} is {{ ansible_facts['distribution'] | upper }}"

# With a default value (if the variable is undefined)
msg: "Config path: {{ config_path | default('/etc/myapp.conf') }}"

# Quoting: always quote the entire expression when it starts a string
# WRONG (unquoted): line: {{ http_port }} is the port   # YAML sees it as a key: value pair
# RIGHT (quoted): line: "{{ http_port }} is the port"  # Ansible substitutes the value
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
      ansible.builtin.file:
        path: "{{ app_path }}"
        state: directory
        owner: www-data
        mode: '0755'

    - name: Deploy application files
      ansible.builtin.copy:
        src: files/myapp/
        dest: "{{ app_path }}/"
```

Run against dev: `ansible-playbook site.yml`

```bash
PLAY [Deploy application to dev environment] *********************************

TASK [Gathering Facts] *********************************************************
ok: [webserver1]

TASK [Create application directory] *******************************************
changed: [webserver1]

TASK [Deploy application files] ***********************************************
changed: [webserver1]

PLAY RECAP *********************************************************************
webserver1                  : ok=3    changed=2    unreachable=0    failed=0
```

Run against prod: `ansible-playbook site.yml -e "env=prod"`

```bash
PLAY [Deploy application to prod environment] *********************************

TASK [Gathering Facts] *********************************************************
ok: [webserver1]

TASK [Create application directory] *******************************************
changed: [webserver1]

TASK [Deploy application files] ***********************************************
changed: [webserver1]

PLAY RECAP *********************************************************************
webserver1                  : ok=3    changed=2    unreachable=0    failed=0
```

### Example 2: Registered Variable for Conditional Restart

```yaml
# configure-db.yml
---
- name: Configure PostgreSQL
  hosts: databases
  vars:
    max_db_connections: 100
    shared_buffers: 256MB
  tasks:
    - name: Update postgresql.conf
      ansible.builtin.lineinfile:
        path: /etc/postgresql/14/main/postgresql.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: "^max_connections", line: "max_connections = {{ max_db_connections }}" }
        - { regexp: "^shared_buffers", line: "shared_buffers = {{ shared_buffers }}" }
      register: pg_conf_changed

    - name: Restart PostgreSQL
      ansible.builtin.service:
        name: postgresql
        state: restarted
      when: pg_conf_changed is changed

    - name: Verify PostgreSQL is running
      ansible.builtin.service:
        name: postgresql
        state: started
        enabled: yes
```

### Example 3: Hostvars to Build a Hosts File

**set_fact** is a module that creates a new variable and sets its value. Unlike registered variables (which capture task output), `set_fact` lets you build up custom variables from existing data.

```yaml
# generate-hosts-file.yml
---
- name: Generate /etc/hosts entries
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Build hosts file content
      ansible.builtin.set_fact:
        hosts_content: |
          127.0.0.1 localhost
          ::1 localhost ip6-localhost ip6-loopback

    - name: Add all inventory hosts
      ansible.builtin.set_fact:
        hosts_content: "{{ hosts_content }}\n{{ hostvars[item]['ansible_facts']['default_ipv4']['address'] }} {{ item }}"
      loop: "{{ groups['all'] }}"
      when: hostvars[item]['ansible_facts']['default_ipv4'] is defined

    - name: Write hosts file
      ansible.builtin.copy:
        content: "{{ hosts_content }}\n"
        dest: /tmp/hosts-generated
```

## Hands-On Exercises

### Exercise 1: Variable Precedence Demo

**Objective**: Demonstrate that extra vars override everything, and play-level vars override role defaults.

**Instructions**:
1. Create a role scaffold: `ansible-galaxy init --init-path roles demo-role`
2. In `roles/demo-role/defaults/main.yml`, set: `message: "from defaults"`
3. In `roles/demo-role/tasks/main.yml`, add a task: `debug: msg: "{{ message }}"`
4. Create a playbook that applies the role and also sets `vars: { message: "from play" }`
5. Run the playbook and observe: `ansible-playbook test-precedence.yml`

```bash
PLAY [Test variable precedence] ***********************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [demo-role : debug] ******************************************************
ok: [localhost] => {
    "msg": "from play"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0
```

6. Now run with `ansible-playbook test-precedence.yml -e 'message="from extra vars"'`

```bash
PLAY [Test variable precedence] ***********************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [demo-role : debug] ******************************************************
ok: [localhost] => {
    "msg": "from extra vars"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0
```
7. Observe the different outputs based on precedence.

**Expected Outcome**: First run prints "from play", second run prints "from extra vars".

**Hint**: Use `ansible-playbook -v` for more detail on which value Ansible resolved for each variable.

---

### Exercise 2: Inventory Variables and group_vars

**Objective**: Use group_vars to configure different settings for dev vs. prod environments.

**Instructions**:
1. Create an inventory file with two groups: `dev_servers` and `prod_servers`, each with one host.
2. Create `group_vars/dev_servers.yml` with `deploy_env: dev` and `log_level: debug`
3. Create `group_vars/prod_servers.yml` with `deploy_env: prod` and `log_level: error`
4. Create `group_vars/all.yml` with `app_name: mywebapp`
5. Write a playbook that targets both groups and uses `debug` to display all three variables.
6. Run the playbook with `-l dev_servers` and observe which values are resolved.

```bash
PLAY [Configure servers] ******************************************************

TASK [Gathering Facts] *********************************************************
ok: [devserver1]

TASK [Display environment configuration] ***************************************
ok: [devserver1] => {
    "msg": "Environment: dev, Log Level: debug, App: mywebapp"
}

PLAY RECAP *********************************************************************
devserver1                 : ok=2    changed=0    unreachable=0    failed=0
```

**Expected Outcome**: When targeting `dev_servers`, `deploy_env=dev`, `log_level=debug`, `app_name=mywebapp`. When targeting `prod_servers`, `deploy_env=prod`, `log_level=error`, `app_name=mywebapp`.


**Hint**: Variables from `all.yml` apply to every host. The more specific group variable (dev_servers vs all) takes precedence for the same key.

---

### Exercise 3: Register and Reuse Task Output

**Objective**: Capture command output and use it in a subsequent task.

**Instructions**:
1. Create a playbook targeting `localhost`.
2. Run `date` command and register the output as `current_date`.
3. Register the output of `whoami` as `current_user`.
4. Use a `debug` task to display both: "Current date: [date], running as: [user]"

```bash
PLAY [System information] *****************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Get current date] ********************************************************
changed: [localhost]

TASK [Get current user] ********************************************************
changed: [localhost]

TASK [Display system information] *********************************************
ok: [localhost] => {
    "msg": "Current date: Thu Jun 13 10:30:45 UTC 2026, running as: nkydigitech"
}

TASK [Security check] **********************************************************
ok: [localhost] => {
    "msg": "Running with elevated privileges"
}

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=2    unreachable=0    failed=0
```

5. Add a conditional: only show a message if the user is `root` or `nkydigitech`.

**Expected Outcome**: The playbook runs successfully on your current user, displaying the current date and username. If run as a different user, the conditional message is suppressed.


**Hint**: Registered variables contain `.stdout`, `.stdout_lines`, `.stderr`, and `.rc`. Use `.stdout_lines` for line-based output and `.stdout` for the full string.

---

### Exercise 4: Magic Variables with hostvars

**Objective**: Use `hostvars` and `groups` to dynamically reference other hosts.

**Instructions**:
1. Create an inventory with at least 2 hosts in the `webservers` group.
2. In a playbook, target `localhost` (or one webserver).
3. Use `debug` to print:
   - A list of all hosts in the `webservers` group
   - The `ansible_facts['hostname']` of each webserver (using `hostvars[item]`)
4. Use a loop over `groups['webservers']` to print each host's memory.

```bash
PLAY [Display webserver information] ******************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [List all webservers] *****************************************************
ok: [localhost] => {
    "msg": "Webservers group: ['web01.example.com', 'web02.example.com']"
}

TASK [Display hostnames] ********************************************************
ok: [localhost] => {
    "msg": "web01.example.com hostname: web01"
}
ok: [localhost] => {
    "msg": "web02.example.com hostname: web02"
}

TASK [Display memory for each webserver] ***************************************
ok: [localhost] => {
    "msg": "web01.example.com memory: 2048 MB"
}
ok: [localhost] => {
    "msg": "web02.example.com memory: 4096 MB"
}

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=0    unreachable=0    failed=0
```

**Expected Outcome**: The playbook outputs information about all webservers, even though the play only targets one host. This demonstrates that `hostvars` lets you query facts from hosts not currently running in the play.


**Hint**: When looping over `groups['webservers']`, each `item` is a hostname string. Use `hostvars[item]` to access that host's variables and facts.

---

### Exercise 5: Default Values with Jinja2 Filters

**Objective**: Handle undefined variables gracefully using the `default` filter.

**Instructions**:
1. Create a playbook with a task that references a variable `db_port` that is NOT defined anywhere.
2. Run the playbook and observe the error.

```bash
PLAY [Test undefined variable] ************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Connect to database] *****************************************************
fatal: [localhost]: FAILED! => {"msg": "The task includes an option to use the undefined variable db_port"}

PLAY RECAP *********************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=1    skipped=0
```
3. Now modify the task to use `{{ db_port | default(5432) }}`.
4. Run again — the task should succeed, using `5432`.

```bash
PLAY [Test default filter] ****************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Connect to database] *****************************************************
ok: [localhost] => {
    "msg": "Connecting to database on port 5432"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0
```
5. Override `db_port` via `-e "db_port=5433"` and verify the override wins.

```bash
PLAY [Test default filter] ****************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [Connect to database] *****************************************************
ok: [localhost] => {
    "msg": "Connecting to database on port 5433"
}

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0
```

**Expected Outcome**: First run succeeds with default 5432. Second run uses override 5433. This pattern is essential for writing playbooks that work across environments where some variables may not be defined.


**Hint**: The `default` filter is one of the most used Jinja2 filters in Ansible. Always use it for variables that might not be defined in all environments.

## Summary

- Ansible variables let you customize playbooks using variables, making them reusable across environments and hosts.
- Variable precedence determines which value wins when the same variable is defined in multiple places.
- Variables can be defined in playbooks, inventory, `group_vars/`, `host_vars/`, and via `--extra-vars`.
- Magic variables (`hostvars`, `groups`, `inventory_hostname`, `ansible_facts`) are always available.
- Registered variables capture task results for use in subsequent tasks.
- Always quote expressions starting with `{{` to avoid YAML parsing errors.
- Use the `default` filter to handle undefined variables gracefully.

## Additional Resources

1. **Ansible Documentation: Variables**: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html
   Official documentation covering all variable topics.

2. **Ansible Documentation: Understanding Variable Precedence**: https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html#setting-different-values-for-different-hosts
   Explains the 22 levels with practical examples.

3. **Ansible by Red Hat — Variables Deep Dive (Blog)**: https://www.ansible.com/blog/ansible-best-practices-variables
   Real-world patterns for managing variables at scale.