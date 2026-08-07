# Chapter 4: Ansible Inventory

## Learning Objectives

By the end of this chapter, you will be able to:

- Create and manage static inventory files in both INI and YAML formats
- Organize hosts into groups and nested groups
- Define variables at host and group levels
- Use the `ansible-inventory` command to inspect and visualize inventory
- Apply best practices for organizing inventory in production environments
- Understand inventory patterns and how to target specific hosts

## Explanation

### What Is the Inventory?

The inventory is Ansible's way of knowing which machines to manage. It's a list of hosts, organized into groups, that Ansible connects to when running playbooks and commands.

The inventory can be:

- **Static**: A file you maintain manually (INI or YAML format)
- **Dynamic**: Scripts or plugins that fetch hosts from external sources (AWS, GCP, LDAP, etc.)

In this chapter, we focus on static inventory—the foundation you'll use first. Chapter 13 covers dynamic inventory.

### Default Inventory Location

By default, Ansible looks for inventory in these locations:

1. `/etc/ansible/hosts` — system-wide default
2. `./hosts` or `./inventory` — current working directory

You can also specify a custom inventory file using the `-i` flag:

```bash
# Use specific inventory file
ansible all -i /path/to/inventory -m ping

# Use a playbook with specific inventory
ansible-playbook -i inventory/production site.yml
```

> **Pro Tip**: Never rely on the default `/etc/ansible/hosts`. Always create a project-specific inventory file and reference it explicitly with `-i`. This makes your project portable and self-contained.

### INI Format Inventory

The classic Ansible inventory format uses simple INI-like syntax:

```ini
# Comments start with # or ;

# A single host by hostname
webserver1.example.com

# A group named [webservers]
[webservers]
webserver1.example.com
webserver2.example.com
webserver3.example.com

# Another group named [dbservers]
[dbservers]
dbserver1.example.com
dbserver2.example.com

# A group with explicit ports (for non-standard SSH)
[dev:children]
webservers
dbservers

# Individual host with port
backup.example.com:2222
```

### YAML Format Inventory

YAML inventory is more verbose but easier to extend and version-control friendly:

```yaml
---
all:
  hosts:
    webserver1.example.com:
    webserver2.example.com:
    dbserver1.example.com:
  children:
    webservers:
      hosts:
        webserver1.example.com:
        webserver2.example.com:
    dbservers:
      hosts:
        dbserver1.example.com:
    dev:
      children:
        webservers:
        dbservers:
```

Both formats are equivalent. Choose based on your team's familiarity. YAML is generally preferred for complex inventories because it handles nested structures more elegantly.

### Groups and Group Hierarchy

Groups organize related hosts. A host can belong to multiple groups:

```ini
# Basic groups
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[loadbalancers]
lb1.example.com
```

#### The Special `all` Group

Every host automatically belongs to the `all` group. This is useful for variables that apply to everything:

```ini
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ntp_server=pool.ntp.org
```

#### The `ungrouped` Group

Hosts that don't belong to any group besides `all` are in the implicit `ungrouped` group:

```ini
# These hosts are in 'all' but not in any other group
standalone1.example.com
standalone2.example.com
```

#### Nested Groups (Groups of Groups)

Create parent groups using `[groupname:children]`:

```ini
# Define base groups
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[monitoring]
monitor1.example.com

# Create a parent group 'production' containing webservers, dbservers, and monitoring
[production:children]
webservers
dbservers
monitoring

# A 'staging' group that only has webservers
[staging:children]
webservers
```

The resulting hierarchy:

```
all
├── webservers
│   ├── web1.example.com
│   └── web2.example.com
├── dbservers
│   └── db1.example.com
├── monitoring
│   └── monitor1.example.com
├── production (contains webservers, dbservers, monitoring)
└── staging (contains webservers)
```

### Host Variables

Override settings for individual hosts:

```ini
[webservers]
web1.example.com http_port=8080 max_connections=1000
web2.example.com http_port=9090 max_connections=500
```

These variables can be referenced in playbooks:

```yaml
- name: Configure web servers
  hosts: webservers
  tasks:
    - name: Configure httpd
      ansible.builtin.template:
        src: httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
      vars:
        port: "{{ http_port }}"
```

### Group Variables

Define variables that apply to all hosts in a group:

```ini
[webservers:vars]
http_port=80
max_connections=500
ansible_user=webadmin
```

```yaml
[dbservers:vars]
db_port=5432
db_name=myapp_production
db_user=dbadmin
```

### Variable Precedence (Simplified)

When the same variable is defined at multiple levels, Ansible uses precedence. From lowest to highest:

1. `all` group (lowest precedence)
2. Parent groups (in alphabetical order)
3. Child groups (later groups override earlier)
4. Host variables (highest precedence for static inventory)

For a complete precedence list, see Chapter 6.

> **Pro Tip**: Don't overuse inventory variables for complex configurations. They're best for connection details and environment-specific settings. Keep business logic in playbooks and roles.

### Aliases and Non-Standard Ports

You can alias hosts and specify connection details explicitly:

```ini
# Alias 'web1' for host at 192.168.1.10 on port 2222
web1 ansible_host=192.168.1.10 ansible_port=2222

# Complex connection settings
[production:children]
webservers
dbservers

[production:vars]
ansible_user=deploy
ansible_ssh_private_key_file=/home/user/.ssh/prod_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Ranges in Host Names

Specify multiple hosts using ranges:

```ini
# web1 through web5
web[1:5].example.com

# db01 through db10 (zero-padded)
db[01:10].example.com

# 192.168.1.1 through 192.168.1.10
192.168.1.[1:10]

# Combination
[webservers:vars]
ansible_host=192.168.1.[10:15]
```

### Using the ansible-inventory Command

The `ansible-inventory` command is invaluable for inspecting and debugging inventory:

```bash
# List all hosts in inventory
ansible-inventory -i hosts.ini --list

# Show inventory as a tree
ansible-inventory -i hosts.ini --graph

# Show a specific host's variables
ansible-inventory -i hosts.ini --host web1.example.com

# Show inventory in YAML format
ansible-inventory -i hosts.ini --list --yaml
```

Example output from `--graph`:

```bash
@all:
  |--@webservers:
  |  |--web1.example.com
  |  |--web2.example.com
  |--@dbservers:
  |  |--db1.example.com
  |--@ungrouped:
     |--control.example.com
```

### Verifying Inventory

Before running playbooks, always verify your inventory:

```bash
# Check which hosts Ansible sees
ansible all -i hosts.ini --list-hosts

# Ping all hosts (if reachable)
ansible all -i hosts.ini -m ping

# Test connectivity with specific user
ansible all -i hosts.ini -m ping -u ansible_user
```

### Best Practices for Inventory Organization

#### Project-Specific Inventory

```
project/
├── inventory/
│   ├── development
│   ├── staging
│   └── production
├── playbooks/
│   └── site.yml
└── ansible.cfg
```

```ini
# inventory/development
[development]
dev-web-1.example.com
dev-db-1.example.com

[development:vars]
environment=development
ansible_user=devuser
```

```ini
# inventory/production
[production]
prod-web-1.example.com
prod-web-2.example.com
prod-db-1.example.com
prod-db-2.example.com

[production:vars]
environment=production
ansible_user=deployuser
```

#### Use `ansible.cfg` to Point to Inventory

```ini
# ansible.cfg
[defaults]
inventory = ./inventory/development
host_key_checking = False
```

#### Separate Sensitive Data

Never put passwords or API keys directly in inventory files. Use:

- Ansible Vault (covered in Chapter 11)
- Environment variables
- External secrets management (HashiCorp Vault, AWS Secrets Manager)

```ini
# inventory/production (without secrets)
[production]
prod-web-1.example.com

[production:vars]
# Reference external secrets
db_password={{ lookup('env', 'DB_PASSWORD') }}
```

> **Pro Tip**: Create an `inventory/example` or `inventory/template` file to document your inventory structure for new team members. Include comments explaining each group and variable.

### Common Inventory Mistakes to Avoid

1. **Using default inventory**: Always create project-specific inventory
2. **Overloading with variables**: Use `group_vars/` and `host_vars/` directories for complex variable management (covered in Chapter 6)
3. **Hardcoding credentials**: Use Vault or external secrets
4. **Not testing inventory**: Always run `ansible-inventory --graph` before running playbooks
5. **Ignoring YAML formatting**: YAML is whitespace-sensitive—use consistent indentation

## Examples

### Example 1: Basic INI Inventory

```ini
# inventory/hosts.ini
# Web infrastructure inventory

[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com ansible_host=192.168.1.20

[loadbalancers]
lb1.example.com

[monitoring]
monitor1.example.com

# Group containing all infrastructure hosts
[infrastructure:children]
webservers
dbservers
loadbalancers
monitoring
```

### Example 2: YAML Inventory with Variables

```yaml
# inventory/production.yml
---
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: deploy
    environment: production

  children:
    webservers:
      hosts:
        web1.example.com:
          http_port: 80
          max_connections: 1000
        web2.example.com:
          http_port: 80
          max_connections: 1000

    dbservers:
      hosts:
        db1.example.com:
          db_port: 5432
          db_name: production_db
        db2.example.com:
          db_port: 5432
          db_name: production_db

    production:
      children:
        webservers:
        dbservers:
```

### Example 3: Inventory with Connection Variables

```ini
# inventory/environments.ini
# Development environment uses password authentication (INSECURE - demo only)
[development]
dev-server1.example.com ansible_user=devuser ansible_password=devpass

[development:vars]
ansible_port=22

# Staging uses SSH keys
[staging]
staging-server1.example.com ansible_user=staginguser ansible_ssh_private_key_file=~/.ssh/staging_id_rsa

[staging:vars]
ansible_port=2222
```

### Example 4: Complex Nested Groups

```ini
# inventory/complex.ini
# Multi-tier application with different environments

# Environment-based groups
[development]
dev-web-[1:2].example.com
dev-app-[1:2].example.com
dev-db-[1:2].example.com

[staging]
staging-web-[1:2].example.com
staging-app-[1:2].example.com
staging-db-[1:2].example.com

[production]
prod-web-[1:3].example.com
prod-app-[1:3].example.com
prod-db-[1:2].example.com

# Role-based groups
[webservers]
dev-web-*.example.com
staging-web-*.example.com
prod-web-*.example.com

[appservers]
dev-app-*.example.com
staging-app-*.example.com
prod-app-*.example.com

[databases]
dev-db-*.example.com
staging-db-*.example.com
prod-db-*.example.com

# Composite groups
[tier:children]
webservers
appservers
databases

[securezone:children]
appservers
databases

# All variables
[all:vars]
ntp_server=pool.ntp.org
dns_server=8.8.8.8

[tier:vars]
cluster_name=myapp

[production:vars]
monitoring_enabled=true
backup_enabled=true
```

### Example 5: Inspecting Inventory Programmatically

```bash
#!/bin/bash
# Script to verify inventory before deployment

INVENTORY="inventory/production.yml"

echo "=== Inventory Summary ==="
ansible-inventory -i $INVENTORY --graph

echo ""
echo "=== Host Count by Group ==="
ansible-inventory -i $INVENTORY --list | jq '.groups | to_entries[] | select(.key != "all") | "\(.key): \(.value.hosts | length) hosts"'

echo ""
echo "=== All Hosts ==="
ansible-inventory -i $INVENTORY --list-hosts

echo ""
echo "=== Checking Connectivity ==="
ansible all -i $INVENTORY -m ping --user deploy --ask-pass || echo "Some hosts unreachable"
```

## Hands-On Exercises

### Exercise 1: Create a Basic INI Inventory

**Objective**: Create an inventory file for a simple web application infrastructure.

**Expected Outcome**: An inventory file with at least 2 groups (webservers, dbservers) and 4 hosts total.

**Instructions**:
1. Create a file `inventory.ini`
2. Add 2 web servers and 2 database servers
3. Create a parent group called `production`
4. Add a `[production:vars]` section with common variables

**Hint**: Remember the `[group:children]` syntax for nested groups:
```ini
[production:children]
webservers
dbservers
```

---

### Exercise 2: Convert Inventory to YAML Format

**Objective**: Convert your INI inventory to equivalent YAML format.

**Expected Outcome**: A YAML inventory file that represents the same infrastructure as your INI file.

**Instructions**:
1. Create a file `inventory.yml`
2. Use the same groups and hosts as Exercise 1
3. Add the same variables
4. Verify equivalence with `ansible-inventory -i inventory.yml --graph`

**Hint**: Use `ansible-inventory` with both files and compare the `--graph` output. They should be identical.

---

### Exercise 3: Inspect Inventory with ansible-inventory

**Objective**: Use the `ansible-inventory` command to explore your inventory.

**Expected Outcome**: Successfully list hosts, show group hierarchy, and view host variables.

**Instructions**:
```bash
# List all hosts
ansible-inventory -i inventory.ini --list

# Show as tree
ansible-inventory -i inventory.ini --graph

# Show variables for a specific host
ansible-inventory -i inventory.ini --host web1.example.com
```

**Hint**: The `--host` flag only works for hosts defined in the inventory. It won't work for hosts that would match patterns (like `web*`).

---

### Exercise 4: Create Inventory for Multiple Environments

**Objective**: Create separate inventory files for development and production environments.

**Expected Outcome**: Two inventory files with identical structure but different host IP addresses and environment-specific variables.

**Instructions**:
1. Create `inventory/development.ini` with localhost and 2 VMs
2. Create `inventory/production.ini` with 3 web servers, 2 app servers, 2 db servers
3. Add `[development:vars]` and `[production:vars]` with `environment` variable
4. Test connectivity to development environment

**Hint**: Use Vagrant private networks (like 192.168.56.x) for local VMs.

---

### Exercise 5: Use Host Patterns to Target Specific Hosts

**Objective**: Practice using different host patterns to run commands on subsets of inventory.

**Expected Outcome**: Understand how to target specific hosts using patterns.

**Instructions**:
```bash
# Run ping on webservers group only
ansible webservers -i inventory.ini -m ping

# Run ping on all hosts except dbservers
ansible 'all:!dbservers' -i inventory.ini -m ping

# Run ping on hosts matching multiple patterns
ansible 'webservers:&production' -i inventory.ini -m ping

# Use a range
ansible web[1:2] -i inventory.ini -m ping
```

**Hint**: If you get "No hosts matched", check your inventory structure with `--graph` first.

## Summary

- The inventory defines which hosts Ansible manages and how to connect to them
- Inventory can be static (files) or dynamic (scripts/plugins)
- INI format is traditional and concise; YAML format is more explicit and version-control friendly
- Groups organize hosts; hosts can belong to multiple groups
- Use `[group:children]` to create nested groups (groups of groups)
- The `all` group contains every host; `ungrouped` contains hosts without explicit group membership
- Host variables override group variables, which override `all` variables
- Use `ansible-inventory --graph` to visualize inventory structure
- Always create project-specific inventory files rather than using defaults
- Separate sensitive data from inventory using Vault or external secrets

## Additional Resources

1. **Ansible Inventory Documentation**: https://docs.ansible.com/ansible/latest/inventory/
   Official guide covering all inventory topics including advanced features and troubleshooting.

2. **Intro to Inventory - Ansible Official Workshop**: https://ansible.readthedocs.io/en/latest/getting_started_ee/inventory.html
   Interactive introduction to inventory concepts with hands-on examples.

3. **Ansible Inventory Generator Patterns**: https://docs.ansible.com/ansible/latest/inventory_guide/intro_patterns.html

Comprehensive reference for host patterns, including advanced matching and filtering techniques.

<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../03-ad-hoc-commands/" style="color:#8892b0; text-decoration:none;">← Previous: Ad-hoc</a>
  <a href="../05-first-playbook/" style="background:#6c63ff; color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:600;">Next: First Playbook →</a>
</div>
