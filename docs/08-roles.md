# Chapter 8: Roles

## Learning Objectives

- Understand what Ansible roles are and why they are the standard way to organize reusable automation content
- Know the Ansible Galaxy directory structure for roles (tasks, handlers, vars, defaults, files, templates, meta)
- Create a role from scratch and from `ansible-galaxy init`
- Use roles in playbooks with the `roles:` keyword and understand the role execution order
- Define role dependencies with `meta/main.yml`
- Use Ansible Galaxy to find, install, and use community-maintained roles

## Explanation

As you build more complex playbooks, you will notice that a single playbook can grow very long and difficult to maintain. You may also want to reuse a set of tasks across multiple playbooks — for example, the steps to install and configure nginx should be identical whether you are deploying a web server or a load balancer.

Ansible **roles** solve both problems. A role is a self-contained, reusable collection of tasks, handlers, variables, files, templates, and metadata that can be shared and versioned. Think of a role as a packaged unit of automation — you can drop it into any playbook and it "just works."

Roles enforce a standardized directory structure. This means any Ansible developer who understands roles immediately knows where to look for tasks, handlers, or templates within a role. This predictability is one of the biggest benefits of the role-based approach.

### Role Directory Structure

An Ansible Galaxy-compliant role has this directory structure:

```
role_name/
├── defaults/          # Default variables (lowest precedence, meant to be overridden)
│   └── main.yml
├── files/             # Static files to be copied (no templating)
│   └── (files go here)
├── handlers/          # Handler definitions
│   └── main.yml
├── meta/              # Role metadata (dependencies, galaxy tags)
│   └── main.yml
├── tasks/             # Task definitions
│   └── main.yml
├── templates/         # Jinja2 templates (files with .j2 extension)
│   └── (templates go here)
├── vars/              # Role-internal variables (higher precedence than defaults)
│   └── main.yml
└── README.md          # Role documentation (optional but recommended)
```

Each directory is optional. If a role does not need handlers, you omit the `handlers/` directory entirely.

> **Pro Tip**: The `defaults/main.yml` file contains variables that are meant to be overridden by users. The `vars/main.yml` file contains variables that are internal to the role and should NOT be overridden (or at least, are not designed to be). This distinction is key: always put user-configurable values in `defaults/`, never in `vars/`.

### Creating a Role

The easiest way to create a role skeleton is with `ansible-galaxy init`:

```bash
ansible-galaxy init --init-path roles/ deploy-minecraft
```

This creates:

```
roles/deploy-minecraft/
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── README.md
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
```

You can now fill in each file. Let us build a real role step by step.

### A Complete Role Example: `deploy-minecraft`

**tasks/main.yml** — The tasks the role performs:

```yaml
---
# tasks/main.yml
- name: Ensure Java is installed
  package:
    name: java
    state: present

- name: Create minecraft user
  user:
    name: minecraft
    comment: Minecraft server user
    shell: /bin/false
    home: "{{ minecraft_home }}"
    create_home: yes

- name: Create Minecraft directory
  file:
    path: "{{ minecraft_home }}"
    state: directory
    owner: minecraft
    group: minecraft
    mode: '0755'

- name: Download Minecraft server jar
  get_url:
    url: "{{ minecraft_download_url }}"
    dest: "{{ minecraft_home }}/{{ minecraft_jar_file }}"
    mode: '0644'
    owner: minecraft
    group: minecraft
  notify: Restart Minecraft

- name: Accept EULA
  copy:
    content: "eula=true\n"
    dest: "{{ minecraft_home }}/eula.txt"
    owner: minecraft
    group: minecraft
    mode: '0644'
  notify: Restart Minecraft

- name: Create start script
  template:
    src: start.sh.j2
    dest: "{{ minecraft_home }}/start.sh"
    owner: minecraft
    group: minecraft
    mode: '0755'
  notify: Restart Minecraft
```

**handlers/main.yml** — Handlers triggered by tasks:

```yaml
---
# handlers/main.yml
- name: Restart Minecraft
  systemd:
    name: minecraft
    state: restarted
    enabled: yes
    daemon_reload: yes
```

**defaults/main.yml** — Default variables (lowest precedence):

```yaml
---
# defaults/main.yml
minecraft_version: "1.20.4"
minecraft_home: /opt/minecraft
minecraft_jar_file: server.jar
minecraft_download_url: "https://piston-data.mojang.com/v1/objects/15b09c1c24c5a4..."
minecraft_memory: "2G"
minecraft_rcon_port: 25575
minecraft_rcon_password: "changeme"
minecraft_whitelist_enabled: false
```

**templates/start.sh.j2** — The startup script template:

```bash
#!/bin/bash
java -Xmx{{ minecraft_memory }} -jar {{ minecraft_jar_file }} nogui
```

### Using Roles in a Playbook

Once a role is defined, you use it in a playbook with the `roles:` keyword:

```yaml
---
# site.yml
- name: Deploy Minecraft server
  hosts: minecraft_servers
  become: true

  roles:
    - role: deploy-minecraft
      vars:
        minecraft_version: "1.20.4"
        minecraft_memory: "4G"
```

When Ansible encounters `roles:`, it:

1. Loads any role dependencies (from `meta/main.yml`)
2. Loads role variables (defaults and vars)
3. Copies role files to the remote host (from `files/`)
4. Executes role tasks
5. Fires any handlers that were notified

The key point is that **role tasks always run before regular tasks** in a play. Within the `roles:` keyword, roles run in the order listed.

> **Pro Tip**: If you need tasks to run BEFORE role tasks (e.g., pre-flight checks), use `pre_tasks`. If you need tasks to run AFTER role tasks (e.g., health checks or cleanup), use `post_tasks`. Handlers run at the end of all of these.

### Role Execution Order in a Play

A complete play has this execution order:

```
pre_tasks          → Run before any roles
roles:             → Role tasks (in order listed)
tasks:             → Regular tasks (after all roles)
post_tasks         → Run after all tasks and handlers
handlers:          → Run at end (may be flushed earlier with meta)
```

### Role Dependencies

Roles can declare dependencies on other roles in `meta/main.yml`. This lets you build composable automation:

```yaml
# roles/webserver/meta/main.yml
---
dependencies:
  - role: common
    vars:
      ntp_server: "pool.ntp.org"
  - role: firewall
    vars:
      firewall_rules:
        - port: 80
        - port: 443
```

When you include the `webserver` role, Ansible automatically first includes `common` and `firewall` roles.

> **Pro Tip**: Be careful with circular dependencies (role A depends on B, B depends on A). Ansible will detect and prevent this, but it causes confusing errors. Keep dependency chains shallow — 2 levels deep is usually fine, 3+ is a smell.

### Ansible Galaxy

Ansible Galaxy (galaxy.ansible.com) is the community hub for Ansible content. It hosts thousands of roles written and maintained by the community and by companies. Using Galaxy roles lets you avoid reinventing the wheel.

To install a role from Galaxy:

```bash
# Install a role
ansible-galaxy install geerlingguy.redis

# Install a specific version
ansible-galaxy install geerlingguy.redis,6.0.0

# Install from a requirements file
ansible-galaxy role install -r requirements.yml
```

A `requirements.yml` file:

```yaml
# requirements.yml
---
roles:
  - name: geerlingguy.redis
    version: "6.0.0"
  - name: geerlingguy.apache
    version: "4.1.0"
```

To use a Galaxy role in your playbook, reference it by name just like a local role:

```yaml
---
- name: Configure Redis
  hosts: redis_servers
  become: true
  roles:
    - role: geerlingguy.redis
      vars:
        redis_port: 6379
        redis_bind_interface: 0.0.0.0
```

> **Pro Tip**: Pin versions in production. Galaxy roles are updated regularly, and a major version bump can change behavior unexpectedly. Always review a Galaxy role's `meta/main.yml` and `defaults/main.yml` before using it in production — community roles vary widely in quality and maintainability.

### Building Your Own Role for Reuse

Here is the recommended workflow for building a reusable role:

1. Write the tasks as a regular playbook first (so you can test iteratively)
2. Extract the tasks into `tasks/main.yml`
3. Extract variables into `defaults/main.yml` (configurable) and `vars/main.yml` (internal)
4. Identify static files → `files/`, templated files → `templates/`
5. Identify side effects → `handlers/main.yml`
6. Add `meta/main.yml` with galaxy tags and dependencies
7. Test by including the role in a minimal playbook

## Examples

### Example 1: Local Role with Full Structure

```yaml
# playbook.yml
---
- name: Set up development workstation
  hosts: workstations
  become: true

  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"

  roles:
    - role: common
    - role: docker
      vars:
        docker_users:
          - devuser
    - role: development-tools

  post_tasks:
    - name: Verify installations
      debug:
        msg: "Workstation setup complete for {{ ansible_facts['hostname'] }}"

  handlers:
    - name: Reload systemd
      systemd:
        daemon_reload: yes
```

### Example 2: Role with Conditional Execution

```yaml
# site.yml
---
- name: Configure database servers
  hosts: databases
  become: true

  roles:
    - role: common
    - role: postgresql
      when: database_type == "postgresql"
    - role: mysql
      when: database_type == "mysql"
    - role: redis
      when: enable_cache is defined and enable_cache | bool
```

### Example 3: Role with Custom File and Template

Role structure:
```
roles/mywebapp/
├── defaults/main.yml
├── files/
│   └── html/
│       └── index.html
├── tasks/main.yml
├── handlers/main.yml
└── templates/
    └── nginx.conf.j2
```

```yaml
# roles/mywebapp/tasks/main.yml
---
- name: Copy static HTML files
  synchronize:
    src: html/
    dest: /var/www/html/
  when: deploy_static | bool

- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/mywebapp
  notify: Reload nginx

- name: Enable nginx site
  file:
    src: /etc/nginx/sites-available/mywebapp
    dest: /etc/nginx/sites-enabled/mywebapp
    state: link
  notify: Reload nginx
```

## Hands-On Exercises

### Exercise 1: Create a Role from Scratch
**Goal**: Build a role that installs and configures a basic Apache web server.

1. Create a role: `ansible-galaxy init --init-path roles/ apache-role`
2. In `defaults/main.yml`, set:
   ```yaml
   apache_listen_port: 80
   apache_document_root: /var/www/html
   apache_server_name: localhost
   ```
3. In `tasks/main.yml`, write tasks to:
   - Install `apache2` package (Debian) or `httpd` (RHEL)
   - Create a custom index.html using `template` (create a simple template in `templates/`)
   - Start and enable the Apache service
4. In `handlers/main.yml`, add a `Restart Apache` handler.
5. Write a playbook that uses the role and overrides `apache_listen_port` to `8080`.
6. Run the playbook and verify Apache is running on port 8080.

**Expected outcome**: Apache is installed, running, and serving the custom page. The port override `8080` is reflected in the configuration.

**Hint**: Use `ansible_facts['os_family']` or `ansible_facts['distribution']` to handle both Debian and RHEL families with conditionals.

---

### Exercise 2: Role Dependencies
**Goal**: Create a common role that is a dependency for other roles.

1. Create a `common` role with a task that creates a monitoring user.
2. Create a `webserver` role with `meta/main.yml` that declares dependency on `common`.
3. Create a `database` role with `meta/main.yml` that also depends on `common`.
4. Write a playbook that uses only the `webserver` role.
5. Run the playbook and verify that:
   - The `common` role tasks run (even though not listed)
   - The `webserver` role tasks run

**Expected outcome**: The common role's monitoring user is created even though only `webserver` is listed in the playbook's `roles:` block. This confirms the dependency was resolved automatically.

**Hint**: Run with `-v` (verbose) to see the full task execution order and confirm role loading.

---

### Exercise 3: Use a Galaxy Role
**Goal**: Install and use a community role from Ansible Galaxy.

1. Install `geerlingguy.helm` (a popular Kubernetes package manager role).
2. Write a playbook that uses this role with appropriate variables.
3. Inspect the role's defaults to understand what variables it uses.
4. Run the playbook in check mode (`--check`) to see what it would do.

**Expected outcome**: The role is installed successfully. The check mode output shows the planned tasks without making changes. Inspecting defaults reveals the configurable variables.

**Hint**: Use `ansible-galaxy install geerlingguy.helm -p roles/` to install to your local `roles/` directory. Then reference it by name in your playbook.

---

### Exercise 4: Role with pre_tasks and post_tasks
**Goal**: Understand how pre_tasks and post_tasks interact with roles.

1. Create a `db-role` with 2 tasks: "Install database" and "Configure database".
2. Write a playbook that:
   - Has `pre_tasks` with a `debug` message: "Running pre-flight checks..."
   - Uses `db-role`
   - Has `post_tasks` with a `debug` message: "Running health checks..."
   - Has a handler `Restart database service`
3. Add a `notify: Restart database service` in the role's configure task.
4. Run the playbook and observe the execution order in the output.

**Expected outcome**: Output order is: pre_tasks → role tasks → post_tasks → handlers. The handler runs after post_tasks complete.

**Hint**: Use `-v` to see task names clearly. Note that role tasks are prefixed with the role name in verbose output.

---

### Exercise 5: Refactor an Existing Playbook into a Role
**Goal**: Convert a monolithic playbook into a reusable role.

1. Start with this playbook (or write one):
   ```yaml
   - name: Set up Prometheus
     hosts: monitoring
     become: true
     tasks:
       - name: Create prometheus user
         user: name=prometheus shell=/bin/false
       - name: Download Prometheus
         get_url: url=https://... dest=/opt/prometheus/
       - name: Configure Prometheus
         template: src=prometheus.yml.j2 dest=/etc/prometheus/
       - name: Start Prometheus
         systemd: name=prometheus state=started enabled=yes
   ```
2. Refactor it into a `prometheus` role with proper directory structure.
3. Extract variables to `defaults/main.yml` (version, install path, port).
4. Move the template to `templates/prometheus.yml.j2`.
5. Write a minimal playbook that includes the role.
6. Verify the refactored version produces the same result.

**Expected outcome**: The new role-based playbook produces identical results to the original. The role is self-contained and can be reused.

**Hint**: This is the most important skill for production Ansible work. The key is extracting all hard-coded values into `defaults/main.yml` variables, making the role configurable.

## Module Review — Test Yourself

??? question "Q1: Which directory inside a role holds the LOWEST-precedence variables that users are meant to override?"
    Click to reveal the answer.

    ??? success "Answer"
        **`defaults/main.yml`**. Variables here have the lowest precedence and are designed to be overridden by play vars, inventory vars, or extra vars.

??? question "Q2: What is the execution order inside a single play?"
    Click to reveal the answer.

    ??? success "Answer"
        `pre_tasks` → `roles` → `tasks` → `post_tasks` → `handlers`

??? question "Q3: If role A lists role B in its `meta/main.yml` dependencies, what happens when you include only role A in a playbook?"
    Click to reveal the answer.

    ??? success "Answer"
        Ansible **automatically includes role B first**, then runs role A. You only list role A in the playbook.

??? question "Q4: What is the difference between `defaults/main.yml` and `vars/main.yml` inside a role?"
    Click to reveal the answer.

    ??? success "Answer"
        - **`defaults/main.yml`** = user-configurable values (lowest precedence, meant to be overridden)
        - **`vars/main.yml`** = internal role values (higher precedence, not meant to be overridden)

??? question "Q5: Which command scaffolds a new role with the full Galaxy directory structure?"
    Click to reveal the answer.

    ??? success "Answer"
        `ansible-galaxy init --init-path roles/ my_role_name`

---

## Summary

- Roles are the standard Ansible packaging format for reusable automation content.
- The Galaxy directory structure (`tasks/`, `handlers/`, `defaults/`, `vars/`, `files/`, `templates/`, `meta/`) enforces consistency and discoverability.
- `defaults/main.yml` contains user-configurable variables; `vars/main.yml` contains internal ones.
- Use `ansible-galaxy init` to scaffold roles quickly.
- Roles in the `roles:` block run before `tasks:` in a play. Use `pre_tasks` and `post_tasks` for tasks that must run before or after roles.
- Role dependencies in `meta/main.yml` automatically pull in dependent roles.
- Ansible Galaxy hosts thousands of community roles — use them to avoid reinventing common infrastructure patterns.
- Always pin Galaxy role versions in production to prevent unexpected updates.

## Additional Resources

- [Ansible Documentation: Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) — Official documentation covering all role topics.
- [Ansible Galaxy](https://galaxy.ansible.com) — The community hub for discovering and sharing roles.
- [Ansible Best Practices: Roles and Includes (Red Hat)](https://www.ansible.com/blog/ansible-best-practices-roles) — Real-world guidance on structuring roles for large deployments.

```md
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../07-handlers/" style="color:#8892b0; text-decoration:none;">← Previous: Handlers</a>
  <a href="../09-templates-jinja2/" style="background:#6c63ff; color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:600;">Next: Templates →</a>
</div>
```
