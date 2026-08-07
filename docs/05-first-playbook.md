# Chapter 5: Your First Ansible Playbook

## Learning Objectives

By the end of this chapter, you will be able to:

- Understand the structure of an Ansible playbook
- Write a basic playbook with plays, tasks, and handlers
- Master YAML syntax fundamentals for Ansible
- Run playbooks using `ansible-playbook` with appropriate flags
- Use verbosity flags to debug playbook execution
- Perform dry-run and diff modes before making changes

## Explanation

### What Is a Playbook?

A playbook is a YAML file that defines a set of configuration and deployment steps for your infrastructure. Unlike ad-hoc commands (one-time operations), playbooks are:

- **Stored**: Saved to files that can be version-controlled
- **Repeatable**: Run the same playbook multiple times with identical results
- **Shareable**: Team members can use the same playbook
- **Documented**: The YAML itself describes what will happen

Think of a playbook as a recipe. Just as a recipe lists ingredients (variables) and steps (tasks), a playbook specifies what variables to use and what tasks to perform.

### Playbook Structure

A playbook is composed of one or more **plays**. Each play:

1. Targets a specific set of hosts (from inventory)
2. Defines variables for that play
3. Lists tasks to execute in order
4. May include handlers that respond to changes

```yaml
---
# Playbook with single play
- name: Play name (appears in output)
  hosts: webservers          # Which hosts this play targets
  become: yes                # Run as privileged user
  vars:                      # Variables for this play
    http_port: 80

  tasks:                     # List of tasks
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Start nginx service
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes

  handlers:                  # Respond to changes
    - name: Reload nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
```

### YAML Syntax Fundamentals

Ansible playbooks use YAML, which has specific syntax rules.

#### Indentation

YAML uses spaces for indentation—**not tabs**. Always use consistent spacing (typically 2 spaces per level):

```yaml
# Correct - uses spaces
tasks:
  - name: Install nginx
    apt:
      name: nginx

# Wrong - tabs will cause errors
tasks:
	- name: Install nginx
```

> **Pro Tip**: Configure your editor to use spaces instead of tabs. In VS Code, add to settings.json:
> ```json
> "editor.insertSpaces": true,
> "editor.tabSize": 2
> ```

#### Key-Value Pairs

Simple key-value pairs use colons:

```yaml
name: John
version: "1.0"
enabled: true
```

Strings don't always need quotes, but use them when:

- The string contains special characters (`:` `,` `{` `}` `[` `]` `-` `#`)
- The string might be misinterpreted as another type

```yaml
# These need quotes
message: "This: is a message with colon"
status: "OK"              # Without quotes, YAML might parse 'OK' as boolean

# These don't
name: nginx
path: /etc/nginx
```

#### Lists

Lists use dashes with spaces:

```yaml
# List of packages
packages:
  - nginx
  - vim
  - curl

# Inline notation (less common in Ansible)
packages: [nginx, vim, curl]
```

#### Dictionaries (Maps)

Dictionaries are key-value pairs indented together:

```yaml
# Full notation
nginx:
  name: nginx
  state: present
  enabled: yes

# Inline notation (flow style)
nginx: {name: nginx, state: present, enabled: yes}
```

#### Multi-Line Strings

Preserve formatting with `|` or fold with `>`:

```yaml
# Literal block (preserves newlines)
config: |
  line1
  line2
    indented

# Folded block (single newlines become spaces)
message: >
  This is a long message
  that spans multiple lines
  but appears as one paragraph.
```

#### Comments

Comments start with `#`:

```yaml
# This is a comment
- name: Install nginx
  # Another comment
  apt:
    name: nginx  # Inline comment
```

### Anatomy of a Task

Each task in a playbook follows this structure:

```yaml
tasks:
  - name: Descriptive task name       # Required: human-readable description
    module_name:                      # Module to use
      module_arg1: value1             # Module parameters
      module_arg2: value2

    # Alternative syntax (explicit module):
    - name: Task name
      ansible.builtin.{{ module_name }}:
        param1: value1
        param2: value2
```

The `name` field is displayed when the playbook runs, making it essential for debugging:

```
TASK [Install nginx] ****
ok: [webserver1]
```

Without names, you see just the module:
```
TASK [ansible.builtin.apt] ****
ok: [webserver1]
```

### Understanding Modules in Playbooks

Ansible modules accept arguments in two formats:

#### Keyword Arguments (most common)

```yaml
- name: Copy file
  ansible.builtin.copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
    mode: '0644'
```

#### String Arguments (for simple cases)

```yaml
- name: Run uptime command
  ansible.builtin.command: uptime
```

> **Pro Tip**: The `ansible.builtin.` prefix is optional for built-in modules. However, using it makes it clear where the module comes from and avoids conflicts with collection modules. For example, `ansible.builtin.apt` vs `community.general.apt`.

### Handlers: Responding to Changes

Handlers are special tasks that only run when triggered by a `notify` directive. They're typically used for actions that need to happen after a change:

```yaml
tasks:
  - name: Copy nginx configuration
    ansible.builtin.copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify:
      - Restart nginx

handlers:
  - name: Restart nginx
    ansible.builtin.service:
      name: nginx
      state: restarted
```

**Execution flow**:
1. Task detects the configuration file changed
2. Task triggers `notify: Restart nginx`
3. After all tasks complete, Ansible runs the handler
4. If the configuration didn't change, the handler doesn't run

**Important**: Handlers run in the order they're defined in the `handlers:` section, not the order they're notified. Use `listen` for more control:

```yaml
tasks:
  - name: Update nginx config
    ansible.builtin.copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify: "Reload services"

  - name: Update application config
    ansible.builtin.copy:
      src: app.conf
      dest: /etc/app.conf
    notify: "Reload services"

handlers:
  - name: Reload services
    listen: "Reload services"
    ansible.builtin.service:
      name: nginx
      state: reloaded
```

### Running Playbooks

The basic command:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

#### Common Options

```bash
# Check syntax only (don't run)
ansible-playbook playbook.yml --syntax-check

# List hosts that would be affected
ansible-playbook playbook.yml --list-hosts

# Run in check mode (dry run)
ansible-playbook playbook.yml --check

# Show differences (for files that would change)
ansible-playbook playbook.yml --diff

# Start at a specific task
ansible-playbook playbook.yml --start-at-task="Install nginx"

# Run specific tags only
ansible-playbook playbook.yml --tags="configuration"

# Skip specific tags
ansible-playbook playbook.yml --skip-tags="debug"

# Run with specific inventory
ansible-playbook playbook.yml -i inventory/production.ini

# Run as specific user
ansible-playbook playbook.yml -u ansible_user --become

# Specify become password
ansible-playbook playbook.yml --ask-become-pass
```

### Verbosity Levels

Increasing verbosity reveals more information:

```bash
# Normal output (-v is optional, shows task names)
ansible-playbook playbook.yml

# Detailed task results (-v)
ansible-playbook playbook.yml -v

# Module arguments (-vv)
ansible-playbook playbook.yml -vv

# Connection debugging (-vvv)
ansible-playbook playbook.yml -vvv

# Everything (-vvvv includes plugin execution)
ansible-playbook playbook.yml -vvvv
```

Typical output progression:

```bash
# Normal
TASK [Gathering Facts] ************************************************
ok: [webserver1]

# -v shows item details
TASK [Gathering Facts] ************************************************
ok: [webserver1] => {"ansible_facts": {...}}

# -vv shows module arguments
ok: [webserver1] => {"ansible_facts": {...}, "invocation": {"module_args": {...}}}
```

### Playbook Dry Run and Diff

The `--check` flag performs a dry run without making changes:

```bash
ansible-playbook playbook.yml --check
```

The `--diff` flag shows what would change:

```bash
ansible-playbook playbook.yml --diff
```

For files, diff shows line-by-line changes:
```diff
--- before:/etc/nginx/nginx.conf
+++ after:/etc/nginx/nginx.conf
@@ -1,3 +1,3 @@
 user nginx;
-worker_processes 4;
+worker_processes auto;
 error_log /var/log/nginx/error.log;
```

Combining both is the safest way to test changes:

```bash
ansible-playbook playbook.yml --check --diff
```

> **Pro Tip**: Always run `--check --diff` before modifying production systems. This gives you a preview of exactly what will change. However, some modules don't support check mode—Ansible will warn you and may execute anyway.

### Checking Playbook Syntax

Before running any playbook, verify its syntax:

```bash
# Syntax check
ansible-playbook playbook.yml --syntax-check

# List tasks without running
ansible-playbook playbook.yml --list-tasks

# List all hosts that match
ansible-playbook playbook.yml --list-hosts
```

### Understanding Playbook Output

A successful playbook run shows:

```bash
PLAY [Deploy web application] *************************************************

TASK [Gathering Facts] *********************************************************
ok: [webserver1]
ok: [webserver2]

TASK [Install nginx] ***********************************************************
ok: [webserver1]
changed: [webserver2]

TASK [Configure nginx] *********************************************************
ok: [webserver1]
changed: [webserver2]

PLAY RECAP *********************************************************************
webserver1                  : ok=3    changed=0    unreachable=0    failed=0
webserver2                  : ok=3    changed=1    unreachable=0    failed=0
```

Key elements:

- **`ok`**: Task ran successfully without making changes
- **`changed`**: Task made changes to the system
- **`unreachable`**: Could not connect to host
- **`failed`**: Task failed on this host

## Examples

### Example 1: Simple Nginx Installation Playbook

```yaml
---
# playbook.yml - Install and configure Nginx
- name: Install and start Nginx
  hosts: webservers
  become: yes
  vars:
    nginx_port: 80

  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Start Nginx service
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes

    - name: Verify Nginx is running
      ansible.builtin.uri:
        url: http://localhost:{{ nginx_port }}
        status_code: 200
```

### Example 2: Multi-Play Playbook

```yaml
---
# multi_play.yml - Configure entire infrastructure
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    app_user: webapp

  tasks:
    - name: Install web server packages
      ansible.builtin.apt:
        name:
          - nginx
          - python3
          - git
        state: present

    - name: Create application user
      ansible.builtin.user:
        name: "{{ app_user }}"
        shell: /bin/bash
        create_home: yes

- name: Configure database servers
  hosts: dbservers
  become: yes
  vars:
    app_user: webapp

  tasks:
    - name: Install PostgreSQL
      ansible.builtin.apt:
        name:
          - postgresql
          - postgresql-contrib
        state: present

    - name: Start PostgreSQL
      ansible.builtin.service:
        name: postgresql
        state: started
        enabled: yes

- name: Verify all servers are configured
  hosts: all
  tasks:
    - name: Check uptime
      ansible.builtin.command: uptime
      register: uptime_output

    - name: Display uptime
      ansible.builtin.debug:
        var: uptime_output.stdout
```

### Example 3: Playbook with Handlers

```yaml
---
# handlers_playbook.yml - Configuration changes with handler notification
- name: Deploy application with handlers
  hosts: webservers
  become: yes
  vars:
    app_dir: /opt/myapp
    app_port: 8080

  tasks:
    - name: Create application directory
      ansible.builtin.file:
        path: "{{ app_dir }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: Deploy application configuration
      ansible.builtin.copy:
        src: app.conf.j2
        dest: "{{ app_dir }}/config.conf"
        owner: www-data
        group: www-data
        mode: '0644'
      notify:
        - Restart application

    - name: Deploy main application file
      ansible.builtin.copy:
        src: app.py
        dest: "{{ app_dir }}/app.py"
        owner: www-data
        group: www-data
        mode: '0755'
      notify:
        - Restart application

  handlers:
    - name: Restart application
      ansible.builtin.systemd:
        name: myapp
        state: restarted
        enabled: yes
        daemon_reload: yes
```

### Example 4: Complete LEMP Stack Playbook

```yaml
---
# lemp_playbook.yml - Install LEMP stack (Linux, Nginx, MySQL, PHP)
- name: Install LEMP stack
  hosts: webservers
  become: yes
  vars:
    mysql_root_password: "changeme"
    nginx_server_name: "localhost"

  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Install MySQL
      ansible.builtin.apt:
        name:
          - mysql-server
          - python3-mysqldb
        state: present

    - name: Install PHP and extensions
      ansible.builtin.apt:
        name:
          - php-fpm
          - php-mysql
          - php-cli
        state: present

    - name: Start services
      ansible.builtin.service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - nginx
        - mysql

    - name: Configure Nginx
      ansible.builtin.template:
        src: nginx-site.conf.j2
        dest: /etc/nginx/sites-available/default
        mode: '0644'
      notify: Reload nginx

  handlers:
    - name: Reload nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded

    - name: Restart nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

### Example 5: Troubleshooting Playbook with Verbose Output

```yaml
---
# debug_playbook.yml - Demonstration of debugging techniques
- name: Debugging demonstration
  hosts: webservers
  gather_facts: yes

  tasks:
    - name: Get system information
      ansible.builtin.debug:
        msg: "Host: {{ ansible_facts['hostname'] }}, OS: {{ ansible_facts['distribution'] }}"

    - name: Check memory
      ansible.builtin.command: free -m
      register: memory_output

    - name: Display memory output
      ansible.builtin.debug:
        var: memory_output.stdout_lines

    - name: Conditional display
      ansible.builtin.debug:
        msg: "This system has less than 1GB RAM"
      when: ansible_facts['memtotal_mb'] < 1024

    - name: Fail deliberately for demonstration
      ansible.builtin.fail:
        msg: "This is a deliberate failure to demonstrate error handling"
      ignore_errors: yes

    - name: This task runs because ignore_errors is yes
      ansible.builtin.debug:
        msg: "We continued despite the previous failure"
```

## Hands-On Exercises

### Exercise 1: Write Your First Playbook

**Objective**: Create a playbook that installs Vim on your test hosts.

**Expected Outcome**: A playbook file that installs Vim and can be run successfully.

**Instructions**:
1. Create a file `install_vim.yml`
2. Add a play targeting your test hosts
3. Include a task using the `apt` module to install `vim`
4. Run the playbook: `ansible-playbook -i inventory.ini install_vim.yml`

**Hint**: Use `become: yes` for system packages. If using CentOS/RHEL, change `apt` to `yum`.

---

### Exercise 2: Add Multiple Tasks to Your Playbook

**Objective**: Expand your playbook to perform multiple related tasks.

**Expected Outcome**: A playbook that creates a user, installs a package, and starts a service.

**Instructions**:
1. Create a playbook that:
   - Creates a user named `webadmin`
   - Installs `nginx`
   - Starts the nginx service
   - Enables nginx to start at boot
2. Run with `--check` first to verify syntax
3. Run for real
4. Verify the service is running

**Hint**: Use `ansible.builtin.service` with `state: started` and `enabled: yes`.

---

### Exercise 3: Create a Playbook with Handlers

**Objective**: Create a playbook that uses handlers to respond to configuration changes.

**Expected Outcome**: A playbook with configuration tasks that trigger handler notifications.

**Instructions**:
1. Create a playbook that:
   - Installs nginx
   - Copies a custom nginx configuration file (use a simple template or static file)
   - Notifies the "Restart nginx" handler on config change
2. Create a simple nginx.conf file in a `files/` directory
3. Run the playbook, verify it runs successfully
4. Modify the nginx.conf file, run the playbook again
5. Confirm the handler runs (should show "changed" and "RUNNING HANDLER")

**Hint**: Handlers only run if a task reports "changed". If the config file is identical, no notification triggers.

---

### Exercise 4: Explore Verbose Output

**Objective**: Learn to use verbosity levels for debugging playbooks.

**Expected Outcome**: Understand the differences between -v, -vv, -vvv, -vvvv outputs.

**Instructions**:
1. Create a simple playbook with a few tasks
2. Run with `-v` and observe output
3. Run with `-vv` and compare
4. Run with `-vvv` and identify connection debugging info
5. Run with `-vvvv` and examine the detailed information

**Hint**: Focus on understanding what additional information each level provides. For production debugging, `-vvv` is usually sufficient.

---

### Exercise 5: Use Check Mode and Diff

**Objective**: Practice safe playbook execution with dry-run modes.

**Expected Outcome**: Successfully preview changes without modifying systems.

**Instructions**:
1. Create a playbook that modifies a file
2. Run with `--check --diff` to preview changes
3. Review the diff output
4. Run without flags to actually make changes
5. Run again with `--check` — should show no changes needed

**Hint**: The `--check` mode might not work for all modules. Some modules (like `service`) require actual system state to determine changes.

## Summary

- Playbooks are YAML files that define repeatable automation workflows
- A playbook contains plays, each targeting hosts and containing tasks
- YAML syntax requires spaces (not tabs), proper indentation, and correct data structures
- Tasks are the basic unit of work, using modules with named arguments
- Handlers respond to changes via `notify` and run after all tasks complete
- Run playbooks with `ansible-playbook -i inventory playbook.yml`
- Use `--syntax-check`, `--list-hosts`, and `--list-tasks` before running
- Verbosity flags (`-v` through `-vvvv`) reveal progressively more debugging information
- Always use `--check --diff` before modifying production systems
- The play recap shows `ok`, `changed`, `unreachable`, and `failed` counts per host

## Additional Resources

1. **Ansible Playbooks Documentation**: https://docs.ansible.com/ansible/latest/playbook_guide/index.html
   Complete guide to playbook writing, including advanced features and best practices.

2. **YAML Syntax Reference**: https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html
   Official Ansible documentation on YAML syntax specific to Ansible usage.

3. **Ansible Playbook Best Practices**: https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html
   Community-curated best practices for organizing playbooks, handling errors, and maximizing reusability.


 ```md
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../04-inventory/" style="color:#8892b0; text-decoration:none;">← Previous: Inventory</a>
  <a href="../06-variables/" style="background:#6c63ff; color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:600;">Next: Variables →</a>
</div>
```
  
