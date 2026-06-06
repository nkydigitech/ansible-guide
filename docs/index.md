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
  <div class="module-card">
    <div class="module-number">Module 01</div>
    <h3>Introduction</h3>
    <p>What Ansible is, why it exists, and how it thinks differently about automation.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 02</div>
    <h3>Installation</h3>
    <p>Get Ansible running on Linux, Mac, and Windows WSL with verified output.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 03</div>
    <h3>Ad-hoc Commands</h3>
    <p>Run one-liners against real servers before writing a single playbook.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 04</div>
    <h3>Inventory</h3>
    <p>Tell Ansible which servers to talk to — static, grouped, and dynamic.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 05</div>
    <h3>First Playbook</h3>
    <p>Write your first YAML playbook and deploy something real in minutes.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 06–10</div>
    <h3>Core Concepts</h3>
    <p>Variables, handlers, roles, Jinja2 templates, conditionals and loops.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 11–14</div>
    <h3>Advanced Skills</h3>
    <p>Vault secrets, error handling, dynamic inventory, and collections.</p>
  </div>
  <div class="module-card">
    <div class="module-number">Module 15</div>
    <h3>Capstone Project</h3>
    <p>Build a full production infrastructure from scratch using everything you learned.</p>
  </div>
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
    <span class="ok">web01 : ok=2 changed=1 unreachable=0 failed=0</span><br>
    <span class="ok">web02 : ok=2 changed=1 unreachable=0 failed=0</span>
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
