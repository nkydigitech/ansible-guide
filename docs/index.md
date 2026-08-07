---
hide:
  - navigation
  - toc
---

<div style="background:#0a0e1a; border:1px solid #2a3a5c; border-left:4px solid #6c63ff; padding:14px 20px; border-radius:10px; margin-bottom:28px; display:flex; flex-wrap:wrap; gap:10px; align-items:center; justify-content:center; font-size:0.88rem; color:#e8eaf6;">
  <strong style="color:#fff;">🚀 Nkechi Ahanonye — Cloud & DevOps Engineer | Zero to Production: 15 Modules, Real Output, No Fluff</strong>
  <span style="display:flex; gap:14px; flex-wrap:wrap; align-items:center; justify-content:center;">
    <a href="https://github.com/nkydigitech/ansible_practical" style="color:#00d4aa; text-decoration:none; font-weight:600;">📦 17 Green Runs ✅</a>
    <span style="opacity:0.4;">|</span>
    <span style="color:#8892b0;">📖 You are here</span>
    <span style="opacity:0.4;">|</span>
    <a href="https://nkydigitech.github.io/ansible-lab/" style="color:#6c63ff; text-decoration:none; font-weight:600;">🧪 Student Lab</a>
    <span style="opacity:0.4;">|</span>
    <a href="https://www.linkedin.com/in/nkechi-ahanonye" style="color:#e8eaf6; text-decoration:none; font-weight:600;">💼 LinkedIn</a>
  </span>
</div>

<div style="background:#0a0e1a; border:1px solid #1a2340; border-radius:24px; padding:60px 40px; text-align:center; margin-bottom:40px;">

<div style="display:inline-flex; align-items:center; gap:8px; background:rgba(108,99,255,0.1); border:1px solid rgba(108,99,255,0.3); color:#6c63ff; font-size:0.75rem; font-weight:700; letter-spacing:0.1em; text-transform:uppercase; padding:6px 16px; border-radius:50px; margin-bottom:28px;">
🚀 FREE & OPEN SOURCE
</div>

<h1 style="font-size: clamp(2.5rem, 6vw, 4rem); font-weight:900; line-height:1.1; color:#fff; margin:0 0 20px 0;">
Master <span style="background:linear-gradient(135deg,#6c63ff,#00d4aa); -webkit-background-clip:text; -webkit-text-fill-color:transparent;">Ansible</span><br>
From Zero to Production
</h1>

<div style="width:60px; height:4px; background:linear-gradient(90deg,#6c63ff,#00d4aa); border-radius:2px; margin:24px auto;"></div>

<p style="color:#8892b0; font-style:italic; max-width:500px; margin:0 auto 8px auto; font-size:1.05rem; line-height:1.6;">
"I built this guide because beginners deserve better than scattered tutorials."
</p>

<p style="color:#8892b0; max-width:600px; margin:0 auto 32px auto; font-size:1.05rem; line-height:1.7;">
15 hands-on modules. Real playbooks. Actual terminal output. No fluff.
</p>

<a href="#what-makes-this-different" style="display:inline-flex; align-items:center; gap:8px; background:linear-gradient(135deg,#6c63ff,#8b5cf6); color:#fff; font-weight:700; padding:14px 28px; border-radius:12px; text-decoration:none; box-shadow:0 8px 30px rgba(108,99,255,0.4);">
Start Learning →
</a>

<div style="display:flex; justify-content:center; gap:40px; flex-wrap:wrap; margin-top:48px; border-top:1px solid #1a2340; padding-top:32px;">
  <div><div style="font-size:1.8rem; font-weight:800; color:#00d4aa;">15</div><div style="font-size:0.8rem; color:#8892b0;">Modules</div></div>
  <div><div style="font-size:1.8rem; font-weight:800; color:#6c63ff;">100%</div><div style="font-size:0.8rem; color:#8892b0;">Free</div></div>
  <div><div style="font-size:1.8rem; font-weight:800; color:#fff;">0→Pro</div><div style="font-size:0.8rem; color:#8892b0;">Skill Path</div></div>
  <div><div style="font-size:1.8rem; font-weight:800; color:#00d4aa;">Real</div><div style="font-size:0.8rem; color:#8892b0;">Output Shown</div></div>
</div>

</div>

## What makes this different?

Every module shows you **exactly what to expect** — real terminal output, not just code blocks. You see what success looks like before you run a single command.

### Modules 01-06: Beginner Foundation
- **01 Introduction** — What Ansible is, why it exists, and how it thinks differently
- **02 Installation** — Get Ansible running on Linux, Mac, Windows WSL with verified output
- **03 Ad-hoc Commands** — Run one-liners against real servers before writing playbooks
- **04 Inventory** — Tell Ansible which servers to talk to
- **05 First Playbook** — Write your first YAML playbook and deploy something real
- **06 Variables** — Define, scope, and override variables

### Modules 07-11: Intermediate Core
- **07 Handlers** — Trigger actions only when changes happen
- **08 Roles** — Organise playbooks into reusable, shareable structures
- **09 Templates & Jinja2** — Generate dynamic config files
- **10 Conditionals & Loops** — Control execution with `when` and `loop`
- **11 Vault** — Encrypt secrets so you can safely commit them to git

### Modules 12-15: Advanced Production
- **12 Error Handling** — Control failures, rescue broken tasks
- **13 Dynamic Inventory** — Pull live hosts from AWS, GCP, Azure
- **14 Collections** — Install and manage Galaxy collections
- **15 Capstone Project** — Build full production infrastructure from scratch

## What you will see in every module

<div style="background:#0d1117; border:1px solid #2a3a5c; border-radius:12px; padding:20px 24px; font-family:monospace; font-size:0.85rem; color:#abb2bf; margin:20px 0;">

<span style="color:#5c6370;">$</span> ansible-playbook site.yml -i inventory/hosts<br><br>
PLAY [web servers] *********************************************<br>
TASK [Gathering Facts] ***************************************** <span style="color:#98c379;">ok: [web01]  ok: [web02]</span><br>
TASK [Install nginx] ******************************************* <span style="color:#d19a66;">changed: [web01]  changed: [web02]</span><br><br>
PLAY RECAP *****************************************************<br>
<span style="color:#61afef;">web01</span> : ok=2 changed=1 unreachable=0 failed=0<br>
<span style="color:#61afef;">web02</span> : ok=2 changed=1 unreachable=0 failed=0

</div>

## About the author

**Nkechi Ahanonye — Cloud & DevOps Engineer | I turn manual, 3 AM-breaking deployments into 1-min automated pipelines with AWS + Ansible + Terraform**

DevOps practitioner passionate about making complex engineering accessible. This guide is part of the trilogy: [Practical (17 Green Runs)](https://github.com/nkydigitech/ansible_practical) → Guide → [Lab](https://nkydigitech.github.io/ansible-lab/)

[LinkedIn](https://www.linkedin.com/in/nkechi-ahanonye) | [GitHub](https://github.com/nkydigitech)
