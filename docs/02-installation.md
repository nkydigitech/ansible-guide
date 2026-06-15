# Chapter 2: Installing Ansible

## Learning Objectives

By the end of this chapter, you will be able to:

- Install Ansible on Linux (RHEL/CentOS and Ubuntu/Debian), macOS, and Windows (WSL2)
- Verify the installation using `ansible --version`
- Understand the differences between `ansible`, `ansible-playbook`, and `ansible-galaxy` commands
- Configure a basic test environment using Docker, Vagrant, or containers
- Troubleshoot common installation issues

## Explanation

### Before You Begin

This chapter assumes you have:

- A computer (laptop, desktop, or server) to use as your control node
- Basic familiarity with the command line
- SSH access to at least one test target (or willingness to set one up)
- An internet connection to download packages

The "control node" is the machine where you run Ansible commands. It can be your laptop, a dedicated build server, or any Unix-like system. Windows is supported as a control node only through Windows Subsystem for Linux (WSL2).

### Installation Methods Overview

There are several ways to install Ansible:

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| OS Package Manager | Most users | Easy, well-tested | May have older version |
| pip (Python package manager) | Latest features | Most recent version | Requires Python knowledge |
| pipx | Isolated installation | Clean, no dependency conflicts | Slightly more complex |
| Source (git) | Contributors | Access to development | Less stable, harder to update |

For beginners, the OS package manager is the recommended starting point. If you need the newest features, pip or pipx are better choices.

### Installing on Linux

#### RHEL, CentOS, Rocky, and AlmaLinux

These Red Hat-based distributions use `yum` or `dnf` as package managers. For RHEL 8+ and CentOS 8+, `dnf` is preferred.

```bash
# For RHEL 8+/CentOS 8+/Rocky 8+/AlmaLinux 8+
sudo dnf install ansible

# For older RHEL/CentOS 7 systems (using yum)
sudo yum install epel-release
sudo yum install ansible
```

The `epel-release` package adds the Extra Packages for Enterprise Linux (EPEL) repository, which contains Ansible.

#### Ubuntu and Debian

```bash
# Update the package cache first
sudo apt update

# Install Ansible
sudo apt install ansible
```

For newer versions or specific needs, you might want to use the Ansible PPA (Personal Package Archive):

```bash
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

#### Fedora

Fedora uses `dnf` and sometimes has Ansible available directly:

```bash
sudo dnf install ansible
```

> **Pro Tip**: The version of Ansible in system package managers is often 2-4 weeks behind the latest release. If you need cutting-edge features or modules, consider using `pip install ansible` instead. However, for learning and most production uses, the packaged version is perfectly adequate.

### Installing on macOS

macOS does not include Python or Ansible by default. The easiest installation method is Homebrew, macOS's package manager.

First, ensure you have Homebrew installed. If not, install it from https://brew.sh.

```bash
# Install Homebrew if you haven't already
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ansible
brew install ansible
```

After installation, verify with:

```bash
ansible --version
```

You may also need to install Python 3 if it's not already present:

```bash
brew install python@3.11
```

### Installing on Windows

Ansible cannot run natively on Windows as a control node. Microsoft Windows Subsystem for Linux (WSL2) provides a fully functional Linux environment within Windows, and this is the officially supported method.

#### Setting Up WSL2

1. **Enable WSL2**: Open PowerShell as Administrator and run:
   ```powershell
   wsl --install
   ```

2. **Restart your computer** when prompted.

3. **Choose a Linux distribution**: Ubuntu is recommended for beginners. You can install it from the Microsoft Store or via command line.

4. **Verify WSL2 is set as default**:
   ```powershell
   wsl --set-default-version 2
   ```

5. **Complete Linux setup**: When Ubuntu launches for the first time, create your user account and password.

6. **Install Ansible inside WSL2**:
   ```bash
   sudo apt update && sudo apt install ansible
   ```

7. **Verify installation**:
   ```bash
   ansible --version
   ```

> **Pro Tip**: Store your project files within the WSL2 filesystem (e.g., `/home/yourusername/ansible/`) for better performance. Accessing Windows filesystem from WSL2 has slower I/O speeds. The WSL2 filesystem is at `\\wsl$\` from Windows or accessible directly in the WSL2 terminal.

### Installing via pip

If you need a newer version or prefer Python's package manager:

```bash
# Install Python 3 if not present (Linux/macOS)
# On macOS:
brew install python@3.11

# On Ubuntu:
sudo apt install python3 python3-pip

# Install Ansible using pip
pip3 install ansible

# Or for the latest development version:
pip3 install ansible-core

# Upgrade to latest:
pip3 install --upgrade ansible
```

For isolated environments that don't conflict with system packages:

```bash
# Install pipx if not present
pip3 install pipx
pipx install ansible
```

### Verifying Your Installation

Regardless of how you installed Ansible, verify it works:

```bash
ansible --version
```

Expected output:
```bash
ansible [core 2.16.x]
  config file = None
  configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.11/site-packages/ansible
  ansible collection location = /usr/lib/python3.11/site-packages/ansible_collections
  executable location = /usr/bin/ansible
  python version = 3.11.x
```

If you see an error like `ansible: command not found`, the installation failed or your shell's PATH doesn't include the Ansible binary. Check that Python is installed:

```bash
python3 --version
pip3 --version
```

---

## 🚀 Quick First Test — Make Ansible Do Something Real

Running `ansible --version` proves Ansible is installed. It does **not** prove you can use it.

The very next thing you should do is make Ansible perform a real action and verify the result with your own eyes. There are two paths depending on your environment:

### Path A — Native Install (Ubuntu/Debian VM or WSL with `sudo`)

Run these three commands in order:

```bash
# 1. Install nginx using Ansible
ansible localhost -m ansible.builtin.apt \
  -a "name=nginx state=present update_cache=yes" \
  --become

# 2. Start the nginx service
ansible localhost -m ansible.builtin.systemd \
  -a "name=nginx state=started enabled=yes" \
  --become

# 3. Check it's serving
ansible localhost -m ansible.builtin.uri \
  -a "url=http://localhost return_content=yes" \
  --become
```

**Expected output from Step 3:**
```json
localhost | SUCCESS => {
    "changed": false,
    "content": "<!DOCTYPE html>...",
    "status": 200
}
```

**Now browse to `http://localhost`.** You should see the nginx welcome page.

### Path B — Docker Fallback (Codespaces or restricted environments)

If `sudo apt-get` is blocked, use Docker:

```bash
# 1. Start nginx in Docker
docker run -d --name first-nginx -p 8080:80 nginx:alpine

# 2. Prove Ansible can reach localhost and run commands
ansible localhost -m ansible.builtin.command \
  -a "docker exec first-nginx nginx -v"

# 3. Verify with curl
curl -s http://localhost:8080 | head -5
```

**Expected output from Step 2:**
```
localhost | CHANGED | rc=0 >>
nginx version: nginx/1.31.1
```

**Now browse to `http://localhost:8080`.** You should see the nginx welcome page.

Follow the full step-by-step guide with screenshots at [playbooks/02-installation/README.md](../../playbooks/02-installation/README.md).

### Understanding Ansible Commands

After installation, you'll have several new commands available:

#### ansible

The base command for running individual tasks against hosts. Used for **ad-hoc commands**—quick operations you don't want to save in a playbook:

```bash
# Ping all hosts in inventory
ansible all -m ping

# Get system memory info from all hosts
ansible all -m setup -a "filter=ansible_memory_mb"
```

We'll cover ad-hoc commands in detail in Chapter 3.

#### ansible-playbook

The command for running playbooks—your saved automation scripts:

```bash
# Run a playbook
ansible-playbook site.yml

# Run with increased verbosity (useful for debugging)
ansible-playbook site.yml -v    # Basic info
ansible-playbook site.yml -vv   # More detail
ansible-playbook site.yml -vvv  # Connection debugging
ansible-playbook site.yml -vvvv # Everything
```

We'll cover playbooks in detail starting in Chapter 5.

#### ansible-galaxy

The command for managing Ansible Roles and Collections:

```bash
# Initialize a new role with a standard directory structure
ansible-galaxy init my_role

# Install a role from Ansible Galaxy (community roles)
ansible-galaxy install geerlingguy.nginx

# List installed roles
ansible-galaxy list

# Remove a role
ansible-galaxy remove geerlingguy.nginx
```

Galaxy is Ansible's community hub for sharing and discovering automation content.

### Setting Up a Test Environment

To practice Ansible, you need target hosts to manage. Here are several options:

#### Option 1: Docker Containers (Recommended for Speed)

Docker provides the fastest way to spin up test hosts:

```bash
# Ensure Docker is installed
docker --version

# Pull a lightweight Linux image
docker pull ubuntu:22.04

# Create two test containers
docker run -d --name ansible-target-1 ubuntu:22.04 sleep infinity
docker run -d --name ansible-target-2 ubuntu:22.04 sleep infinity

# Install SSH server in each container (required for Ansible)
docker exec ansible-target-1 apt-get update && apt-get install -y openssh-server
docker exec ansible-target-2 apt-get update && apt-get install -y openssh-server

# Start SSH service in each container
docker exec ansible-target-1 service ssh start
docker exec ansible-target-2 service ssh start
```

The containers need a few minutes to settle. Check they are running:

```bash
docker ps
```

#### Option 2: Vagrant Virtual Machines

Vagrant creates reproducible development environments using VirtualBox, VMware, or other providers:

1. Install Vagrant from https://www.vagrantup.com/downloads.html
2. Install VirtualBox from https://www.virtualbox.org/wiki/Downloads

Create a `Vagrantfile` in your project directory:

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.define "web" do |web|
    web.vm.network "private_network", ip: "192.168.56.10"
  end

  config.vm.define "db" do |db|
    db.vm.network "private_network", ip: "192.168.56.11"
  end
end
```

Start the VMs:
```bash
vagrant up
```

SSH into a VM:
```bash
vagrant ssh web
```

#### Option 3: Cloud Instances

If you have cloud access (AWS, GCP, Azure, DigitalOcean), create 2-3 small instances:

- **AWS**: Use t2.micro (free tier eligible)
- **GCP**: Use e2-micro (free tier eligible)
- **Azure**: Use B1s (free tier eligible)
- **DigitalOcean**: Use the smallest droplet ($4/month)

Document the IP addresses and ensure your SSH key can access them.

> **Pro Tip**: Whichever test environment you choose, create a simple inventory file immediately. For example, create `hosts.ini` in your project directory:
> ```ini
> [testhosts]
> 192.168.56.10
> 192.168.56.11
> ```
> We'll cover inventory in depth in Chapter 4, but having this ready will let you test your Ansible installation immediately.

### Testing Your Installation End-to-End

Once you have test hosts available, perform this verification sequence:

```bash
# 1. Create a simple inventory file
echo "[testhosts]
192.168.56.10
192.168.56.11" > hosts.ini

# 2. Test connectivity with ping module
ansible all -i hosts.ini -m ping

# 3. If ping fails, test basic SSH connectivity
ssh user@192.168.56.10 "echo 'SSH works'"
```

If the ping succeeds, your Ansible installation is working correctly.

### Troubleshooting Common Issues

#### Python Not Found

If you get errors about Python not being found on targets:

```bash
# Configure Ansible to use python3 explicitly
ansible all -i hosts.ini -m ping -e 'ansible_python_interpreter=/usr/bin/python3'
```

Or add this to your `ansible.cfg`:

```ini
[defaults]
inventory = ./hosts.ini
host_key_checking = False
interpreter_python = auto_silent
```

#### SSH Connection Issues

If SSH fails:

```bash
# Test SSH manually
ssh -v user@hostname

# Common issues:
# - SSH key not added to authorized_keys
# - Wrong username
# - Firewall blocking port 22
# - Host key verification failing (known_hosts)
```

Add to your `ansible.cfg` to disable host key checking (testing only):

```ini
[defaults]
host_key_checking = False
```

#### Permission Denied

If you get permission denied errors:

```bash
# Try with verbose output to see where it fails
ansible all -i hosts.ini -m ping -v

# You may need to provide SSH password (not recommended for production)
# Use SSH keys instead
ssh-copy-id user@hostname
```

## Hands-On Exercises

### Exercise 1: Install Ansible on Your System

**Objective**: Install Ansible on your control node using the method appropriate for your operating system.

**Expected Outcome**: Successfully run `ansible --version` and see output showing Ansible version, Python location, and config file location.

**Instructions**:
- Linux: Use your system's package manager (apt, dnf, yum)
- macOS: Use Homebrew (`brew install ansible`)
- Windows: Install WSL2 and Ubuntu, then install Ansible inside WSL2

**Hint**: If you're on a corporate system and don't have sudo access, consider using pip to install Ansible in your user directory: `pip3 install --user ansible`.

---

### Exercise 2: Verify Multiple Ansible Commands

**Objective**: Confirm that all Ansible commands are available in your PATH.

**Expected Outcome**: Successfully execute `ansible --version`, `ansible-playbook --version`, and `ansible-galaxy --version` with no errors.

**Instructions**:
```bash
ansible --version
ansible-playbook --version
ansible-galaxy --version
```

**Hint**: If any command is not found, check that the installation completed successfully. The package might have installed Ansible but not created all the command aliases.

---

### Exercise 3: Explore the Ansible Directory Structure

**Objective**: After installation, locate and examine key Ansible directories and files on your system.

**Expected Outcome**: Document the locations of:
- The Ansible configuration file (`ansible.cfg`)
- The default inventory file
- The site-packages directory containing Ansible modules
- Your personal Ansible configuration (if any)

**Instructions**:
```bash
# Find ansible.cfg
ansible --version | grep "config file"

# Check default inventory location
grep "^inventory" /etc/ansible/ansible.cfg 2>/dev/null || echo "No inventory in ansible.cfg"

# List installed Ansible collections
ansible-galaxy collection list
```

**Hint**: On some installations, `ansible.cfg` might not exist yet. Ansible uses built-in defaults in that case. You can create your own `ansible.cfg` in your project directory to override defaults.

---

### Exercise 4: Set Up a Simple Test Environment

**Objective**: Create test target hosts using Docker, Vagrant, or cloud instances.

**Expected Outcome**: Have at least one reachable target host that you can manage with Ansible.

**Instructions**:
- If using Docker: Create a container as described in the "Option 1" section
- If using Vagrant: Create a `Vagrantfile` and run `vagrant up`
- If using cloud: Provision 2 small instances and note their IP addresses

**Hint**: Record the IP addresses or hostnames of your test machines. You'll need them for all subsequent exercises.

---

### Exercise 5: Test Connectivity to Your Targets

**Objective**: Verify Ansible can connect to your test hosts.

**Expected Outcome**: Successfully run `ansible all -i hosts.ini -m ping` and receive SUCCESS results from at least one host.

**Instructions**:
1. Create an inventory file with your test host IP addresses
2. Run the ping module against all hosts
3. If it fails, troubleshoot using SSH manually

**Hint**: The most common connectivity issue is SSH keys. Verify you can SSH to the target manually first. If password authentication is required, you may need to install `sshpass` or configure SSH keys.

## Module Review — Test Yourself

??? question "Q1: What is the difference between `ansible`, `ansible-playbook`, and `ansible-galaxy`?"
    Click to reveal the answer.

    ??? success "Answer"
        - **`ansible`** — Runs one-off ad-hoc commands (quick tasks you don't save).
        - **`ansible-playbook`** — Runs saved automation scripts written in YAML.
        - **`ansible-galaxy`** — Manages downloadable roles and collections from the community.

??? question "Q2: You ran `ansible --version` and got `command not found`. What should you check first?"
    Click to reveal the answer.

    ??? success "Answer"
        Run `python3 --version` and `pip3 --version` to make sure Python is installed. Then reinstall Ansible using your system's package manager or `pip3 install ansible`.

??? question "Q3: You created a Docker container for testing. What must be installed inside the container before Ansible can manage it?"
    Click to reveal the answer.

    ??? success "Answer"
        An **SSH server** (`openssh-server`). Ansible connects to target hosts over SSH by default.

??? question "Q4: Which task runs BEFORE any role in a playbook?"
    Click to reveal the answer.

    ??? success "Answer"
        **`pre_tasks`**. They run first, then roles, then regular `tasks`, then `post_tasks`, then handlers.

??? question "Q5: What does `CHANGED` in Ansible output mean?"
    Click to reveal the answer.

    ??? success "Answer"
        Ansible made a change to the target system. If you run the same command again, it should show `ok` (no changes needed) — this is called **idempotency**.

---

## Summary

- Ansible can be installed on Linux via system package managers (`apt`, `yum`, `dnf`), on macOS via Homebrew, and on Windows only through WSL2
- The `ansible` command runs ad-hoc commands, `ansible-playbook` runs saved playbooks, and `ansible-galaxy` manages roles and collections
- Always verify installation with `ansible --version`
- Test environments can be created using Docker (fastest), Vagrant (more realistic), or cloud instances (most like production)
- Common issues include missing Python on targets, SSH connectivity problems, and permission errors—troubleshoot systematically
- After installation and test environment setup, you should be able to ping your target hosts

## Additional Resources

1. **Ansible Installation Guide**: https://docs.ansible.com/ansible/latest/installation_guide/index.html
   Official documentation covering all installation methods with detailed troubleshooting steps.

2. **Test Kitchen for Ansible**: https://kitchen.ci/
   An integration testing framework for infrastructure code. Useful for testing Ansible playbooks across multiple platforms.

3. **Ansible Mailing List and Slack Community**: https://docs.ansible.com/ansible/latest/community/
   Connect with other Ansible users, ask questions, and get help with installation issues from experienced practitioners.