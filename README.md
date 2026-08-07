<p align="center">
  <img src="https://img.shields.io/badge/Ansible-Zero%20to%20Production-00d4aa?style=for-the-badge&logo=ansible&logoColor=white" />
  <img src="https://img.shields.io/badge/15%20Modules-Free%20%26%20Open%20Source-6c63ff?style=for-the-badge" />
  <img src="https://img.shields.io/badge/MkDocs-Material-ff6b6b?style=for-the-badge" />
</p>

<h1 align="center">Ansible Zero to Production — Complete 15-Module Masterclass</h1>
<p align="center"><strong>From Beginner to Production-Ready Infrastructure Automation</strong></p>

> 🚀 **Nkechi Ahanonye — Cloud & DevOps Engineer | I turn manual, 3 AM-breaking deployments into 1-min automated pipelines with AWS + Ansible + Terraform**
>
> **Live Portfolio:** 📦 [ansible_practical – 17 Green Runs ✅](https://github.com/nkydigitech/ansible_practical) | 📖 You are here (Guide) | 🧪 [Student Lab](https://nkydigitech.github.io/ansible-lab/) | 💼 [LinkedIn](https://www.linkedin.com/in/nkechi-ahanonye)

<p align="center">
  <a href="https://github.com/nkydigitech/ansible_practical/actions/workflows/cicd.yml"><img src="https://github.com/nkydigitech/ansible_practical/actions/workflows/cicd.yml/badge.svg" alt="CI/CD Pipeline" /></a>
  <a href="https://nkydigitech.github.io/ansible-guide/"><img src="https://img.shields.io/badge/Live%20Site-Online-00d4aa?style=flat-square&logo=githubpages" /></a>
  <a href="#"><img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" /></a>
  <a href="#"><img src="https://img.shields.io/badge/100%25%20Free-Forever-6c63ff?style=flat-square" /></a>
</p>

> *"I built this guide because beginners deserve better than scattered tutorials. Every module shows you exactly what success looks like."*
> — **Nkechi Ahanonye**, Cloud & DevOps Engineer, Lagos

**A free, structured Ansible curriculum covering Ad-hoc Commands → Inventory → Playbooks → Roles → Jinja2 Templates → Vault AES-256 → Dynamic Inventory → Collections → Capstone. Real terminal output in every module — no fluff, just what gets you hired.**

---

### 🌐 Live Site

## 👉 [nkydigitech.github.io/ansible-guide](https://nkydigitech.github.io/ansible-guide)

15 modules • Real terminal output • 100% free • Built with MkDocs Material 9.7.6

---

### 📚 What's Inside — 15 Modules Zero to Production

| # | Module | What You'll Master | Level |
|---|--------|-------------------|-------|
| 01 | **Introduction to Ansible** | Agentless architecture, control node vs managed nodes | 🟢 Beginner |
| 02 | **Installation** | Linux, Mac, Windows WSL — verified install | 🟢 Beginner |
| 03 | **Ad-hoc Commands** | One-liners before writing playbooks | 🟢 Beginner |
| 04 | **Inventory** | Static, grouped & dynamic inventory | 🟢 Beginner |
| 05 | **First Playbook** | Your first YAML deployment that actually works | 🟢 Beginner |
| 06 | **Variables** | Define, scope & override like a pro | 🟢 Beginner |
| 07 | **Handlers** | Restart services only when changed | 🟡 Intermediate |
| 08 | **Roles** | Reusable, production-grade structure | 🟡 Intermediate |
| 09 | **Templates & Jinja2** | Dynamic config files | 🟡 Intermediate |
| 10 | **Conditionals & Loops** | `when`, `loop`, filters | 🟡 Intermediate |
| 11 | **Vault AES-256** | Never commit plain secrets again | 🟡 Intermediate |
| 12 | **Error Handling** | `ignore_errors`, `block/rescue` | 🔴 Advanced |
| 13 | **Dynamic Inventory** | AWS, GCP, Azure auto-scaling | 🔴 Advanced |
| 14 | **Collections** | Galaxy, `ansible-galaxy` | 🔴 Advanced |
| 15 | **Capstone Project** | Full prod infrastructure from scratch | 🔴 Advanced |

---

### ✨ What Makes This Different?

<table>
<tr>
<td width="50%">

**📺 Expected Output Everywhere**
Every module shows you the *exact* terminal output you should see when it works. No guessing.

```bash
PLAY [web servers] *****
TASK [Install nginx] ***
changed: [web01]
PLAY RECAP *****
web01 : ok=2 changed=1
```

</td>
<td width="50%">

**🔄 Built for Real Jobs**
- Progressive learning — each module builds on last
- Hands-on exercises, not just reading
- Production-ready patterns used in `ansible_practical`
- Lint → Dry-Run → Deploy mindset

</td>
</tr>
</table>

---

### 🚀 Quick Start — Run Locally

```bash
# Clone
git clone https://github.com/nkydigitech/ansible-guide.git
cd ansible-guide

# Install MkDocs Material
pip install mkdocs-material

# Serve
mkdocs serve
```
Open `http://127.0.0.1:8000` — hot reload enabled!

---

### 🌐 Deployment — Auto to GitHub Pages

This site auto-deploys via GitHub Actions.

**Required GitHub Pages setting (one time):**
1. Go to **Settings → Pages**
2. **Source:** `Deploy from a branch`
3. **Branch:** `gh-pages` / `root`
4. Push to `main` → workflow builds and pushes to `gh-pages`

> Workflow file: `.github/workflows/deploy.yml`

---

### 🧪 Part of the Trilogy — Learn the Right Order

| Repo | What It Proves | Link |
|------|----------------|------|
| **📦 ansible_practical** | Senior pipeline — 17 green runs, no SSH | [View Repo →](https://github.com/nkydigitech/ansible_practical) |
| **📖 ansible-guide (You are here)** | Teaching — 15 modules, zero to prod | You are here |
| **🧪 ansible-lab** | Practice — 4 hands-on labs | [View Lab →](https://nkydigitech.github.io/ansible-lab/) |

> Recruiter flow: Lab → Guide → Practical (green CI) → Hired.

---

### 🤝 Contributing

Found a typo? Want to add Module 16? PRs welcome!

1. Fork the repo
2. `git checkout -b fix/module-name`
3. Make changes
4. Submit PR

All contributors get credit.

---

### 👩🏽‍💻 Author — Nkechi Anna Ahanonye

**Cloud & DevOps Engineer | Nkydigitech | Training the Next Generation of African DevOps Engineers**

I build infrastructure that doesn't break at 2 AM. 15 years running a cybercafe taught me: real users don't care about your stack, they care that things just work.

- **LinkedIn:** [linkedin.com/in/nkechi-ahanonye](https://www.linkedin.com/in/nkechi-ahanonye)
- **GitHub:** [github.com/nkydigitech](https://github.com/nkydigitech)
- **Portfolio:** [nkydigitech.github.io/nky-portfolio](https://nkydigitech.github.io/nky-portfolio/)
- **Live Practical:** [ansible_practical – 17 Green Runs ✅](https://github.com/nkydigitech/ansible_practical)

---

<p align="center">
  <strong>⭐ Star this repo if it stopped you from SSH-ing into prod!</strong><br/>
  Built with ❤️ by Nkechi — Open source & free forever. Share with every DevOps student you know 🚀
</p>

### 📄 License

MIT — free to use, share, and build on.

---

<p align="center">
  <sub>Keywords: ansible tutorial, ansible zero to production, ansible complete guide, ansible roles, ansible vault, ansible jinja2, ansible dynamic inventory, ansible collections, devops ansible, infrastructure as code, mkdocs material</sub>
</p>
