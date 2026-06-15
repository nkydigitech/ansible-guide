# Module 02: Your First Ansible Command — Quick Test

You've installed Ansible and run `ansible --version`. Now let's **do something real** to prove it works.

There are two paths. Read both and pick the one that matches your environment.

---

## Path A — Native Install (Real Ubuntu/Debian VM or WSL)

If you are on a real Linux system with `sudo`, use this path. It installs nginx directly.

### Step 1 — Install nginx with Ansible (ad-hoc command)

```bash
ansible localhost -m ansible.builtin.apt \
  -a "name=nginx state=present update_cache=yes" \
  --become
```

**Expected output:**
```
localhost | CHANGED => {
    "cache_updated": true,
    "changed": true,
    "stderr": "",
    "stdout": "Reading package lists...\nBuilding dependency tree...\n"
}
```

> If you see `FAILED` or `No package matching 'nginx'`, run `sudo apt-get update` manually first, then retry.

---

### Step 2 — Start nginx

```bash
ansible localhost -m ansible.builtin.systemd \
  -a "name=nginx state=started enabled=yes" \
  --become
```

**Expected output:**
```
localhost | CHANGED => {
    "changed": true,
    "name": "nginx",
    "status": "started"
}
```

---

### Step 3 — Verify it's serving

```bash
curl -s http://localhost | head -5
```

**Expected output:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

---

### Step 4 — Open in your browser

Point your browser to `http://localhost` or `http://<your-vm-ip>`.

**You should see:** The nginx welcome page.

**Screenshot this.** Save it to `docs/assets/screenshots/module-02-installation/`.

---

## Path B — Docker Fallback (Codespaces or restricted environments)

If `sudo apt-get` is blocked (e.g., GitHub Codespaces), use Docker. This path proves Ansible works without needing root package installs.

### Step 1 — Run nginx in Docker

```bash
docker run -d --name first-nginx -p 8080:80 nginx:alpine
```

**Expected output:** A long container ID, e.g.,
```
8a3b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b
```

---

### Step 2 — Prove Ansible can see it

```bash
ansible localhost -m ansible.builtin.command \
  -a "docker exec first-nginx nginx -v"
```

**Expected output:**
```
localhost | CHANGED | rc=0 >>
nginx version: nginx/1.31.1
```

> This proves Ansible is installed, can connect to localhost, and can run commands on your behalf.

---

### Step 3 — Verify the web server

```bash
curl -s http://localhost:8080 | head -5
```

**Expected output:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

---

### Step 4 — Open in your browser

Point your browser to `http://localhost:8080`.

**You should see:** The nginx welcome page.

**Screenshot this.** Save it to `docs/assets/screenshots/module-02-installation/`.

---

### Step 5 — Clean up

```bash
docker rm -f first-nginx
```

---

## What this taught you

Even though it was just a few lines, you just:

1. **Connected Ansible to a target** (localhost)
2. **Ran a module** (`ansible.builtin.apt`, `ansible.builtin.systemd`, or `ansible.builtin.command`)
3. **Saw the exact JSON output** Ansible returns for every task
4. **Verified the result in a browser** — the real test that automation worked

This is the pattern for every module going forward:
> **Run the command → Check the output → Verify in the real world → Screenshot it.**

---

## Did you understand? Check yourself

- [ ] Can you explain the difference between `ansible` (ad-hoc) and `ansible-playbook` (saved scripts)?
- [ ] What flag makes Ansible run commands as root? (`--become`)
- [ ] What does `CHANGED` in the output mean vs `ok`?
- [ ] Where does Ansible look for inventory if you don't pass `-i`?

If you can't answer these in your own words, re-read Chapter 2 before moving to Chapter 3.
