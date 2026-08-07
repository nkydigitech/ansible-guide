<div style="background:linear-gradient(135deg,#6c63ff,#00d4aa); color:#000; padding:14px 20px; text-align:center; font-weight:800; border-radius:12px; margin-bottom:24px; box-shadow:0 8px 30px rgba(108,99,255,0.3);">
🚀 Nkechi Ahanonye — Cloud & DevOps Engineer | Zero to Production: 15 Modules, Real Output, No Fluff<br>
<span style="font-weight:600; font-size:0.9rem;">📦 <a href="https://github.com/nkydigitech/ansible_practical" style="color:#000; text-decoration:underline;">17 Green Runs ✅</a> | 📖 You are here (Guide) | 🧪 <a href="https://nkydigitech.github.io/ansible-lab/" style="color:#000; text-decoration:underline;">Student Lab</a> | 💼 <a href="https://www.linkedin.com/in/nkechi-ahanonye" style="color:#000; text-decoration:underline;">LinkedIn</a></span>
</div>
---
hide:
  - navigation
  - toc
---

<div class="hero">
  <div class="hero-badge">🚀 Free & Open Source</div>
  <h1>Master <span>Ansible</span><br>From Zero to Production</h1>
  <p class="hero-tagline">"I built this guide because beginners deserve better than scattered tutorials."</p>
  <p>15 hands-on modules. Real playbooks. Actual terminal output. No fluff.</p>
  <a href="01-introduction/" class="hero-cta">Start Learning →</a>
  <div class="hero-stats">
    <div class="stat">
      <span class="stat-number">15</span>
      <span class="stat-label">Modules</span>
    </div>
    <div class="stat">
      <span class="stat-number">100%</span>
      <span class="stat-label">Free</span>
    </div>
    <div class="stat">
      <span class="stat-number">0→Pro</span>
      <span class="stat-label">Skill Path</span>
    </div>
    <div class="stat">
      <span class="stat-number">Real</span>
      <span class="stat-label">Output Shown</span>
    </div>
  </div>
</div>

## What makes this different?

Every module shows you **exactly what to expect** — real terminal output, not just code blocks. You see what success looks like before you run a single command.

<div class="module-grid">
  <a href="01-introduction/" class="module-card">
    <div class="module-number">Module 01</div>
    <h3>Introduction</h3>
    <p>What Ansible is, why it exists, and how it thinks differently about automation.</p>
  </a>
  <a href="02-installation/" class="module-card">
    <div class="module-number">Module 02</div>
    <h3>Installation</h3>
    <p>Get Ansible running on Linux, Mac, and Windows WSL with verified output.</p>
  </a>
  <a href="03-ad-hoc-commands/" class="module-card">
    <div class="module-number">Module 03</div>
    <h3>Ad-hoc Commands</h3>
    <p>Run one-liners against real servers before writing a single playbook.</p>
  </a>
  <a href="04-inventory/" class="module-card">
    <div class="module-number">Module 04</div>
    <h3>Inventory</h3>
    <p>Tell Ansible which servers to talk to — static, grouped, and dynamic.</p>
  </a>
  <a href="05-first-playbook/" class="module-card">
    <div class="module-number">Module 05</div>
    <h3>First Playbook</h3>
    <p>Write your first YAML playbook and deploy something real in minutes.</p>
  </a>
  <a href="06-variables/" class="module-card">
    <div class="module-number">Module 06</div>
    <h3>Variables</h3>
    <p>Define, scope, and override variables across inventory, playbooks and roles.</p>
  </a>
  <a href="07-handlers/" class="module-card">
    <div class="module-number">Module 07</div>
    <h3>Handlers</h3>
    <p>Trigger actions only when changes happen — restart services the right way.</p>
  </a>
  <a href="08-roles/" class="module-card">
    <div class="module-number">Module 08</div>
    <h3>Roles</h3>
    <p>Organise playbooks into reusable, shareable role structures.</p>
  </a>
  <a href="09-templates-jinja2/" class="module-card">
    <div class="module-number">Module 09</div>
    <h3>Templates & Jinja2</h3>
    <p>Generate dynamic config files using Jinja2 expressions and filters.</p>
  </a>
  <a href="10-conditionals-loops/" class="module-card">
    <div class="module-number">Module 10</div>
    <h3>Conditionals & Loops</h3>
    <p>Control task execution with when clauses and loop over lists and dicts.</p>
  </a>
  <a href="11-vault/" class="module-card">
    <div class="module-number">Module 11</div>
    <h3>Vault</h3>
    <p>Encrypt secrets and sensitive data so you can safely commit them to git.</p>
  </a>
  <a href="12-error-handling/" class="module-card">
    <div class="module-number">Module 12</div>
    <h3>Error Handling</h3>
    <p>Control failures, ignore errors selectively, and rescue broken tasks.</p>
  </a>
  <a href="13-dynamic-inventory/" class="module-card">
    <div class="module-number">Module 13</div>
    <h3>Dynamic Inventory</h3>
    <p>Pull live host lists from AWS, GCP, Azure and other cloud providers.</p>
  </a>
  <a href="14-collections/" class="module-card">
    <div class="module-number">Module 14</div>
    <h3>Collections</h3>
    <p>Install, use, and manage Ansible Galaxy collections in your projects.</p>
  </a>
  <a href="15-capstone-project/" class="module-card">
    <div class="module-number">Module 15</div>
    <h3>Capstone Project</h3>
    <p>Build a full production infrastructure from scratch using everything you learned.</p>
  </a>
</div>

## What you will see in every module

<div class="output-box">
  <div class="output-box-title">📺 Expected Output</div>
  Every module includes the exact terminal output you should see when things work correctly — so you know immediately if something is wrong.
</div>

<div class="terminal">
  <div class="terminal-header">
    <div class="terminal-dot red"></div>
    <div class="terminal-dot yellow"></div>
    <div class="terminal-dot green"></div>
    <div class="terminal-title">ansible output example</div>
  </div>
  <div class="terminal-body">
    <span class="prompt">$</span> <span class="cmd">ansible-playbook site.yml -i inventory/hosts</span><br><br>
    <span class="info">PLAY [web servers] *********************************************</span><br><br>
    <span class="info">TASK [Gathering Facts] *****************************************</span><br>
    <span class="ok">ok: [web01]</span><br>
    <span class="ok">ok: [web02]</span><br><br>
    <span class="info">TASK [Install nginx] *******************************************</span><br>
    <span class="ok">changed: [web01]</span><br>
    <span class="ok">changed: [web02]</span><br><br>
    <span class="info">PLAY RECAP *****************************************************</span><br>
    <span class="ok">web01 : ok=2  changed=1  unreachable=0  failed=0</span><br>
    <span class="ok">web02 : ok=2  changed=1  unreachable=0  failed=0</span>
  </div>
</div>

## About the author

<div class="author-card">
  <div class="author-avatar">NA</div>
  <div class="author-info">
    <h3>Nkechi Ahanonye</h3>
    <p>Cloud & DevOps Engineer based in Lagos, Nigeria. Co-mentor at CloudAdvisory DMI program. I built this guide because I've seen too many beginners quit Ansible due to poor documentation. Connect on <a href="https://linkedin.com/in/nkechiahanonye">LinkedIn</a>.</p>
  </div>
</div>
