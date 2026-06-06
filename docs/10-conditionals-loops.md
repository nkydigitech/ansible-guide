# Chapter 10: Conditionals and Loops

## Learning Objectives

- Use the `when` clause to run tasks conditionally based on variables and facts
- Apply Jinja2 tests (`is defined`, `is not defined`, `is directory`, etc.) in `when` conditions
- Replace `with_items` with the modern `loop` keyword for iterating over lists
- Use `loop_control` to customize loop behavior (`label`, `index_var`, `extended`)
- Combine loops with conditionals to process subsets of data
- Use `block`, `rescue`, and `always` to group tasks and handle errors structurally
- Apply `run_once` to control task execution across hosts

## Explanation

Static playbooks that do the same thing every time are useful for simple setups, but real infrastructure automation requires **dynamic behavior** — running different tasks on different operating systems, processing lists of items, handling errors gracefully, and adapting to the state discovered on each host. Conditionals and loops are the two primary mechanisms for adding this dynamism.

As you learned in earlier chapters, Ansible is fundamentally a configuration management tool — it evaluates the state of each target and decides what actions are needed. Conditionals and loops give you fine-grained control over which actions run and how many times.

### Conditionals with `when`

The `when` clause is Ansible's primary conditional mechanism. It accepts a Jinja2 expression that evaluates to `true` or `false`. If `true`, the task runs; if `false`, the task is skipped.

```yaml
- name: Install Apache on Debian
  apt:
    name: apache2
    state: present
  when: ansible_os_family == "Debian"

- name: Install Apache on RHEL
  yum:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"
```

The `when` clause can use any Jinja2 expression, including:
- Comparisons: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Boolean logic: `and`, `or`, `not`
- Tests: `is defined`, `is not defined`, `is true`, `is false`

```yaml
# Multiple conditions
- name: Restart nginx if port changed and service is running
  service:
    name: nginx
    state: restarted
  when:
    - nginx_port_changed | bool
    - nginx_service_state == "running"

# OR conditions
- name: Install on Debian or Ubuntu
  apt:
    name: curl
    state: present
  when: ansible_distribution in ["Debian", "Ubuntu"]

# Negation
- name: Skip if maintenance mode is on
  debug:
    msg: "Skipping because maintenance mode is enabled"
  when: not maintenance_mode | bool
```

### Jinja2 Tests

Jinja2 tests are predicates that return `true` or `false`. Ansible's `when` clause supports all standard Jinja2 tests plus Ansible-specific ones:

```yaml
# is defined / is not defined
- name: Create database only if db_name is defined
  postgresql_db:
    name: "{{ db_name }}"
  when: db_name is defined

- name: Skip if optional_variable is missing
  debug:
    msg: "{{ optional_variable }}"
  when: optional_variable is not defined

# is truthy / is falsey
- name: Enable feature flag
  include_tasks: feature.yml
  when: feature_enabled is truthy

# is sameas (identity comparison)
- name: Check if value is exactly None
  debug:
    msg: "Value is None"
  when: my_value is none

# Jinja2 type tests
- name: Check if value is a string
  debug:
    msg: "It's a string"
  when: my_value is string

- name: Check if value is a number
  debug:
    msg: "It's a number"
  when: my_value is number
```

### Loops with `loop`

The `loop` keyword (introduced in Ansible 2.5) replaces the older `with_items` and similar directives. It is more consistent with Ansible's plugin architecture and is the recommended approach.

```yaml
# Basic loop
- name: Install multiple packages
  package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - curl
    - git
    - vim
```

In loops, `{{ item }}` holds the current element. For loops over dictionaries or complex objects, access properties with dot notation:

```yaml
# Loop over list of dicts
- name: Create users
  user:
    name: "{{ item.name }}"
    shell: "{{ item.shell }}"
    home: "{{ item.home }}"
  loop:
    - { name: alice, shell: /bin/bash, home: /home/alice }
    - { name: bob, shell: /bin/zsh, home: /home/bob }
    - { name: service, shell: /bin/false, home: /opt/service }
```

### loop_control

The `loop_control` directive customizes loop behavior:

```yaml
# Using label for readable output
- name: Create application directories
  file:
    path: "{{ item.path }}"
    state: directory
    owner: "{{ item.owner }}"
    group: "{{ item.group }}"
    mode: '0755'
  loop:
    - { path: /opt/myapp, owner: app, group: app }
    - { path: /var/log/myapp, owner: app, group: app }
    - { path: /var/data/myapp, owner: app, group: app }
  loop_control:
    label: "{{ item.path }}"   # Shows just the path in ansible output
```

```yaml
# Using index_var to track position
- name: Add entries to config file
  lineinfile:
    path: /etc/myapp.conf
    line: "server {{ item }}:{{ port }}"
    insertafter: "^server "
  loop: "{{ server_list }}"
  loop_control:
    index_var: idx
```

```yaml
# Using extended for loop metadata
- name: Process queue items
  debug:
    msg: "Item {{ item }} at index {{ ansible_loop.index }} of {{ ansible_loop.depth }}"
  loop: "{{ queue_items }}"
  loop_control:
    extended: yes
```

When `extended: yes`, Ansible sets these additional variables:
- `ansible_loop.index` — 1-based position in the loop
- `ansible_loop.index0` — 0-based position
- `ansible_loop.first` — `true` if first iteration
- `ansible_loop.last` — `true` if last iteration
- `ansible_loop.length` — total number of items
- `ansible_loop.depth` — nesting level (1 for top-level loop)
- `ansible_loop.previtem` — previous item in the loop
- `ansible_loop.nextitem` — next item in the loop

### Loop Filters

Ansible provides `map` and `select`/`reject` filters to transform and filter loop lists:

```yaml
# map: extract a property from a list of dicts
- name: Get all usernames
  debug:
    msg: "{{ item }}"
  loop: "{{ users | map(attribute='name') | list }}"

# select/reject: filter list by condition
- name: Install only RedHat family packages
  package:
    name: "{{ item }}"
    state: present
  loop: "{{ all_packages | select('search', 'tools') | list }}"
```

### Combining Loops and Conditionals

You can combine `loop` and `when` — the condition is evaluated for each item:

```yaml
- name: Install web server packages
  package:
    name: "{{ item.name }}"
    state: present
  loop: "{{ packages }}"
  when: item.install | bool   # Only install if item.install is true
  vars:
    packages:
      - { name: nginx, install: true }
      - { name: apache2, install: false }
      - { name: lighttpd, install: true }
      - { name: caddy, install: false }
```

This is very powerful: the same task iterates over all packages, but only actually installs those with `install: true`.

### Block, Rescue, and Always

`block` groups tasks together and applies a common condition or error handling strategy. This is one of Ansible's most powerful organizational features.

```yaml
- name: Deploy application with rollback
  hosts: webservers
  become: true
  tasks:
    - name: Block: Deploy new version
      block:
        - name: Backup current version
          shell: cp -r /opt/myapp /opt/myapp.backup

        - name: Deploy new version
          synchronize:
            src: ./build/
            dest: /opt/myapp/
            delete: yes

        - name: Run database migrations
          command: /opt/myapp/bin/migrate

        - name: Restart application
          systemd:
            name: myapp
            state: restarted

      when: deploy_version is defined

      rescue:
        - name: Restore from backup on failure
          shell: cp -r /opt/myapp.backup /opt/myapp
          when: deploy_version is defined

        - name: Notify on rollback
          debug:
            msg: "Deployment failed, backup restored"

      always:
        - name: Always log deployment attempt
          shell: echo "$(date) - Deployment attempted for {{ inventory_hostname }}" >> /var/log/deploy.log
```

In this structure:
- **block**: Tasks that attempt the primary operation. If all succeed, `rescue` is skipped.
- **rescue**: Tasks that run only if the block failed. Use this for rollback/cleanup.
- **always**: Tasks that run regardless of whether block succeeded or failed. Use for cleanup, notifications, or logging.

> **Pro Tip**: `block` is not just for error handling. It is also the recommended way to apply a `when` condition to multiple tasks at once — instead of repeating the same `when` on every task, wrap them in a block and put the `when` on the block itself.

### run_once

By default, a task runs on every host in the current play's host pattern. Use `run_once: yes` to make a task run on only one host:

```yaml
- name: Initialize database schema (run once)
  command: /opt/myapp/bin/init-db
  run_once: true
```

This is useful for operations that only need to happen once per cluster (e.g., database initialization, leader election setup).

Be careful: if the `run_once` task fails, you may need `ignore_errors` or error-handling blocks to prevent the entire play from failing when other hosts still need configuration.

### `with_fileglob`

This loop iterator matches files in the local `files/` directory (or a specified path) and iterates over their names:

```yaml
- name: Copy all configuration files
  copy:
    src: "{{ item }}"
    dest: "/etc/myapp/{{ item | basename }}"
    mode: '0644'
  with_fileglob:
    - files/configs/*
```

### `with_dict`

Iterate over a dictionary's key-value pairs:

```yaml
- name: Set facts from dictionary
  set_fact:
    "{{ item.key }}": "{{ item.value }}"
  loop: "{{ query('dict', my_dictionary) }}"
```

### `with_sequence`

Generate a numeric sequence:

```yaml
- name: Create numbered directories
  file:
    path: "/tmp/dir{{ item }}"
    state: directory
  with_sequence: start=1 end=10 format=%02d
  # Creates: dir01, dir02, ..., dir10
```

## Examples

### Example 1: OS-Dependent Package Installation

```yaml
---
- name: Configure application servers
  hosts: all
  become: true
  tasks:
    - name: Install common packages
      package:
        name: "{{ item }}"
        state: present
      loop:
        - curl
        - wget
        - vim

    - name: Install OS-specific packages
      package:
        name: "{{ item.name }}"
        state: present
      loop:
        - { name: apache2, family: Debian }
        - { name: httpd, family: RedHat }
        - { name: nginx, family: Suse }
      when: ansible_os_family == item.family

    - name: Install development tools (Debian only)
      package:
        name:
          - gcc
          - build-essential
          - python3-dev
        state: present
      when: ansible_os_family == "Debian"

    - name: Install development tools (RHEL only)
      package:
        name:
          - gcc
          - gcc-c++
          - python3-devel
        state: present
      when: ansible_os_family == "RedHat"
```

### Example 2: Loop with Conditionals for User Management

```yaml
---
- name: Manage application users
  hosts: localhost
  gather_facts: no
  vars:
    app_users:
      - name: alice
        system: false
        groups: [developers, docker]
        shell: /bin/bash
      - name: bob
        system: false
        groups: [qa]
        shell: /bin/zsh
      - name: service_app
        system: true
        groups: []
        shell: /bin/false
      - name: deploy_bot
        system: true
        groups: [deployment]
        shell: /bin/bash
  tasks:
    - name: Create system users
      user:
        name: "{{ item.name }}"
        shell: "{{ item.shell }}"
        system: "{{ item.system }}"
        groups: "{{ item.groups | join(',') if item.groups else omit }}"
        create_home: yes
        comment: "Application user: {{ item.name }}"
      loop: "{{ app_users }}"
      when: item.system | bool

    - name: Create regular users
      user:
        name: "{{ item.name }}"
        shell: "{{ item.shell }}"
        system: no
        groups: "{{ item.groups | join(',') if item.groups else omit }}"
        create_home: yes
        password: "{{ lookup('password', '/dev/null length=32 chars=ascii_letters,digits') | password_hash('sha512') }}"
      loop: "{{ app_users }}"
      when: not (item.system | bool)
```

### Example 3: Block/Rescue for Database Migration

```yaml
---
- name: Deploy application with database migration safety
  hosts: webservers
  become: true
  vars:
    db_migration_timeout: 300
  tasks:
    - name: Block: Application deployment with migration
      block:
        - name: Create database backup
          shell: pg_dump myapp > /backups/myapp-$(date +%Y%m%d-%H%M%S).sql

        - name: Run database migrations
          command: /opt/myapp/bin/migrate --timeout {{ db_migration_timeout }}
          register: migration_result

        - name: Deploy application code
          synchronize:
            src: ./build/
            dest: /opt/myapp/
            delete: yes

        - name: Restart application
          systemd:
            name: myapp
            state: restarted

      rescue:
        - name: Migration failed — notify DBA team
          debug:
            msg: "Database migration failed. DBA team notified. Migration output: {{ migration_result.stdout }}"

        - name: Ensure application is in healthy state
          systemd:
            name: myapp
            state: started

        - name: Revert to previous code version
          synchronize:
            src: ./build-previous/
            dest: /opt/myapp/
            delete: yes

      always:
        - name: Log deployment attempt
          lineinfile:
            path: /var/log/deployments.log
            line: "[{{ ansible_date_time.iso8601 }}] {{ inventory_hostname }} - {{ 'success' if migration_result is succeeded else 'failed' }}"
            create: yes
            mode: '0644'
```

## Hands-On Exercises

### Exercise 1: Conditional Task Execution Based on Facts
**Goal**: Write a playbook that adapts its tasks based on discovered host facts.

1. Create a playbook targeting `localhost`.
2. Add tasks that use `ansible_facts` to:
   - Print the OS distribution and version
   - Print the total memory
   - Print the CPU core count
3. Use `when` to:
   - Only create `/tmp/debian-welcome` if the OS is Debian/Ubuntu
   - Only create `/tmp/rhel-welcome` if the OS is RedHat/CentOS
   - Only print "Low memory warning" if memory is less than 1GB
4. Run with `ansible-playbook --check` first to see what would happen, then for real.

**Expected outcome**: The playbook correctly identifies the OS and creates the appropriate marker file. Memory-based conditions trigger correctly.

**Hint**: Use `ansible_facts['distribution']` and `ansible_facts['memtotal_mb']`. Memory is in MB, so `ansible_facts['memtotal_mb'] < 1024` checks for less than 1GB.

---

### Exercise 2: Loop Over Dictionary Data
**Goal**: Process a list of complex objects using `loop` and conditionals.

1. Create a data structure representing firewall rules:
   ```yaml
   firewall_rules:
     - { port: 22, protocol: tcp, allowed_hosts: [office_ip], service: ssh }
     - { port: 80, protocol: tcp, allowed_hosts: [0.0.0.0/0], service: http }
     - { port: 443, protocol: tcp, allowed_hosts: [0.0.0.0/0], service: https }
     - { port: 5432, protocol: tcp, allowed_hosts: [app_server_ip], service: postgresql }
   ```
2. Write a task that iterates over these rules and uses `debug` to print each one.
3. Add a conditional: only process rules where `service` is not `ssh` or `postgresql` (simulating "skip internal services").
4. Use `loop_control.label` to make the output readable.

**Expected outcome**: Only the http and https rules are processed. Output is clean and shows the rule details.

**Hint**: Use `when: item.service not in ['ssh', 'postgresql']` inside the loop (note: `when` inside a loop applies to each item, not the whole task).

---

### Exercise 3: Block/Rescue/Always Pattern
**Goal**: Implement error handling with block structure.

1. Create a playbook with a `block` containing 3 tasks:
   - Task A: Create a file `/tmp/test-block.txt` with content
   - Task B: Run a command that fails (e.g., `exit 1` or a bad command)
   - Task C: Write `/tmp/success.txt` (should NOT run if task B fails)
2. Add a `rescue` block that creates `/tmp/rescue-triggered.txt` and prints a message.
3. Add an `always` block that prints "Always runs" and creates `/tmp/always-ran.txt`.
4. Run the playbook and observe: block fails at task B, rescue runs, always runs.
5. Fix task B so it succeeds, run again, and verify rescue does NOT run.

**Expected outcome**: On first run, block fails, rescue runs, always runs. On second run (fixed), all block tasks succeed, rescue is skipped, always still runs.

**Hint**: Use `command: /bin/false` or `command: exit 1` to simulate a failing task. The `always` block is the key feature to test here.

---

### Exercise 4: Loop with index_var for Ordered Configuration
**Goal**: Generate a numbered list of server entries in a config file.

1. Create a playbook that writes a `loadbalancer.conf` file using `template`.
2. Use a loop over server definitions with `loop_control: index_var: idx`.
3. Inside the template loop, generate lines like: `server server{{ idx + 1 }} = {{ item.host }}:{{ item.port }};`
4. Use `extended: yes` and print `ansible_loop.index` and `ansible_loop.first`/`ansible_loop.last`.
5. Test with at least 5 server entries.

**Expected outcome**: The generated config has server1 through server5, correctly numbered. The first and last items are identified correctly.

**Hint**: `index_var: idx` makes `idx` available as the 0-based counter in the template. Add 1 to get 1-based numbering.

---

### Exercise 5: Combination — Loops, Conditionals, and Registered Variables
**Goal**: Implement a package update checker that processes results and reacts to them.

1. Write a task that uses `shell` to list installed packages matching a pattern (e.g., `dpkg -l | grep python`).
2. Register the output.
3. Parse the registered output (use `stdout_lines` to get a list) in a subsequent loop.
4. For each installed package line that contains a version number, extract and display it.
5. Use a conditional to only process non-empty results (skip if no packages found).

**Expected outcome**: If packages are found, they are listed with version info. If none are found, a "no packages found" message is displayed instead of an error.

**Hint**: Use `when: package_list.stdout_lines | length > 0` on a subsequent debug task. Register variables with complex output are easier to debug with `debug: var=registered_var.stdout_lines` first.

## Summary

- The `when` clause makes tasks conditional based on variables, facts, and Jinja2 expressions.
- Jinja2 tests (`is defined`, `is not defined`, `is truthy`, `is none`, `is string`, etc.) enhance conditional logic.
- `loop` replaces older `with_items` and is the recommended loop construct.
- `loop_control` (`label`, `index_var`, `extended`) customizes loop behavior and output.
- Loop over lists of dicts to process complex configuration data.
- `block`, `rescue`, and `always` group tasks and implement error handling patterns.
- `run_once: true` ensures a task executes on only one host per play.
- `with_fileglob`, `with_dict`, and `with_sequence` provide specialized iteration.
- Combining loops with conditionals on `item` allows filtering within a single task.
- Always use `loop_control.label` for readable output when looping over complex objects.

## Additional Resources

- [Ansible Documentation: Conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html) — Complete guide to conditionals in Ansible.
- [Ansible Documentation: Loops](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html) — All loop types with examples.
- [Ansible Documentation: Block / Rescue / Always](https://docs.ansible.com/ansible/latest/user_guide/playbooks_blocks.html) — Error handling with blocks in detail.