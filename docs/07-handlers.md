# Chapter 7: Handlers

## Learning Objectives

- Understand what handlers are and why they exist as a separate mechanism from tasks
- Write handlers using the `handlers` block and trigger them with `notify`
- Understand when and how handlers run (only when a task reports changes)
- Use `meta: flush_handlers` to force immediate handler execution
- Notify multiple handlers and use handler listening for grouped notifications
- Apply best practices for handler naming and organization

## Explanation

When you configure a service, you often need to restart it after changing its configuration. But restarting is a separate action from modifying the configuration — it should only happen if the configuration actually changed. This is exactly the problem handlers solve.

A **handler** is a task that only runs when explicitly triggered by another task. Think of it as an "interrupt" or "callback" that fires after a change is detected.

Handlers exist because of **idempotency**. If a task checks whether nginx is already configured correctly and it is, Ansible reports "ok" (no change). If we also unconditionally restarted nginx every time the playbook ran, we would be restarting a service even when nothing changed — that's not idempotent. Handlers ensure that side effects (like restarts) only happen when actual changes occurred.

### Basic Handler Syntax

A handler looks like a task but lives in the `handlers:` block of a play:

```yaml
---
- name: Configure nginx
  hosts: webservers
  tasks:
    - name: Copy nginx configuration
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart nginx

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started

  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

The `notify` directive on the `template` task references the handler by name. When the template task runs and detects a change (the file on the remote host differs from the source), it fires the `Restart nginx` handler.

> **Pro Tip**: Handler names must be unique within a play. If two handlers share the same name, only the first one will be called. Use descriptive, unique names like `Restart nginx on port change` rather than just `restart`.

### Handler Execution Order

Handlers run at the end of the play, after all tasks in all plays are complete. The order is determined by:

1. **Notification order**: Handlers run in the order they were first notified.
2. **Handler block order**: Within a single handler block, they run top to bottom.

Consider this example with two handlers:

```yaml
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify:
      - Restart nginx
      - Reload fail2ban

  - name: Update SSL certificate
    copy:
      src: cert.pem
      dest: /etc/ssl/certs/cert.pem
    notify: Restart nginx

handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted

  - name: Reload fail2ban
    service:
      name: fail2ban
      state: reloaded
```

Even though `Restart nginx` is notified twice, it only runs once (duplicate notifications are deduplicated). The order of execution will be: `Restart nginx` (first notified) → `Reload fail2ban`. If `Update SSL certificate` notified first, then `Reload fail2ban` → `Restart nginx`.

### Flushing Handlers with `meta: flush_handlers`

By default, handlers run at the end of each play. But sometimes you need a handler to run immediately — for example, to reload a configuration and then use the new configuration in a subsequent task.

You can force immediate handler execution with `meta: flush_handlers`:

```yaml
---
- name: Configure and test database
  hosts: databases
  tasks:
    - name: Update PostgreSQL configuration
      template:
        src: postgresql.conf.j2
        dest: /etc/postgresql/14/main/postgresql.conf
      notify: Restart PostgreSQL

    - name: Flush handlers to restart PostgreSQL now
      meta: flush_handlers

    - name: Verify database is accessible
      postgresql_query:
        db: myapp
        query: SELECT version();

    - name: Create application database
      postgresql_db:
        name: myapp
        state: present
      become: true
      become_user: postgres

  handlers:
    - name: Restart PostgreSQL
      service:
        name: postgresql
        state: restarted
```

In this example, `Restart PostgreSQL` runs right after `meta: flush_handlers`, before the `Verify database is accessible` task. This allows you to test the effects of the restart within the same play.

> **Pro Tip**: Use `meta: flush_handlers` sparingly. It breaks the normal flow where handlers run once at the end, which can surprise teammates. It is most useful for testing configurations or when subsequent tasks genuinely depend on the handler having run.

### Handler Listening

Sometimes you want multiple tasks to be able to trigger the same handler without hard-coding the handler name in each task. Ansible's **listener pattern** lets handlers "listen" for notifications by a logical topic rather than a specific name.

```yaml
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: "nginx service"

  - name: Update SSL certificate
    copy:
      src: cert.pem
      dest: /etc/ssl/certs/cert.pem
    notify: "nginx service"

  - name: Update nginx ports
    lineinfile:
      path: /etc/nginx/nginx.conf
      regexp: "^listen"
      line: "listen {{ http_port }};"
    notify: "nginx service"

handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted
    listen: "nginx service"

  - name: Reload fail2ban
    service:
      name: fail2ban
      state: reloaded
    listen: "nginx service"
```

Here, three different tasks all notify `"nginx service"`. Both handlers `Restart nginx` and `Reload fail2ban` listen to `"nginx service"` and both will be triggered. This decouples the notifier from the specific handler names, making it easier to add new handlers that react to the same event.

### Handler Naming Best Practices

Handlers follow the same naming rules as tasks (they are tasks technically). Best practices:

1. **Be specific**: `Restart nginx because config changed` is clearer than `restart`.
2. **Be unique**: No two handlers in the same play should share a name.
3. **Prefix by action**: Start with the action — `Reload`, `Restart`, `Restart if needed`.
4. **Indicate the service**: `Reload nginx` not `reload`.

### When Handlers Do Not Run

Handlers will NOT run in these situations:

- The triggering task reports `changed=false` (no change was made)
- The play fails before the triggering task completes
- A task with `changed_when: false` always reports ok, never changed, so it never triggers handlers

If you want a handler to always run (even if the preceding tasks didn't detect a change), you can force it with `meta: flush_handlers` in a separate task, but note this task will always report `ok` — it does not track whether any handlers actually ran.

## Examples

### Example 1: Multi-Service Handler Chain

```yaml
---
- name: Configure web application stack
  hosts: webservers
  vars:
    app_user: www-data
  tasks:
    - name: Update nginx configuration
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify:
        - Restart nginx
        - Reload fail2ban

    - name: Configure app settings
      template:
        src: app.conf.j2
        dest: /etc/myapp/app.conf
      notify: Restart myapp

    - name: Ensure nginx is enabled
      service:
        name: nginx
        enabled: yes

  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted

    - name: Reload fail2ban
      service:
        name: fail2ban
        state: reloaded

    - name: Restart myapp
      service:
        name: myapp
        state: restarted
```

### Example 2: Conditional Handler Notification

You cannot use a `when` clause on a `notify` directly. Instead, use a conditional inside a task that registers its result and then notifies:

```yaml
tasks:
  - name: Update configuration
    template:
      src: "{{ item }}.conf.j2"
      dest: "/etc/{{ item }}/{{ item }}.conf"
    loop:
      - nginx
      - myapp
    register: config_updates

  - name: Flush handlers if any config changed
    meta: flush_handlers
    when: config_updates is changed

handlers:
  - name: Restart services
    service:
      name: "{{ item }}"
      state: restarted
    loop:
      - nginx
      - myapp
```

### Example 3: Handler for Multiple Notify Names

```yaml
---
- name: Infrastructure configuration
  hosts: all
  tasks:
    - name: Update sysctl settings
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        state: present
        reload: yes
        sysctl_file: /etc/sysctl.d/99-custom.conf
      loop:
        - { name: 'net.ipv4.ip_forward', value: '1' }
        - { name: 'net.core.somaxconn', value: '4096' }
      notify: Apply sysctl changes

  handlers:
    - name: Apply sysctl changes
      command: sysctl --system
      listen: "Apply sysctl changes"
```

## Hands-On Exercises

### Exercise 1: First Handler
**Goal**: Create a playbook with a handler that only restarts a service when the configuration actually changes.

1. Create a directory structure: `files/nginx.conf` and a `playbook.yml`.
2. Write an nginx config file with a specific `server_name` value.
3. Write a playbook that:
   - Copies the nginx config to `/tmp/nginx.conf` on localhost
   - Has a handler named `Restart nginx mock` that uses `debug` to print "Restarting nginx..."
   - Uses `notify: Restart nginx mock`
4. Run the playbook once — observe the handler fires.
5. Run the playbook again without changes — observe the handler does NOT fire.
6. Change the `server_name` in the config file, run again — observe the handler fires again.

**Expected outcome**: First run shows `changed: true` and "Restarting nginx...". Second run shows `ok: true` (no change) and NO handler message. After editing the config, third run shows `changed: true` and handler fires again.

**Hint**: Handlers only run when a task's `changed` status is `true`. If the file content is identical, `copy` reports `ok`, not `changed`.

---

### Exercise 2: Handler Flush
**Goal**: Use `meta: flush_handlers` to run a handler immediately, then use its result.

1. Create a playbook that targets `localhost`.
2. Create a task that writes "version=1" to `/tmp/app.conf`.
3. Add a handler that reads `/tmp/app.conf` and sets a fact `app_version` from it.
4. Use `meta: flush_handlers` after the write task.
5. Add a subsequent task that asserts `app_version == "1"` using `assert`.

**Expected outcome**: The handler runs after the `flush_handlers` directive, reads the version, and the assertion passes.

**Hint**: This pattern is useful when subsequent tasks need to react to the state that the handler creates. Note that the handler's output must be registered for the subsequent task to use it.

---

### Exercise 3: Multiple Handlers with Listening
**Goal**: Use the listener pattern to trigger multiple handlers with a single notification.

1. Create a playbook with 3 tasks, each modifying a different file.
2. Each task notifies the same topic: `"infrastructure reload"`.
3. Create 2 handlers, both listening to `"infrastructure reload"`:
   - `handler1`: debug prints "Handler 1: reloading config"
   - `handler2`: debug prints "Handler 2: restarting daemon"
4. Run the playbook and verify both handlers fire.

**Expected outcome**: Even though only one task explicitly triggered `"infrastructure reload"`, both listeners fire because they both subscribed to that topic.

**Hint**: `listen` is a top-level key in the handler definition, alongside `name`, `service`, `command`, etc. It does not replace the handler name — it adds a topic subscription.

---

### Exercise 4: Handler Dependencies
**Goal**: Create a handler that depends on another handler running first.

1. Write a playbook with these tasks:
   - Task A: modifies `/tmp/base.conf`, notifies `Initialize base config`
   - Task B: uses `meta: flush_handlers` to run `Initialize base config` immediately
   - Task C: modifies `/tmp/app.conf`, notifies `Start application`
2. Create two handlers:
   - `Initialize base config`: uses `copy` to ensure a base config exists, then `set_fact` with `base_ready: true`
   - `Start application`: has a `debug` that prints "Application started" but only if `base_ready` is defined (use `when: base_ready is defined`)
3. Run the playbook twice — first with a fresh `/tmp/`, then after files exist.

**Expected outcome**: On first run, handler order matters — if `Start application` runs before `Initialize base config`, the conditional check fails. This demonstrates why handler order is important.

**Hint**: Handler execution order follows notification order, not handler block order. Use multiple `notify` directives or `meta: flush_handlers` strategically to control ordering.

---

### Exercise 5: Handler Debugging
**Goal**: Learn to troubleshoot handlers that are not firing as expected.

1. Create a playbook where a task's `changed_when` is set to `False`, and the task has a `notify`.
2. Run the playbook and observe: the task reports `ok` not `changed`, and the handler never fires.
3. Fix it by removing `changed_when: false` or setting it to a condition that evaluates to `true`.
4. Verify the handler now fires.

**Expected outcome**: With `changed_when: false`, no handler fires. Removing/changing it restores the handler behavior.

**Hint**: `changed_when` overrides Ansible's automatic change detection. If you set it to `false`, Ansible will never report the task as changed, and no handlers will be notified. This is sometimes used deliberately (e.g., for read-only `debug` tasks), but it has the side effect of suppressing handler notifications.

## Summary

- Handlers are tasks that only run when explicitly notified by another task that made changes.
- Use `notify: handler_name` to trigger a handler from a task.
- Handlers run at the end of each play in the order they were first notified (duplicates are removed).
- `meta: flush_handlers` forces all pending handlers to run immediately.
- The `listen` directive lets multiple handlers subscribe to the same logical topic.
- Handlers do not run if the triggering task did not report a change.
- Handler names must be unique within a play.
- Use `changed_when` carefully — setting it to `false` suppresses handler notifications.

## Additional Resources

- [Ansible Documentation: Handlers](https://docs.ansible.com/ansible/latest/user_guide/playbooks_handlers.html) — Official documentation on handlers and notifiers.
- [Ansible Handlers: Complete Guide (DigitalOcean)](https://www.digitalocean.com/community/tutorials/how-to-use-ansible-handlers-and-logic) — A practical tutorial with real-world examples.
- [Ansible Best Practices: Handler Organization (Red Hat)](https://www.ansible.com/blog/ansible-best-practices-modules) — Guidance on structuring handlers in large playbooks.