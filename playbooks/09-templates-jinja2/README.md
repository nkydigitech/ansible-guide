# Module 09: Templates & Jinja2

Runnable companion code for [docs/09-templates-jinja2.md](../../docs/09-templates-jinja2.md).
This module teaches dynamic config generation using Jinja2 templates.

---

## Part A: Localhost-safe template demo (run this first)

`template-demo.yml` creates `/tmp/ansible-template-demo/`, renders `app_config.conf.j2` with variables, filters, conditionals, and loops, then prints the rendered file.

No sudo. No packages. Works in Codespaces.

### Run the guided demo
```bash
cd playbooks/09-templates-jinja2
bash demo.sh
```

The demo shows:
- `--syntax-check` and `--list-tasks`
- `--check --diff` (no changes on the second run)
- Real run: renders template to `/tmp/ansible-template-demo/app_config.conf`
- Displays rendered content on screen

### Try filters yourself
```bash
cd playbooks/09-templates-jinja2
ansible-playbook template-demo.yml -e "app_name=MyApp" -e "listen_port=9090"
```

---

## Part B: Real server playbook (EC2)

`webserver-with-templates.yml` deploys an nginx config from `templates/nginx.conf.j2` on an Ubuntu EC2 instance.
**Do not run against localhost.**

### Prerequisites
- Ubuntu EC2 instance (t3.micro)
- SSH key configured

### Run
```bash
cd playbooks/09-templates-jinja2
ansible-playbook -i ../../inventory/ec2.ini webserver-with-templates.yml --check --diff
ansible-playbook -i ../../inventory/ec2.ini webserver-with-templates.yml
```

Browse to `http://<EC2_IP>` to verify.

---

## Part C: Exercise Playbooks

| # | Directory | What it teaches |
|---|-----------|----------------|
| 1 | `exercise-01/` | Variable substitution + filters (`upper`, `default`, `int`) |
| 2 | `exercise-02/` | `{% for %}` loop over a list |
| 3 | `exercise-03/` | `{% if %}` conditional blocks with boolean checks |
| 4 | `exercise-04/` | Whitespace control: compare noisy (`{% %}`) vs clean (`{%- %}`) |
| 5 | `exercise-05/` | Nested `{% for %}` loops for reverse-proxy config |

### Quick run
```bash
cd playbooks/09-templates-jinja2

ansible-playbook exercise-01/playbook.yml
ansible-playbook exercise-02/playbook.yml
ansible-playbook exercise-03/playbook.yml
ansible-playbook exercise-04/playbook.yml
ansible-playbook exercise-05/playbook.yml
```

---

## What to screenshot

1. **Rendered template output**
   - `cat /tmp/ansible-template-demo/app_config.conf` showing variables + filters + loops

2. **Exercise 4 comparison**
   - `noisy.conf` has blank lines around `{% for %}` blocks
   - `clean.conf` has no blank lines because of `{%-` and `-%}`

3. **Exercise 5 nested loops**
   - `haproxy.conf` with backend entries for `api` and `web`

4. **Real server (EC2)**
   - Browser showing nginx page
   - `nginx -t` passing the rendered config
