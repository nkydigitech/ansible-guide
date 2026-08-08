# Chapter 15: Capstone Project - Multi-Tier Web Application Deployment

## Learning Objectives

- Deploy a complete three-tier web application (Load Balancer, Web Servers, Database) using Ansible
- Integrate concepts from all previous chapters: inventory, variables, handlers, roles, templates, conditionals, loops, Vault, error handling, dynamic inventory, and collections
- Create a production-ready role structure with proper separation of concerns
- Implement security best practices including Vault-encrypted credentials
- Verify the deployment with validation checks and provide troubleshooting guidance

## Project Overview

### Architecture

You will deploy a **LEMP Stack (Linux, Nginx, MySQL, PHP)** with three distinct server tiers:

```
                    ┌─────────────────┐
                    │   Load Balancer  │  (Nginx as reverse proxy)
                    │   (lb_servers)   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼────┐ ┌───────▼──────┐ ┌─────▼───────┐
    │  Web Server  │ │  Web Server  │ │  Web Server │
    │ (web_servers)│ │ (web_servers)│ │(web_servers)│
    │   app-01     │ │   app-02     │ │   app-03    │
    └──────┬───────┘ └───────┬──────┘ └──────┬──────┘
           │                 │               │
           └─────────────────┼───────────────┘
                             │
                    ┌────────▼────────┐
                    │    Database     │
                    │ (db_servers)    │
                    │   mysql-01      │
                    └─────────────────┘
```

### Requirements Summary

| Component | Technology | Servers | Key Configuration |
|-----------|------------|---------|-------------------|
| Load Balancer | Nginx | 1 | SSL termination, upstream routing |
| Web Servers | Nginx + PHP-FPM | 3 | PHP application hosting |
| Database | MySQL | 1 | Application database, user permissions |
| Firewall | UFW/firewalld | All | Restrictive rules |
| Secrets | Ansible Vault | N/A | Encrypted passwords and keys |

### Role Structure

```
production/
├── inventory/
│   ├── hosts.yml              # Static inventory with all servers
│   └── group_vars/
│       └── all/
│           └── vault.yml      # ENCRYPTED - all secrets
├── playbooks/
│   ├── site.yml               # Main deployment playbook
│   ├── site-check.yml         # Verification playbook
│   └── rollback.yml           # Rollback playbook
├── roles/
│   ├── common/                # Base configuration for all servers
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/etimes.conf.j2
│   ├── firewall/              # Firewall configuration
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   ├── database/              # MySQL setup
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── templates/my.cnf.j2
│   │   └── defaults/main.yml
│   ├── webserver/             # Nginx + PHP-FPM
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── templates/nginx.conf.j2
│   │   └── templates/php.conf.j2
│   ├── loadbalancer/          # Nginx as load balancer
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── templates/lb.conf.j2
│   │   └── defaults/main.yml
│   └── app/                   # Application deployment
│       ├── tasks/main.yml
│       ├── templates/config.php.j2
│       ├── templates/index.php.j2
│       └── files/
│           └── health_check.php
└── ansible.cfg
```

---

## Step-by-Step Instructions

### Phase 1: Project Setup

**Step 1.1: Create the directory structure**

```bash
mkdir -p production/{inventory/group_vars/all,playbooks,roles/{common,firewall,database,webserver,loadbalancer,app}/{tasks,handlers,templates,defaults,files}}
```

**Step 1.2: Configure ansible.cfg**

```ini
# production/ansible.cfg
[defaults]
inventory = inventory/hosts.yml
roles_path = roles
host_key_checking = False
timeout = 30
stdout_callback = yaml
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[diff]
always = True
```

**Step 1.3: Create the static inventory**

```yaml
# production/inventory/hosts.yml
---
all:
  children:
    lb_servers:
      hosts:
        lb01:
          ansible_host: 192.168.1.10
          ansible_user: ubuntu
          nginx_upstream_name: web_backend

    web_servers:
      hosts:
        web01:
          ansible_host: 192.168.1.20
          ansible_user: ubuntu
        web02:
          ansible_host: 192.168.1.21
          ansible_user: ubuntu
        web03:
          ansible_host: 192.168.1.22
          ansible_user: ubuntu

    db_servers:
      hosts:
        mysql01:
          ansible_host: 192.168.1.30
          ansible_user: ubuntu
          ansible_python_interpreter: /usr/bin/python3
```

**Step 1.4: Create encrypted vault file**

This file will contain all sensitive credentials. You must encrypt it with Ansible Vault:

```yaml
# production/inventory/group_vars/all/vault.yml
# (This will be encrypted - run: ansible-vault create inventory/group_vars/all/vault.yml)
---
vault_mysql_root_password: "MyS3cur3RootP@ssw0rd!"
vault_mysql_app_user: "webapp"
vault_mysql_app_password: "AppD@tabaseP@ss123!"
vault_mysql_app_db: "webapp_db"

vault_app_secret_key: "your-256-bit-secret-key-here-change-in-production"
vault_admin_email: "admin@example.com"
```

To create the encrypted file:
```bash
cd production
ansible-vault create inventory/group_vars/all/vault.yml
# Paste the content above, save and exit
```

### Phase 2: Common Role (All Servers)

The common role handles base configuration applied to every server.

**Step 2.1: Create common tasks**

```yaml
# production/roles/common/tasks/main.yml
---
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Upgrade all packages
  ansible.builtin.apt:
    upgrade: dist
    autoremove: yes
  when: ansible_os_family == "Debian"

- name: Install common packages
  ansible.builtin.package:
    name:
      - curl
      - wget
      - vim
      - htop
      - git
      - ufw
    state: present

- name: Set timezone
  community.general.timezone:
    name: "{{ server_timezone | default('UTC') }}"
```

**Step 2.2: Create common handlers**

```yaml
# production/roles/common/handlers/main.yml
---
- name: Reload systemd
  ansible.builtin.systemd:
    daemon_reload: yes
```

### Phase 3: Database Role

**Step 3.1: Define database defaults**

```yaml
# production/roles/database/defaults/main.yml
---
mysql_version: "8.0"
mysql_port: 3306
mysql_bind_address: "0.0.0.0"
mysql_max_connections: 200
mysql_character_set_server: utf8mb4
mysql_collation_server: utf8mb4_unicode_ci
```

**Step 3.2: Create database tasks**

```yaml
# production/roles/database/tasks/main.yml
---
- name: Install MySQL server
  ansible.builtin.apt:
    name:
      - mysql-server
      - python3-mysqldb
      - python3-pymysql
    state: present
    update_cache: yes

- name: Create MySQL configuration
  ansible.builtin.template:
    src: my.cnf.j2
    dest: /etc/mysql/mysql.conf.d/custom.cnf
    mode: '0644'
    backup: yes
  notify: Restart MySQL

- name: Ensure MySQL is running and enabled
  ansible.builtin.service:
    name: mysql
    state: started
    enabled: yes

- name: Wait for MySQL to be ready
  ansible.builtin.wait_for:
    port: "{{ mysql_port }}"
    delay: 5
    timeout: 30

- name: Set MySQL root password
  ansible.builtin.shell: |
    mysql -u root <<EOF
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '{{ vault_mysql_root_password }}';
    FLUSH PRIVILEGES;
    EOF
  args:
    executable: /bin/bash
  no_log: true

- name: Create application database
  community.mysql.mysql_db:
    name: "{{ vault_mysql_app_db }}"
    state: present
    login_user: root
    login_password: "{{ vault_mysql_root_password }}"

- name: Create application user
  community.mysql.mysql_user:
    name: "{{ vault_mysql_app_user }}"
    password: "{{ vault_mysql_app_password }}"
    host: "{{ item }}"
    priv: "{{ vault_mysql_app_db }}.*:ALL"
    state: present
    login_user: root
    login_password: "{{ vault_mysql_root_password }}"
  loop:
    - localhost
    - "%"  # Allow connections from any host (restrict in production)
  no_log: true
```

**Step 3.3: Create MySQL configuration template**

```yaml
# production/roles/database/templates/my.cnf.j2
[mysqld]
# Binding
bind-address = {{ mysql_bind_address }}
port = {{ mysql_port }}

# Performance
max_connections = {{ mysql_max_connections }}
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M

# Character set
character-set-server = {{ mysql_character_set_server }}
collation-server = {{ mysql_collation_server }}

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2

# Binary logging for point-in-time recovery
log_bin = /var/log/mysql/mysql-bin.log
expire_logs_days = 7
max_binlog_size = 100M

[client]
port = {{ mysql_port }}
```

**Step 3.4: Create database handlers**

```yaml
# production/roles/database/handlers/main.yml
---
- name: Restart MySQL
  ansible.builtin.service:
    name: mysql
    state: restarted

- name: Reload MySQL
  ansible.builtin.service:
    name: mysql
    state: reloaded
```

### Phase 4: Web Server Role

**Step 4.1: Create webserver tasks**

```yaml
# production/roles/webserver/tasks/main.yml
---
- name: Install Nginx and PHP-FPM
  ansible.builtin.apt:
    name:
      - nginx
      - php-fpm
      - php-mysql
      - php-cli
      - php-curl
      - php-gd
      - php-mbstring
      - php-xml
    state: present
    update_cache: yes

- name: Create web root directory
  ansible.builtin.file:
    path: "{{ web_root | default('/var/www/html') }}"
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

- name: Configure Nginx
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/webapp.conf
    mode: '0644'
    backup: yes
  notify: Reload Nginx
  when: "'lb_servers' in group_names"

- name: Enable Nginx site
  ansible.builtin.file:
    src: /etc/nginx/sites-available/webapp.conf
    dest: /etc/nginx/sites-enabled/webapp.conf
    state: link
  notify: Reload Nginx
  when: "'lb_servers' in group_names"

- name: Disable default Nginx site
  ansible.builtin.file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: Reload Nginx
  when: "'lb_servers' in group_names"

- name: Ensure Nginx is running
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: yes
```

**Step 4.2: Create Nginx configuration template**

```yaml
# production/roles/webserver/templates/nginx.conf.j2
server {
    listen 80;
    listen [::]:80;
    
    server_name {{ inventory_hostname }};
    root {{ web_root | default('/var/www/html') }};
    
    index index.php index.html;
    
    # Logging
    access_log /var/log/nginx/{{ inventory_hostname }}_access.log;
    error_log /var/log/nginx/{{ inventory_hostname }}_error.log;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php{{ php_version | default('8.1') }}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

**Step 4.3: Create webserver handlers**

```yaml
# production/roles/webserver/handlers/main.yml
---
- name: Reload Nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded

- name: Restart Nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

### Phase 5: Load Balancer Role

**Step 5.1: Create loadbalancer defaults**

```yaml
# production/roles/loadbalancer/defaults/main.yml
---
lb_keepalive_timeout: 65
lb_connect_timeout: 5
lb_server_timeout: 600
```

**Step 5.2: Create loadbalancer tasks**

```yaml
# production/roles/loadbalancer/tasks/main.yml
---
- name: Install Nginx
  ansible.builtin.apt:
    name:
      - nginx
    state: present
    update_cache: yes

- name: Configure load balancer
  ansible.builtin.template:
    src: lb.conf.j2
    dest: /etc/nginx/sites-available/lb.conf
    mode: '0644'
    backup: yes
  notify: Reload Nginx

- name: Enable load balancer configuration
  ansible.builtin.file:
    src: /etc/nginx/sites-available/lb.conf
    dest: /etc/nginx/sites-enabled/lb.conf
    state: link
  notify: Reload Nginx

- name: Disable default site
  ansible.builtin.file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: Reload Nginx

- name: Test Nginx configuration
  ansible.builtin.command: nginx -t
  changed_when: false

- name: Ensure Nginx is running
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: yes
```

**Step 5.3: Create load balancer template**

```yaml
# production/roles/loadbalancer/templates/lb.conf.j2
upstream {{ nginx_upstream_name }} {
    least_conn;
    
    {% for host in groups['web_servers'] %}
    server {{ host }}:{{ web_server_port | default('80') }};
    {% endfor %}
    
    keepalive {{ lb_keepalive_timeout }};
}

server {
    listen 80;
    listen [::]:80;
    
    server_name {{ lb_hostname | default('lb.example.com') }};
    
    # Logging
    access_log /var/log/nginx/lb_access.log;
    error_log /var/log/nginx/lb_error.log;
    
    # Proxy settings
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_buffering off;
    proxy_request_buffering off;
    
    location / {
        proxy_pass http://{{ nginx_upstream_name }};
        
        # Timeouts
        proxy_connect_timeout {{ lb_connect_timeout }}s;
        proxy_send_timeout {{ lb_server_timeout }}s;
        proxy_read_timeout {{ lb_server_timeout }}s;
    }
    
    # Health check endpoint
    location /lb-health {
        access_log off;
        return 200 "LB healthy\n";
        add_header Content-Type text/plain;
    }
}
```

**Step 5.4: Create loadbalancer handlers**

```yaml
# production/roles/loadbalancer/handlers/main.yml
---
- name: Reload Nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded

- name: Restart Nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

### Phase 6: Firewall Role

**Step 6.1: Create firewall tasks**

```yaml
# production/roles/firewall/tasks/main.yml
---
- name: Install UFW
  ansible.builtin.apt:
    name:
      - ufw
    state: present

- name: Reset UFW to default
  community.general.ufw:
    state: reset

- name: Set default deny incoming
  community.general.ufw:
    default: deny
    direction: incoming

- name: Set default allow outgoing
  community.general.ufw:
    default: allow
    direction: outgoing

- name: Allow SSH (prevent lockout)
  community.general.ufw:
    rule: allow
    direction: incoming
    port: '22'
    proto: tcp

- name: Allow HTTP
  community.general.ufw:
    rule: allow
    direction: incoming
    port: '80'
    proto: tcp

- name: Allow HTTPS
  community.general.ufw:
    rule: allow
    direction: incoming
    port: '443'
    proto: tcp

- name: Enable UFW
  community.general.ufw:
    state: enabled
```

### Phase 7: Application Role

**Step 7.1: Create application tasks**

```yaml
# production/roles/app/tasks/main.yml
---
- name: Deploy application configuration
  ansible.builtin.template:
    src: config.php.j2
    dest: "{{ web_root | default('/var/www/html') }}/config.php"
    owner: www-data
    group: www-data
    mode: '0640'
    backup: yes
  when: "'web_servers' in group_names"

- name: Deploy application index file
  ansible.builtin.template:
    src: index.php.j2
    dest: "{{ web_root | default('/var/www/html') }}/index.php"
    owner: www-data
    group: www-data
    mode: '0644'
    backup: yes
  when: "'web_servers' in group_names"

- name: Deploy health check endpoint
  ansible.builtin.copy:
    src: health_check.php
    dest: "{{ web_root | default('/var/www/html') }}/health_check.php"
    owner: www-data
    group: www-data
    mode: '0644'
  when: "'web_servers' in group_names"
```

**Step 7.2: Create config.php template**

```yaml
# production/roles/app/templates/config.php.j2
<?php
/**
 * Application Configuration
 * Generated by Ansible on {{ ansible_date_time.iso8601 }}
 */

// Database configuration
define('DB_HOST', '{{ groups['db_servers'] | first }}');
define('DB_PORT', {{ mysql_port | default(3306) }});
define('DB_NAME', '{{ vault_mysql_app_db }}');
define('DB_USER', '{{ vault_mysql_app_user }}');
define('DB_PASS', '{{ vault_mysql_app_password }}');

// Application settings
define('APP_ENV', '{{ app_environment | default('production') }}');
define('APP_DEBUG', {{ app_debug | default('false') | lower }});
define('APP_SECRET', '{{ vault_app_secret_key }}');
define('APP_TIMEZONE', '{{ server_timezone | default('UTC') }}');

// Security
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
date_default_timezone_set(APP_TIMEZONE);

// Database connection
try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME,
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );
    define('DB_CONNECTED', true);
} catch (PDOException $e) {
    define('DB_CONNECTED', false);
    error_log('Database connection failed: ' . $e->getMessage());
}
?>
```

**Step 7.3: Create index.php template**

```yaml
# production/roles/app/templates/index.php.j2
<?php
/**
 * Application Homepage
 * Generated by Ansible
 */
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LEMP Stack - Web Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .status { padding: 15px; border-radius: 4px; margin: 10px 0; }
        .success { background: #d4edda; color: #155724; }
        .error { background: #f8d7da; color: #721c24; }
        .info { background: #cce5ff; color: #004085; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        td, th { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    </style>
</head>
<body>
    <div class="container">
        <h1>LEMP Stack Deployment</h1>
        <p>This application is running on <?php echo php_uname('n'); ?></p>
        
        <div class="status <?php echo DB_CONNECTED ? 'success' : 'error'; ?>">
            <strong>Database Status:</strong> 
            <?php echo DB_CONNECTED ? 'Connected to ' . DB_NAME : 'Connection Failed'; ?>
        </div>
        
        <div class="status info">
            <strong>Server Information:</strong>
            <table>
                <tr><td>Hostname</td><td><?php echo gethostname(); ?></td></tr>
                <tr><td>PHP Version</td><td><?php echo phpversion(); ?></td></tr>
                <tr><td>Server Software</td><td><?php echo $_SERVER['SERVER_SOFTWARE']; ?></td></tr>
                <tr><td>Environment</td><td><?php echo APP_ENV; ?></td></tr>
                <tr><td>Timestamp</td><td><?php echo date('Y-m-d H:i:s'); ?></td></tr>
            </table>
        </div>
        
        <p><a href="/health_check.php">Health Check</a></p>
    </div>
</body>
</html>
```

**Step 7.4: Create health check file**

```php
<?php
// Health check endpoint - returns JSON status
header('Content-Type: application/json');

$health = [
    'status' => 'healthy',
    'timestamp' => date('c'),
    'checks' => [
        'php' => true,
        'database' => DB_CONNECTED,
        'disk_space' => disk_free_space('/') > 1024 * 1024 * 100, // 100MB minimum
    ]
];

// Set overall status
$health['status'] = (DB_CONNECTED && $health['checks']['disk_space']) ? 'healthy' : 'unhealthy';
$health['overall'] = ($health['status'] === 'healthy') ? 'pass' : 'fail';

http_response_code($health['status'] === 'healthy' ? 200 : 503);
echo json_encode($health, JSON_PRETTY_PRINT);
?>
```

### Phase 8: Main Playbook

**Step 8.1: Create the site.yml playbook**

```yaml
# production/playbooks/site.yml
---
- name: Deploy LEMP Stack Infrastructure
  hosts: all
  gather_facts: true
  become: true
  any_errors_fatal: true  # Stop everything if anything fails
  
  pre_tasks:
    - name: Display deployment info
      ansible.builtin.debug:
        msg: |
          ========================================
          Starting deployment to {{ inventory_hostname }}
          Groups: {{ group_names | join(', ') }}
          ========================================

    - name: Verify connectivity
      ansible.builtin.ping:

  roles:
    - role: common
      tags: [common, base]

    - role: firewall
      tags: [firewall, security]
      when: "'lb_servers' in group_names or 'web_servers' in group_names"

  post_tasks:
    - name: Display completed setup
      ansible.builtin.debug:
        msg: "Base configuration complete for {{ inventory_hostname }}"

- name: Deploy Database Tier
  hosts: db_servers
  gather_facts: true
  become: true
  any_errors_fatal: true
  
  roles:
    - role: database
      tags: [database, db]

- name: Deploy Web Server Tier
  hosts: web_servers
  gather_facts: true
  become: true
  any_errors_fatal: true
  
  roles:
    - role: webserver
      tags: [webserver, web, php]

    - role: app
      tags: [app, application]

- name: Deploy Load Balancer Tier
  hosts: lb_servers
  gather_facts: true
  become: true
  any_errors_fatal: true
  
  roles:
    - role: loadbalancer
      tags: [loadbalancer, lb]

  post_tasks:
    - name: Verify load balancer configuration
      ansible.builtin.uri:
        url: "http://{{ inventory_hostname }}/lb-health"
        return_content: true
      register: lb_health
      failed_when: "'healthy' not in lb_health.content"
```

### Phase 9: Deployment Checklist

Before running the playbook, verify all prerequisites:

```
[ ] AWS/Vagrant/Local VMs are running and accessible
[ ] SSH key-based authentication is configured
[ ] Ansible is installed on control node (ansible --version)
[ ] All inventory hostnames resolve or have ansible_host set
[ ] Vault password is available (store in ~/.vault_pass or use --ask-vault-pass)
[ ] All roles are in the roles/ directory
[ ] ansible.cfg points to correct inventory
[ ] Python 3 is installed on all target hosts
[ ] Target hosts have sudo access for ansible_user
[ ] Security groups/firewall allows SSH (port 22)
```

### Phase 10: Running the Deployment

```bash
# Navigate to production directory
cd production

# Verify inventory is correct
ansible-inventory -i inventory/hosts.yml --graph

# Syntax check all playbooks
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check

# Run the deployment (with vault password prompt)
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --ask-vault-pass

# Or with vault password file
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --vault-password-file ~/.vault_pass
```

---

## Checkpoints

Throughout the deployment, verify at each checkpoint:

### Checkpoint 1: Base Configuration
```bash
# Verify common role completed on all hosts
ansible all -i inventory/hosts.yml -m ansible.builtin.ping
```

### Checkpoint 2: Database Deployment
```bash
# Verify MySQL is running
ansible mysql01 -i inventory/hosts.yml -m ansible.builtin.shell -a "systemctl status mysql | grep Active"

# Test MySQL connectivity from web servers
ansible web_servers -i inventory/hosts.yml -m ansible.builtin.shell -a "mysql -h mysql01 -u webapp -p -e 'SELECT 1;'"
```

### Checkpoint 3: Web Servers
```bash
# Verify Nginx is running
ansible web_servers -i inventory/hosts.yml -m ansible.builtin.shell -a "systemctl status nginx | grep Active"

# Test web server responds
ansible web_servers -i inventory/hosts.yml -m ansible.builtin.uri -a "url=http://localhost/health"
```

### Checkpoint 4: Load Balancer
```bash
# Verify load balancer routes to web servers
ansible lb01 -i inventory/hosts.yml -m ansible.builtin.uri -a "url=http://localhost/lb-health"

# Test round-robin by hitting multiple times
for i in {1..10}; do curl -s http://lb01/health_check.php | grep Hostname; done
```

### Checkpoint 5: Application End-to-End
```bash
# Access application through load balancer
curl -s http://lb01/ | grep -E '(LEMP|Database|healthy)'

# Verify database connection from application
curl -s http://lb01/health_check.php
```

---

## Hints for Troubleshooting

### Hint 1: Connection Failures

If Ansible cannot connect to hosts:
- Verify SSH key authentication works: `ssh -i ~/.ssh/id_rsa ubuntu@192.168.1.10`
- Check the target user has sudo privileges
- Verify the host is reachable: `ping 192.168.1.10`

### Hint 2: MySQL Connection Issues

If web servers cannot connect to MySQL:
- Check MySQL is listening on the correct interface: `netstat -tlnp | grep 3306`
- Verify the user has permission from the web server host: `mysql -e "SHOW GRANTS FOR 'webapp'@'%';"`
- Check firewall allows port 3306 between subnets

### Hint 3: Nginx Configuration Errors

If Nginx fails to reload:
- Test configuration syntax: `nginx -t`
- Check error logs: `tail -f /var/log/nginx/error.log`
- Verify PHP-FPM socket exists: `ls -la /var/run/php/php*-fpm.sock`

### Hint 4: Vault Password Issues

If Ansible cannot decrypt vault file:
- Verify the vault file is encrypted: `head -1 inventory/group_vars/all/vault.yml` should show `$ANSIBLE_VAULT`
- Use `--ask-vault-pass` for interactive entry
- Check vault password file has no trailing newlines

### Hint 5: Handler Not Running

If a handler (like "Restart Nginx") does not run:
- The task must notify the handler by name: `notify: Restart Nginx`
- Check the task actually reported a change (handlers only run on change)
- Use `--force-handlers` flag if tasks fail after notification

---

## Extensions and Next Steps

### Extension 1: Add TLS/SSL

Add HTTPS support to the load balancer:

1. Install `certbot` on the load balancer
2. Use the `community.crypto.openssl_certificate` module
3. Modify the load balancer template to include port 443

### Extension 2: Implement Rolling Updates

Modify the playbook to use `serial: 1` for web servers, enabling zero-downtime deployments:

```yaml
- name: Deploy Web Server Tier (Rolling)
  hosts: web_servers
  serial: 1  # Update one server at a time
  # ... rest of configuration
```

### Extension 3: Add Monitoring

Integrate with Prometheus/node_exporter by adding a monitoring role:

```yaml
- name: Install node exporter
  ansible.builtin.yum:
    name: node_exporter
    state: present
```

### Extension 4: CI/CD Integration

Connect the deployment to a CI/CD pipeline:

1. Store vault password in a CI secret
2. Use `ansible-playbook` in CI workflow
3. Add test stage after deployment: `ansible-playbook playbooks/site-check.yml`

### Extension 5: Testing with Molecule

Add Molecule tests to each role for infrastructure testing:

```bash
cd roles/database
molecule init scenario
molecule test
```

---

## Summary

This capstone project integrated all major Ansible concepts:

- **Chapter 1-4**: Inventory configuration (static hosts, groups, variables)
- **Chapter 6**: Variable management (encrypted vault, group vars, host vars)
- **Chapter 7**: Handlers (restart Nginx on config change, reload MySQL)
- **Chapter 8-9**: Roles (6 distinct roles: common, firewall, database, webserver, loadbalancer, app) and Jinja2 templates
- **Chapter 10**: Conditionals (server-type-specific tasks) and loops (iterating over web servers in upstream)
- **Chapter 11**: Vault-encrypted secrets (database passwords, app keys)
- **Chapter 12**: Error handling (`any_errors_fatal: true`, blocks for deployment phases)
- **Chapter 13**: Could integrate dynamic inventory for cloud environments
- **Chapter 14**: Using collection modules (`community.general.ufw`, `community.mysql.mysql_db`)

The result is a production-ready, three-tier web application deployment that you can adapt to real infrastructure needs.

## Additional Resources

- [Ansible User Guide](https://docs.ansible.com/ansible/latest/user_guide/) - Complete Ansible documentation
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html) - Recommended playbook organization patterns
- [Molecule Documentation](https://molecule.readthedocs.io/) - Testing Ansible roles with Molecule
- [Ansible LAMP Stack Example](https://docs.ansible.com/ansible/latest/tutorials/) - Official Ansible tutorials for common infrastructure patterns

<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../14-collections/" style="color:#8892b0; text-decoration:none;">← Previous: Collections</a>
  <div style="display:flex; gap:12px;">
    <a href="../" style="color:#8892b0; text-decoration:none; border:1px solid #2a3a5c; padding:8px 18px; border-radius:8px;">🏠 Back to Home</a>
    <a href="https://nkydigitech.github.io/ansible-lab/" style="background:linear-gradient(135deg,#00d4aa,#6c63ff); color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:700;">🧪 Go to Student Lab →</a>
  </div>
</div>

<div style="background:linear-gradient(135deg,rgba(108,99,255,0.1),rgba(0,212,170,0.1)); border:1px solid rgba(108,99,255,0.3); border-radius:12px; padding:20px; text-align:center; margin-top:24px;">
🎉 <strong>Congratulations!</strong> You completed Zero to Production. Build your own project and share it on LinkedIn — tag me!
</div>
