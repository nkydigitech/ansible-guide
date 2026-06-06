# Chapter 3: Ad-Hoc Commands

## Learning Objectives

By the end of this chapter, you will be able to:

- Understand when to use ad-hoc commands versus playbooks
- Execute the basic `ansible` command with correct syntax
- Use common modules: `ping`, `command`, `shell`, `copy`, `file`, `apt`, `yum`, `service`
- Apply privilege escalation with `-b` and `--become-user`
- Limit command execution to specific hosts using `-l` or `--limit`
- Perform dry-run operations with the `-C` or `--check` flag

## Explanation

### What Are Ad-Hoc Commands?

Ad-hoc commands are one-time commands you run directly from the terminal to perform quick tasks on remote hosts. Unlike playbooks (which are saved, repeatable automation), ad-hoc commands are useful for:

- Quick checks and diagnostics
- One-time tasks you won't repeat
- Testing module behavior before writing a playbook
- Emergency fixes across multiple systems

The syntax follows this pattern:

```bash
ansible <host-pattern> -m <module> -a <arguments> [options]
```

Let's break this down:

- **`<host-pattern>`**: Which hosts to target (e.g., `all`, `webservers`, `192.168.1.10`)
- **`-m <module>`**: Which Ansible module to use
- **`-a <arguments>`**: Arguments to pass to the module
- **[options]**: Additional flags like `-b` for privilege escalation

### When to Use Ad-Hoc Commands vs Playbooks

Ad-hoc commands are powerful but have limitations:

| Use Case | Ad-Hoc | Playbook |
|----------|--------|----------|
| Checking if a host is reachable | Yes | Overkill |
| Rebooting all servers at 3 AM | Yes | Yes |
| Installing a package on one server | Yes | Overkill |
| Rolling out a configuration change | Possible | Better |
| Complex multi-step deployments | Difficult | Designed for this |
| Repeated operations | Repetitive | Reusable |

In practice, you use ad-hoc commands for exploration and testing, then write playbooks for anything you'll do more than once.

### Essential Command Options

Before diving into specific modules, understand these commonly used flags:

```bash
# Privilege escalation (become root or another user)
ansible all -m apt -a "name=vim state=present" -b

# Limit to specific hosts
ansible all -m ping --limit webserver1.example.com

# Use a specific inventory file
ansible all -i /path/to/inventory -m ping

# Check mode (dry run)
ansible all -m copy -a "src=file.txt dest=/tmp/" -C

# Verbose output (-v, -vv, -vvv, -vvvv)
ansible all -m setup -v

# Run as specific user
ansible all -m user -a "name=bob" -b --become-user=bob
```

> **Pro Tip**: Always use `--check` (`-C`) before running commands that modify systems. This performs a dry run and shows you what would change without actually making changes. This is especially important when you're learning—better to see a preview than accidentally modify production systems.

### Common Modules

Let's explore the most frequently used modules.

#### The `ping` Module

The simplest module—checks if hosts are reachable:

```bash
ansible all -m ping
```

Output:
```bash
webserver1.example.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

No arguments needed. It returns "pong" if the host is reachable.

#### The `command` Module

Executes a command on the remote host. This is one of the most-used modules for running arbitrary commands:

```bash
# Check uptime on all hosts
ansible all -m command -a "uptime"

# Check disk usage
ansible all -m command -a "df -h"

# List files in a directory
ansible all -m command -a "ls -la /var/log/"
```

The `command` module is secure by default—it does not process shell variables (`$HOME`) or operators (`|`, `>`, `<`). For shell processing, use the `shell` module instead.

#### The `shell` Module

Like `command`, but runs through the remote host's shell:

```bash
# Create a file with content (using shell redirection)
ansible all -m shell -a "echo 'Hello World' > /tmp/hello.txt"

# Check memory with grep
ansible all -m shell -a "free -m | grep Mem"

# Use pipes
ansible all -m shell -a "cat /etc/os-release | grep PRETTY_NAME"
```

> **Pro Tip**: Prefer `command` over `shell` when possible. `command` is more secure (no shell injection vulnerabilities) and slightly faster. Use `shell` only when you need shell features like pipes, redirects, or variable expansion.

#### The `setup` Module

Automatically gathers facts about remote hosts. You can filter facts:

```bash
# Get all facts
ansible all -m setup

# Get only memory information
ansible all -m setup -a "filter=ansible_memory_mb"

# Get only network interfaces
ansible all -m setup -a "filter=ansible_eth*"

# Get distribution info
ansible all -m setup -a "filter=ansible_distribution*"
```

This module is automatically run at the beginning of every playbook unless you set `gather_facts: no`. You can use these facts in your playbooks:

```yaml
- name: Show system facts
  hosts: all
  tasks:
    - name: Display hostname
      ansible.builtin.debug:
        var: ansible_facts['hostname']

    - name: Display OS family
      ansible.builtin.debug:
        var: ansible_facts['os_family']
```

#### The `copy` Module

Copies files from the control node to managed hosts:

```bash
# Copy a file
ansible all -m copy -a "src=/local/file.txt dest=/remote/file.txt"

# Copy with owner/permissions
ansible all -m copy -a "src=file.txt dest=/tmp/file.txt mode=0644 owner=root"

# Copy with backup (creates .bak with timestamp)
ansible all -m copy -a "src=file.txt dest=/tmp/file.txt backup=yes"
```

This module is **idempotent**—if the file already exists with the same content, no changes are made.

#### The `fetch` Module

The inverse of `copy`—retrieves files from managed hosts to the control node:

```bash
# Fetch a file from remote hosts
ansible all -m fetch -a "src=/var/log/syslog dest=/local/logs/ flat=no"

# flat=no creates directories by hostname
# flat=yes overwrites to single destination (only works for single host)
```

This is useful for collecting logs, configuration files, or security artifacts from multiple servers.

#### The `file` Module

Creates, modifies, or removes files and directories:

```bash
# Create a directory
ansible all -m file -a "path=/tmp/testdir state=directory"

# Create a symbolic link
ansible all -m file -a "src=/etc/foo dest=/tmp/foo state=link"

# Remove a file or directory
ansible all -m file -a "path=/tmp/testdir state=absent"

# Set permissions on a file
ansible all -m file -a "path=/tmp/testfile mode=0755"
```

#### The `apt` Module (Debian/Ubuntu)

Installs, removes, or updates packages on Debian-based systems:

```bash
# Install a package
ansible all -m apt -a "name=vim state=present" -b

# Install multiple packages
ansible all -m apt -a "name=nginx,curl state=present" -b

# Remove a package
ansible all -m apt -a "name=vim state=absent" -b

# Update package cache and upgrade all packages
ansible all -m apt -a "update_cache=yes state=latest" -b

# Install a specific version
ansible all -m apt -a "name=nginx version=1.18.0" -b
```

#### The `yum` Module (RHEL/CentOS)

Similar to `apt` but for Red Hat-based systems:

```bash
# Install a package
ansible all -m yum -a "name=vim state=present" -b

# Install multiple packages
ansible all -m yum -a "name=nginx,curl state=present" -b

# Remove a package
ansible all -m yum -a "name=vim state=absent" -b

# Update all packages
ansible all -m yum -a "name=* state=latest" -b
```

> **Pro Tip**: For portable playbooks that work across different Linux distributions, use the `package` module instead of `apt` or `yum`. It automatically selects the right package manager:
> ```bash
> ansible all -m package -a "name=vim state=present" -b
> ```

#### The `service` Module

Manages system services (start, stop, restart, enable):

```bash
# Start a service
ansible all -m service -a "name=nginx state=started"

# Stop a service
ansible all -m service -a "name=nginx state=stopped"

# Restart a service
ansible all -m service -a "name=nginx state=restarted"

# Enable service to start at boot
ansible all -m service -a "name=nginx state=started enabled=yes"
```

#### The `user` Module

Creates, modifies, or removes users:

```bash
# Create a user
ansible all -m user -a "name=bob state=present" -b

# Create user with specific UID and shell
ansible all -m user -a "name=bob uid=1001 shell=/bin/bash state=present" -b

# Remove a user
ansible all -m user -a "name=bob state=absent" -b

# Remove user and their home directory
ansible all -m user -a "name=bob state=absent remove=yes" -b
```

### Privilege Escalation

Most system administration tasks require root privileges. Ansible provides several options:

```bash
# Become root (sudo by default)
ansible all -m apt -a "name=vim state=present" -b

# Become a specific user
ansible all -m user -a "name=bob" -b --become-user=alice

# Choose a become method (sudo, su, pbrun, pfexec, doas, dzdo, ksu)
ansible all -m shell -a "whoami" -b --become-method=sudo
```

> **Pro Tip**: On systems where sudo requires a password, use `--ask-become-pass`:
> ```bash
> ansible all -m apt -a "name=vim state=present" -b --ask-become-pass
> ```
> This prompts for the sudo password. However, for automation, configure passwordless sudo in `/etc/sudoers` or use SSH key-based authentication with a privileged account.

### Limiting Execution to Specific Hosts

Run commands on only a subset of your inventory:

```bash
# Run on webservers group only
ansible webservers -m ping

# Run on specific host
ansible 192.168.1.10 -m ping

# Run on all except one host (using pattern)
ansible 'all:!dbserver' -m ping

# Run on hosts matching multiple patterns
ansible 'webservers:&production' -m ping
```

The `--limit` flag provides additional control:

```bash
# Limit to a specific host
ansible all --limit webserver1.example.com -m ping

# Limit to multiple hosts (comma-separated)
ansible all --limit webserver1,webserver2 -m ping

# Limit to hosts matching a pattern from a file
ansible all --limit @/path/to/host_pattern.txt -m ping
```

### Host Patterns Quick Reference

| Pattern | Meaning |
|---------|---------|
| `all` | All hosts in inventory |
| `*` | All hosts (same as all) |
| `webservers` | All hosts in webservers group |
| `webservers:dbserver` | Hosts in either group (union) |
| `webservers:&dbserver` | Hosts in both groups (intersection) |
| `webservers:!dbserver` | In webservers but not dbserver (difference) |
| `web[1:3]` | web1, web2, web3 |
| `192.168.1.*` | Any IP in that subnet |

## Examples

### Example 1: Quick Health Check

Check the status of all your servers in seconds:

```bash
# Get uptime and load average
ansible all -m command -a "uptime && w"

# Check disk space (all hosts)
ansible all -m shell -a "df -h | grep -v tmpfs"

# Check memory
ansible all -m shell -a "free -m"

# Check running services
ansible all -m shell -a "systemctl list-units --type=service --state=running | head -20"
```

### Example 2: Install Software Across Servers

Install the same package on multiple servers:

```bash
# Install Nginx on all web servers
ansible webservers -m apt -a "name=nginx state=present update_cache=yes" -b -v
```

### Example 3: Copy and Distribute Configuration Files

Update a configuration file across all servers:

```bash
# Copy updated config (check mode first)
ansible all -m copy -a "src=./nginx.conf dest=/etc/nginx/nginx.conf" -C

# If satisfied, run for real
ansible all -m copy -a "src=./nginx.conf dest=/etc/nginx/nginx.conf" -b

# Reload nginx to pick up changes
ansible all -m service -a "name=nginx state=reloaded" -b
```

### Example 4: Gather Information for Troubleshooting

Collect diagnostic information from failing servers:

```bash
# Get full fact dump
ansible problematic-server -m setup --tree /tmp/facts/

# Check which users exist
ansible all -m command -a "cat /etc/passwd"

# Check recent log entries
ansible all -m shell -a "tail -50 /var/log/syslog"
```

### Example 5: Emergency Response

Reboot all servers in a controlled manner:

```bash
# Check server load before rebooting
ansible all -m command -a "uptime"

# Reboot all servers (with wait for them to come back)
ansible all -m shell -a "sleep 5 && reboot" -b -f 1

# Wait for servers to return (separate command after reboot)
ansible all -m wait_for -a "host=192.168.1.10 port=22 delay=10 timeout=300"
ansible all -m ping
```

> **Pro Tip**: Use `-f 1` (forks=1) when rebooting to reboot servers sequentially rather than all at once. This prevents taking down your entire infrastructure simultaneously.

## Hands-On Exercises

### Exercise 1: Ping Your Test Hosts

**Objective**: Verify Ansible can reach your test environment hosts.

**Expected Outcome**: All hosts return `SUCCESS` with `"ping": "pong"`.

**Instructions**:
```bash
ansible all -i hosts.ini -m ping
```

If using Docker containers, you may need to start the SSH service first:
```bash
docker exec ansible-target-1 service ssh start
```

**Hint**: If you get "UNREACHABLE", check that the containers are running (`docker ps`) and SSH is functioning.

---

### Exercise 2: Check System Information

**Objective**: Use the `setup` module to gather facts from your hosts.

**Expected Outcome**: Display hostname, operating system, and memory information from each host.

**Instructions**:
```bash
# Get all facts
ansible all -i hosts.ini -m setup

# Filter to specific facts
ansible all -i hosts.ini -m setup -a "filter=ansible_*"
```

**Hint**: The output is JSON. Look for keys like `ansible_facts['hostname']`, `ansible_facts['distribution']`, and `ansible_facts['memtotal_mb']`.

---

### Exercise 3: Install Software Using Ad-Hoc Commands

**Objective**: Install a package on your test hosts using ad-hoc commands.

**Expected Outcome**: The package is installed and verifiable by running `which <package>` or checking via package manager.

**Instructions**:
```bash
# Install vim on Debian/Ubuntu systems
ansible all -i hosts.ini -m apt -a "name=vim state=present" -b --ask-become-pass

# Verify installation
ansible all -i hosts.ini -m command -a "which vim"
```

**Hint**: If you don't have a package manager available in your test containers, try using `command` with `apt-get update && apt-get install -y vim`.

---

### Exercise 4: Create a File and Fetch It

**Objective**: Create a file on remote hosts using the `copy` module, then retrieve it using `fetch`.

**Expected Outcome**: Successfully create `/tmp/ansible_test.txt` on all hosts and download it to your control node.

**Instructions**:
```bash
# Create a file on remote hosts
ansible all -i hosts.ini -m copy -a "content='Hello from Ansible\nCreated at: $(date)' dest=/tmp/ansible_test.txt"

# Verify it exists
ansible all -i hosts.ini -m command -a "cat /tmp/ansible_test.txt"

# Fetch the file (flat=no preserves directory structure)
ansible all -i hosts.ini -m fetch -a "src=/tmp/ansible_test.txt dest=/tmp/fetched/ flat=no"

# Check the fetched files
ls -la /tmp/fetched/
```

**Hint**: With `flat=no`, Ansible creates directories like `/tmp/fetched/hostname/tmp/ansible_test.txt`.

---

### Exercise 5: Test Check Mode

**Objective**: Practice using the `--check` flag to preview changes without applying them.

**Expected Outcome**: Understand what would change on each host before making actual modifications.

**Instructions**:
```bash
# Attempt to copy a file in check mode (preview only)
ansible all -i hosts.ini -m copy -a "content='Test' dest=/tmp/check_test.txt" -C

# Try removing a non-existent file (should show no changes)
ansible all -i hosts.ini -m file -a "path=/tmp/nonexistent_file state=absent" -C

# Create a directory in check mode
ansible all -i hosts.ini -m file -a "path=/tmp/check_test_dir state=directory" -C
```

**Hint**: Check mode shows "changed": true for actions that would modify the system. For truly idempotent operations on already-correct state, it shows "changed": false.

## Summary

- Ad-hoc commands are one-time operations useful for quick tasks, diagnostics, and testing
- The basic syntax is `ansible <host-pattern> -m <module> -a <arguments>`
- Key modules include `ping` (connectivity), `command`/`shell` (execute commands), `setup` (gather facts), `copy`/`fetch` (file transfer), `file` (manage files/directories), `apt`/`yum`/`package` (packages), `service` (systemd services), and `user` (user management)
- Privilege escalation is achieved with `-b` (become) and `--become-user` (specify user)
- Limit hosts with `--limit` or by specifying groups in the host pattern
- Always use `--check` (`-C`) for dry runs before modifying systems
- Ad-hoc commands are for exploration and one-time tasks; write playbooks for repeatable automation

## Additional Resources

1. **Ansible Module Index**: https://docs.ansible.com/ansible/latest/modules/modules_by_category.html
   Complete reference for all built-in modules, organized by category (system, commands, files, etc.).

2. **Ansible Ad-Hoc Command Examples**: https://docs.ansible.com/ansible/latest/command_guide/intro_adhoc.html
   Official documentation with practical ad-hoc command examples for common sysadmin tasks.

3. **Practical Ansible Examples (GitHub)**: https://github.com/ansible/ansible-examples
   Community-maintained collection of Ansible examples, from simple ad-hoc commands to complete deployments.