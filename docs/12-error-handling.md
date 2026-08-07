# Chapter 12: Error Handling and Debugging in Ansible

## Learning Objectives

- Understand how Ansible handles task failures by default and when to deviate from defaults
- Use `ignore_errors`, `failed_when`, and `changed_when` to customize Ansible's behavior
- Implement structured error handling with `block`, `rescue`, and `always` clauses
- Configure play-level failure handling with `any_errors_fatal` and `max_fail_percentage`
- Apply debugging techniques to troubleshoot failing playbooks

## Explanation

### Default Error Handling Behavior

By default, Ansible stops executing tasks on a host as soon as any task fails. This is the correct behavior for most scenarios—you do not want Ansible to continue installing packages on a server if the repository configuration failed, for example. The failing host is removed from the play's batch, and Ansible continues with remaining hosts.

However, real-world infrastructure often requires nuanced handling:
- Some tasks are expected to fail in certain conditions, and failure should not halt the playbook
- You may want to define "failure" based on your own criteria, not just the module's return code
- You might want cleanup tasks to run regardless of whether earlier tasks succeeded
- A failure in one part of a multi-tier application should halt the entire deployment

Ansible provides a rich set of constructs for these scenarios.

### Task-Level Error Handling

#### ignore_errors

The `ignore_errors` directive tells Ansible to continue executing subsequent tasks even if this task fails. Use it sparingly—it can hide real problems.

```yaml
tasks:
  - name: Try to create directory, but don't fail if it exists
    ansible.builtin.file:
      path: /opt/myapp
      state: directory
    ignore_errors: true
```

> **Pro Tip**: If you find yourself using `ignore_errors: true` often, ask whether the task should have a conditional (`when`) instead. Ignoring errors without understanding why they occurred is dangerous in production.

#### failed_when

The `failed_when` directive lets you define custom failure conditions. Instead of relying solely on the module's exit status, you specify a Jinja2 expression. When the expression evaluates to `true`, Ansible considers the task failed.

```yaml
- name: Check if the service is running
  ansible.builtin.command: systemctl is-active myapp
  register: service_status
  failed_when: "'active' not in service_status.stdout"
```

In this example, the task fails only if "active" is not in the command output. This is useful when a command exits with status 0 but produces output that indicates a problem.

#### changed_when

The `changed_when` directive controls when Ansible considers a task to have made changes. By default, Ansible infers this from the module. Sometimes the module's heuristic is incorrect.

```yaml
- name: Restart httpd
  ansible.builtin.service:
    name: httpd
    state: restarted
  register: httpd_restart
  changed_when: false  # Treat as always reporting "changed=false"
```

A more practical example: the `rpm_key` module might report "changed" even when the key was already present. You can refine this:

```yaml
- name: Import repository key if not already present
  ansible.builtin.rpm_key:
    key: https://example.com/gpgkey
    state: present
  register: rpm_result
  changed_when: "'imported' in rpm_result.stdout"
```

### Block, Rescue, and Always

The `block`, `rescue`, and `always` keywords provide structured error handling. They work similarly to try/except/finally in programming languages.

- **block**: Groups tasks together. Normal execution flows through the block.
- **rescue**: Tasks in this section run only if a task in the block failed.
- **always**: Tasks in this section run regardless of whether the block succeeded or failed.

```yaml
tasks:
  - name: Block example
    block:
      - name: Create application directory
        ansible.builtin.file:
          path: /opt/myapp
          state: directory
          owner: appuser
          mode: '0755'

      - name: Deploy application files
        ansible.builtin.copy:
          src: app/
          dest: /opt/myapp/

      - name: Start application service
        ansible.builtin.service:
          name: myapp
          state: started
    rescue:
      - name: Cleanup on failure
        ansible.builtin.file:
          path: /opt/myapp
          state: absent
        when: ansible_facts['distribution'] == "CentOS"

      - name: Alert on failure
        ansible.builtin.debug:
          msg: "Application deployment failed!"

    always:
      - name: Log deployment attempt
        ansible.builtin.shell:
          cmd: echo "$(date) - Deployment attempted for {{ inventory_hostname }}" >> /var/log/deploy.log
```

In this example:
- If all three tasks in the block succeed, `rescue` is skipped, but `always` runs
- If any task in the block fails, `rescue` runs (the CentOS-specific cleanup would be skipped on other distros due to the conditional), then `always` runs
- If `rescue` itself fails, `always` still runs

> **Pro Tip**: Blocks are also useful for applying `when` conditions to multiple tasks at once. Instead of repeating a `when` on every task, put all tasks in a block and apply the condition to the block itself.

### Play-Level Error Handling

#### any_errors_fatal

When `any_errors_fatal: true` is set at the play level, any failure on any host causes the entire play to abort immediately. This is critical for multi-tier deployments where continuing without one tier would break the application.

```yaml
- name: Deploy multi-tier application
  hosts: web_servers,app_servers,database_servers
  any_errors_fatal: true  # Any failure stops everything
  tasks:
    # ...
```

For example, if database setup fails, you do not want the web servers to continue configuring themselves to connect to a database that does not exist.

#### max_fail_percentage

When running a play against a group with `serial` set (controlling how many hosts update simultaneously), `max_fail_percentage` determines how many hosts can fail before Ansible stops the entire play.

```yaml
- name: Rolling update of application servers
  hosts: app_servers
  serial: 5  # Update 5 servers at a time
  max_fail_percentage: 20  # If more than 20% of the batch fails, abort
  tasks:
    - name: Update application
      ansible.builtin.yum:
        name: myapp
        state: latest
```

If 2 out of 5 servers fail (40%), the play stops because 40% > 20%. This prevents a scenario where most servers are updated but a few are left in a broken state.

### Forcing Handler Execution After Failures

By default, Ansible does not run handlers if a task fails before the handler is notified. The `force_handlers: true` directive changes this—when a handler is notified, it runs even if the play ultimately fails.

```yaml
- name: Application deployment
  hosts: app_servers
  force_handlers: true  # Run handlers even if play fails later
  tasks:
    - name: Deploy configuration
      ansible.builtin.template:
        src: app.conf.j2
        dest: /etc/myapp.conf

    - name: Reload application
      ansible.builtin.service:
        name: myapp
        state: reloaded
      notify: Restart application

    - name: Verify deployment (this might fail)
      ansible.builtin.shell: /opt/myapp/bin/healthcheck
      register: health
      failed_when: health.stdout != "OK"
  handlers:
    - name: Restart application
      ansible.builtin.service:
        name: myapp
        state: restarted
```

Even if the `Verify deployment` task fails, the `Restart application` handler still runs, ensuring the service is in a consistent state.

### The Debugger

Ansible includes a debugger that pauses playbook execution when a task fails, allowing you to inspect variables and retry with fixes. Enable it at the play or task level:

```yaml
- name: Debugging example
  hosts: localhost
  debugger: on_failed  # Options: on_failed, on_unreachable, on_skipped, always, never
  tasks:
    - name: Execute a command
      ansible.builtin.command: /bin/false
      register: result
```

When the task fails, you enter an interactive prompt where you can run Python commands to inspect `task_vars`, `result`, `task`, etc. This is useful for complex debugging but rarely used in production automation.

## Hands-On Exercises

### Exercise 1: Using ignore_errors

**Objective**: Handle expected failures gracefully without stopping the playbook.

**Steps**:
1. Create a playbook that attempts to create a user that might already exist:
   ```yaml
   ---
   - name: Handle existing user
     hosts: localhost
     gather_facts: false
     tasks:
       - name: Create application user
         ansible.builtin.user:
           name: appuser
           state: present
         ignore_errors: true

       - name: Continue with deployment
         ansible.builtin.debug:
           msg: "Deployment continues regardless"
   ```
2. Run the playbook twice—the second run should show the user already exists but not fail
3. Modify the playbook to register the result and display whether the user creation "failed"

**Expected Outcome**: The playbook completes successfully on both runs. The second run's `user` task reports a failure in its result but does not halt execution.

**Hint**: Check `result.failed` and `result.msg` in a registered variable to understand what happened even when ignoring errors.

---

### Exercise 2: Custom Failure Conditions with failed_when

**Objective**: Define what "failure" means beyond exit codes.

**Steps**:
1. Create a playbook that checks disk usage and fails if it's above 90%:
   ```yaml
   ---
   - name: Check disk space
     hosts: localhost
     gather_facts: true
     tasks:
       - name: Get root disk usage
         ansible.builtin.shell:
           cmd: df / | tail -1 | awk '{print $5}' | sed 's/%//'
         register: disk_usage

       - name: Warn if disk is running low
         ansible.builtin.debug:
           msg: "Disk usage is {{ disk_usage.stdout }}%"
         failed_when: disk_usage.stdout | int > 90
   ```
2. Run it—verify it succeeds when disk usage is normal
3. Modify the threshold to 0 to force a failure, observe the behavior

**Expected Outcome**: The task uses `failed_when` to determine failure based on the actual disk usage percentage, not just the command's exit code.

**Hint**: The `failed_when` expression must evaluate to `true` to trigger a failure. If you want failure when disk > 90, use `disk_usage.stdout | int > 90`.

---

### Exercise 3: Block/Rescue/Always Pattern

**Objective**: Implement structured error handling for a deployment scenario.

**Steps**:
1. Create a playbook with a block that attempts three operations:
   - Create a directory `/opt/demoapp`
   - Copy a file to that directory (use a nonexistent source to simulate failure)
   - Set permissions on the directory
2. Add a rescue block that logs the failure
3. Add an always block that always reports completion
4. Run the playbook and observe which blocks execute

**Expected Outcome**: The copy task fails, triggering the rescue block. The always block runs regardless of the failure.

**Hint**: In rescue, the `ansible_failed_result` variable contains the result of the failed task, including the error message.

---

### Exercise 4: Multi-Host Failure Handling

**Objective**: Understand `any_errors_fatal` and `max_fail_percentage` in rolling updates.

**Steps**:
1. Create an inventory with 5 test hosts (you can use localhost with different aliases)
2. Write a playbook that updates all hosts:
   ```yaml
   ---
   - name: Rolling update simulation
     hosts: test_hosts
     serial: 2
     any_errors_fatal: true
     max_fail_percentage: 50
     tasks:
       - name: Simulate task (fail on odd hosts)
         ansible.builtin.fail:
           msg: "Simulated failure"
         when: inventory_hostname[-1] in ['1', '3', '5']
       
       - name: Report success
         ansible.builtin.debug:
           msg: "{{ inventory_hostname }} updated successfully"
   ```
3. Run the playbook and observe that failures stop the entire play
4. Change `any_errors_fatal: false` and run again, noting the difference

**Expected Outcome**: With `any_errors_fatal: true`, one failure stops all remaining hosts. Without it, Ansible continues to the next batch.

**Hint**: You can simulate multiple hosts on localhost by adding entries like `test_host_1 ansible_connection=local` to your inventory.

---

### Exercise 5: Debugging with force_handlers

**Objective**: Ensure critical handlers run even when a play fails.

**Steps**:
1. Create a playbook with `force_handlers: true`
2. Add a handler that "restarts a service" (use the debug module to simulate)
3. Add a task sequence where:
   - Task 1 notifies the handler
   - Task 2 intentionally fails
4. Run the playbook and verify the handler still executes
5. Remove `force_handlers: true` and run again to compare

**Expected Outcome**: With `force_handlers: true`, the handler runs even though the play fails. Without it, the handler does not run after the failure.

**Hint**: The handler notification is consumed when the handler runs. Even if subsequent tasks fail, the handler has already executed by the time the failure occurs.

## Summary

- Ansible stops on task failure by default, which is appropriate for most scenarios
- `ignore_errors: true` continues execution after a failure but should be used sparingly
- `failed_when` and `changed_when` customize Ansible's assessment of task outcomes
- `block`/`rescue`/`always` provides structured error handling similar to try/except/finally
- `any_errors_fatal: true` makes any host failure stop the entire play
- `max_fail_percentage` controls how many simultaneous failures trigger a rolling-update abort
- `force_handlers: true` ensures notified handlers run even if the play fails later
- The debugger provides interactive inspection of failed task state

## Additional Resources

- [Error Handling in Ansible](https://docs.ansible.com/ansible/latest/user_guide/playbooks_error_handling.html) - Official documentation on all error handling constructs
- [Ansible Blocks Deep Dive](https://www.ansible.com/blog/ansible-by-example-part-5) - Practical examples of block/rescue/always patterns from Ansible Blog
- [Debugging Ansible Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_debugger.html) - Using the debugger to inspect and fix failures interactively

```md
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../11-vault/" style="color:#8892b0; text-decoration:none;">← Previous: Vault</a>
  <a href="../13-dynamic-inventory/" style="background:#6c63ff; color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:600;">Next: Dynamic Inventory →</a>
</div>
```
