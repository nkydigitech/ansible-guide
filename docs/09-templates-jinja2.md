# Chapter 9: Templates with Jinja2

## Learning Objectives

- Understand what Jinja2 templating is and why it is essential for generating configuration files
- Use the `template` module to deploy rendered templates to remote hosts
- Apply variable substitution with `{{ variable }}` in templates
- Use Jinja2 filters to transform variable values (`upper`, `lower`, `default`, `join`, `map`)
- Write conditional blocks in templates with `{% if %}` / `{% elif %}` / `{% else %}`
- Write loops in templates with `{% for %}` to generate repeated configuration blocks
- Control whitespace with `{%-` and `-%}` to prevent extra blank lines in output

## Explanation

Configuration files rarely consist of purely static content. Most real-world services need configuration that adapts to the environment — different ports, hostnames, IP addresses, feature flags, and more. In Chapter 5 and Chapter 6, you learned how variables store these values. In this chapter, you learn how Jinja2 templates **render** those values into real configuration files.

Jinja2 is a Python templating engine that Ansible adopted wholesale. It lets you embed expressions, conditionals, and loops directly in text files. When Ansible processes a template, it evaluates all Jinja2 expressions and produces a final static file with the rendered output.

### The Template Module

The `template` module copies a Jinja2 template file to a remote host, rendering it first:

```yaml
- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2      # Source template on the control node
    dest: /etc/nginx/nginx.conf  # Destination on the remote host
    owner: root
    group: root
    mode: '0644'
    validate: nginx -t      # Optional: validate config before installing
    backup: yes             # Optional: backup existing file
```

Key differences from the `copy` module:
- `copy` deploys static files as-is
- `template` processes the file through Jinja2 before deploying

### Variable Substitution

Inside a template, use `{{ variable_name }}` to insert a variable's value:

```jinja2
# nginx.conf.j2
user {{ nginx_user }};
worker_processes {{ ansible_facts['processor_vcpus'] }};

events {
    worker_connections {{ max_connections }};
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent"';

    sendfile on;
    keepalive_timeout {{ keepalive_timeout }};
}
```

When rendered, Ansible substitutes every `{{ }}` expression with the variable's value at runtime.

### Jinja2 Filters

Filters transform variable values before rendering. They are applied with a pipe (`|`):

```jinja2
# Jinja2 built-in filters
{{ name | upper }}              # "john doe" → "JOHN DOE"
{{ name | lower }}              # "JOHN DOE" → "john doe"
{{ name | title }}              # "john doe" → "John Doe"
{{ port | default(80) }}        # Use 80 if port is undefined
{{ list | join(", ") }}         # Join list items with ", "
{{ path | basename }}           # Get filename from path
{{ version | replace(".", "_") }} # Replace "." with "_"
{{ value | int }}               # Convert to integer
{{ config | bool }}             # Convert to boolean
{{ items | length }}            # Number of items in list
{{ text | wordwrap(80) }}       # Wrap text at 80 columns
```

Ansible adds many custom filters beyond the built-in Jinja2 ones:

```jinja2
# Ansible-specific filters
{{ ansible_facts['default_ipv4']['address'] | ipaddr }}       # Validate IP
{{ my_list | unique }}                                        # Remove duplicates
{{ my_list | difference(other_list) }}                        # Set difference
{{ dict | dict2items }}                                       # Convert dict to list
{{ items | json_query('[*].name') }}                          # JMESPath query
{{ password | password_hash('sha512') }}                      # Hash password
{{ lookup('env', 'HOME') }}                                   # Environment variable
```

> **Pro Tip**: Ansible has two categories of filters. Jinja2 built-in filters (like `upper`, `lower`, `join`) work everywhere in Ansible — in templates AND in playbook expressions. Ansible-specific filters (like `password_hash`, `from_yaml`) only work in Ansible's Jinja2 context, not in plain Jinja2. When in doubt, test in a `debug` task first.

### Conditionals in Templates

Use `{% if %}` blocks to conditionally include sections of a template:

```jinja2
# app.conf.j2
server {
    listen {{ http_port }};
    server_name {{ server_name }};

    {% if enable_ssl %}
    ssl_certificate     /etc/ssl/certs/{{ cert_file }};
    ssl_certificate_key /etc/ssl/private/{{ cert_key }};
    ssl_protocols       TLSv1.2 TLSv1.3;
    {% endif %}

    {% if enable_gzip %}
    gzip on;
    gzip_types text/plain application/json application/javascript;
    {% endif %}

    root {{ document_root }};

    {% if maintenance_mode %}
    return 503;
    {% endif %}

    location / {
        index index.html;
    }
}
```

The corresponding variables:

```yaml
# In defaults/main.yml or playbook vars
http_port: 80
server_name: example.com
document_root: /var/www/html
enable_ssl: true
enable_gzip: true
maintenance_mode: false
cert_file: fullchain.pem
cert_key: privkey.pem
```

### Loops in Templates

Use `{% for %}` to generate repeated blocks from a list:

```jinja2
# hosts.conf.j2
# Generated hosts file for {{ inventory_hostname }}
# Generated at {{ ansible_facts['date_time']['iso8601'] }}

{% for host in groups['all'] %}
{{ hostvars[host]['ansible_facts']['default_ipv4']['address'] }} {{ host }}
{% endfor %}
```

A more practical example — generating upstream server entries:

```jinja2
# upstream.conf.j2
upstream backend {
    {% for backend in upstreams %}
    server {{ backend.host }}:{{ backend.port }}{% if backend.max_fails is defined %} max_fails={{ backend.max_fails }}{% endif %};
    {% endfor %}
    keepalive {{ upstream_keepalive }};
}
```

With this variable definition:

```yaml
# In playbook or defaults
upstreams:
  - host: 10.0.1.10
    port: 8080
    max_fails: 3
  - host: 10.0.1.11
    port: 8080
    max_fails: 3
  - host: 10.0.1.12
    port: 8080
upstream_keepalive: 32
```

### Whitespace Control

By default, Jinja2 preserves all whitespace, including the blank lines around control structures. This can produce ugly output:

```jinja2
# Uncontrolled whitespace — produces blank lines
server_name {{ server_name }};

{% if enable_logging %}
access_log /var/log/nginx/access.log;
{% endif %}

```

You can control this with `{%-` (strip leading whitespace) and `-%}` (strip trailing whitespace):

```jinja2
# Controlled whitespace — clean output
server_name {{ server_name }};
{%- if enable_logging %}
access_log /var/log/nginx/access.log;{% endif %}
```

`{%-` before a tag strips whitespace before the tag. `-%}` after a tag strips whitespace after the tag.

More examples:

```jinja2
{#- Strip blank lines around for-loop #}
{% for item in items -%}
{{ item.name }}
{%- endfor %}

{#- Inline conditional (no extra whitespace) #}
max_connections {{ max_conn | default(1000) -}};
```

### Template Validation

The `validate` parameter on the `template` module runs a command before copying the rendered file to its final destination. If the validation command returns non-zero, the template is not deployed:

```yaml
- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: nginx -t -c %s
  notify: Reload nginx
```

The `%s` placeholder is replaced with the path to the temporary file containing the rendered template. This lets the validation tool (nginx, apachectl, postgresql, etc.) check the config without writing it to the final location first.

> **Pro Tip**: Always use `validate` for critical service configurations. It catches syntax errors before they take down a running service. A misconfigured nginx.conf that fails to reload leaves you with a broken web server — validation prevents this.

## Examples

### Example 1: Nginx Virtual Host Template

```jinja2
{# templates/nginx_vhost.conf.j2 #}
{# Nginx virtual host configuration #}
{# Generated by Ansible for {{ inventory_hostname }} #}

server {
    listen {{ http_port }}{% if http_port == 80 %} default_server{% endif %};
    server_name {{ server_name }};

    root {{ document_root }};
    index {{ index_files | join(' ') }};

    access_log /var/log/nginx/{{ inventory_hostname }}-access.log;
    error_log /var/log/nginx/{{ inventory_hostname }}-error.log;

    {% if enable_ssl %}
    listen {{ http_port | int + 1 }} ssl http2;
    ssl_certificate /etc/ssl/certs/{{ ssl_cert_file }};
    ssl_certificate_key /etc/ssl/private/{{ ssl_cert_key }};
    ssl_protocols TLSv1.2 TLSv1.3;
    {% endif %}

    location / {
        try_files $uri $uri/ =404;
    }

    {% for extra_location in extra_locations %}
    location {{ extra_location.path }} {
        proxy_pass {{ extra_location.proxy_to }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    {% endfor %}

    location ~ /\.ht {
        deny all;
    }
}
```

### Example 2: User Management Template with Loops and Conditionals

```jinja2
{# templates/users.csv.j2 #}
# User management file
# Environment: {{ env | upper }}
{% for user in users %}
{{ user.name }},{{ user.uid }},{{ user.shell }},{{ user.home }}{% if user.groups is defined %},{{ user.groups | join(':') }}{% endif %}
{% endfor %}
```

With this data structure:

```yaml
users:
  - name: alice
    uid: 1001
    shell: /bin/bash
    home: /home/alice
    groups: [wheel, developers]
  - name: bob
    uid: 1002
    shell: /bin/zsh
    home: /home/bob
  - name: service
    uid: 2001
    shell: /bin/false
    home: /opt/service
```

### Example 3: sysctl Configuration Template

```jinja2
{# templates/sysctl.conf.j2 #}
# Kernel sysctl parameters
# Generated by Ansible
# Host: {{ inventory_hostname }}
# Date: {{ ansible_facts['date_time']['iso8601'] }}

{% for param in sysctl_params %}
{{ param.name }} = {{ param.value }}
{% endfor %}

# Dynamic tracking (if enabled)
{% if track_dynamic %}
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
{% endif %}
```

## Hands-On Exercises

### Exercise 1: Template Your Own nginx.conf
**Goal**: Create a complete nginx.conf.j2 template that adapts to different environments.

1. Create `templates/nginx.conf.j2` with these configurable sections:
   - `worker_processes` (use `ansible_facts['processor_vcpus']` directly)
   - `worker_connections` (variable)
   - A `server` block with `listen port` and `server_name` (variables)
   - A `location /` block with `root` (variable)
2. Create a playbook with these variables:
   ```yaml
   nginx_port: 8080
   server_name: myapp.example.com
   doc_root: /var/www/html
   max_connections: 1024
   ```
3. Use the `template` module to deploy to localhost.
4. Use the `validate: nginx -t -c %s` parameter to verify syntax.
5. Run the playbook, then run `nginx -t` manually to verify.
6. Change `nginx_port` to `9090` and run again, verifying the config updates.

**Expected outcome**: First run generates a valid nginx.conf with port 8080. Second run generates a valid config with port 9090. `nginx -t` passes on both.

**Hint**: Use `ansible_facts['processor_vcpus']` directly in the template without the `{{ }}` wrapper — it's already an expression. Or use `{{ ansible_facts['processor_vcpus'] }}` — both work.

---

### Exercise 2: Loop Over a List in a Template
**Goal**: Generate an `/etc/hosts` file from your inventory using a `{% for %}` loop.

1. Create a template `templates/hosts.j2` that iterates over `groups['all']`.
2. For each host in the inventory, print: `IP_address hostname`
3. Use `hostvars[item]['ansible_facts']['default_ipv4']['address']` to get the IP.
4. Add a filter to handle hosts that might not have an IPv4 address: use a conditional or `default` filter.
5. Deploy the template to `/tmp/hosts_generated` using the `template` module.

**Expected outcome**: The generated file contains all hosts from your inventory with their IP addresses. Hosts without a reachable fact are handled gracefully (no error).

**Hint**: The `{% for host in groups['all'] %}` loop iterates over group membership strings. Use `hostvars[host]` to access each host's variables and facts. Add a `{% if hostvars[host]['ansible_facts']['default_ipv4'] is defined %}` guard.

---

### Exercise 3: Conditional Sections with Filters
**Goal**: Create a configuration file that conditionally includes sections based on variable values.

1. Create a template for a "health check" configuration file at `templates/healthcheck.conf.j2`.
2. Include these conditional sections:
   - SSL/TLS settings (only if `ssl_enabled | bool == True`)
   - Basic auth (only if `basic_auth_enabled | bool == True`)
   - Rate limiting (only if `rate_limit > 0`)
3. Use the `default` filter for all optional settings so the template works even when variables are missing.
4. Create a playbook that deploys this with different combinations of flags to test all branches.

**Expected outcome**: Running with `ssl_enabled=true, basic_auth_enabled=false, rate_limit=100` produces a config with SSL and rate limiting sections, but no basic auth section.

**Hint**: Use `{% if ssl_enabled | bool %}` to convert string "true" to boolean true. In YAML/ansible, booleans from `default` filters are already boolean, but variables from `--extra-vars` are often strings.

---

### Exercise 4: Whitespace Control for Clean Output
**Goal**: Understand how `{%-` and `-%}` affect template output.

1. Create two versions of a simple template: one with normal Jinja2 tags, one with whitespace control.
2. Both templates should generate a multiline config file with a conditional block.
3. Compare the output by running the playbook twice with each template.
4. Observe that normal tags produce extra blank lines, while `{%-` and `-%}` eliminate them.

**Expected outcome**: The version with whitespace control produces a clean config file without spurious blank lines. The normal version has blank lines where Jinja2 blocks were.

**Hint**: Use `cat -A` to see all characters including newlines and spaces in the generated file, which makes whitespace differences obvious.

---

### Exercise 5: Complex Nested Loop — Generate Reverse Proxy Config
**Goal**: Use nested `{% for %}` loops to generate a complex configuration.

1. Define a data structure representing multiple applications, each with multiple backends:
   ```yaml
   applications:
     - name: api
       port: 8080
       backends:
         - host: 10.0.1.10
           port: 9000
         - host: 10.0.1.11
           port: 9000
     - name: web
       port: 80
       backends:
         - host: 10.0.2.10
           port: 3000
         - host: 10.0.2.11
           port: 3000
         - host: 10.0.2.12
           port: 3000
   ```
2. Create a template that generates an HAProxy-style configuration:
   - For each app, create a `backend` section
   - Inside each backend, list all backends from the nested list
3. Deploy the template and inspect the output.

**Expected outcome**: The generated config has 2 backend sections (`api` and `web`) with 2 and 3 server entries respectively. All entries use values from the nested data structure.

**Hint**: This is the most challenging template exercise. Use `{% for app in applications %}` then inside that `{% for backend in app.backends %}`. Use `app.name` and `app.port` for the outer loop's section headers, and `backend.host` and `backend.port` for the inner loop's server lines.

## Summary

- Jinja2 templating lets Ansible generate dynamic configuration files from templates.
- The `template` module renders `.j2` files and deploys them to remote hosts.
- `{{ variable }}` substitutes variable values; `{{ variable | filter }}` applies filters.
- `{% if %}` / `{% elif %}` / `{% else %}` conditionally include template sections.
- `{% for %}` loops generate repeated blocks from lists.
- Whitespace control with `{%-` and `-%}` produces clean output without extra blank lines.
- Filters like `upper`, `lower`, `default`, `join`, `basename`, `int`, `bool`, and `replace` are commonly used.
- Always use `validate` on critical service configs to catch syntax errors before deployment.
- Ansible adds powerful filters like `password_hash`, `json_query`, and `dict2items`.

## Additional Resources

- [Jinja2 Documentation: Template Designer](https://jinja.palletsprojects.com/en/3.1.x/templates/) — The official Jinja2 template documentation.
- [Ansible Documentation: Jinja2 Filters](https://docs.ansible.com/ansible/latest/user_guide/templating.html) — All Ansible-specific filters with examples.
- [Ansible Template Module Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html) — Full reference for the template module parameters.