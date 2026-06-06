# Ansible Guide Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the MkDocs Material site into a DevOps Teal-themed, sidebar-grouped documentation experience with a terminal prompt logo.

**Architecture:** Update `mkdocs.yml` to group modules by skill level in the nav and switch theme features. Replace the orange custom CSS with DevOps Teal palette overrides in `extra.css`. Add a terminal prompt SVG logo.

**Tech Stack:** MkDocs, Material for MkDocs, custom CSS, SVG

---

## File Map

| File | Role |
|------|------|
| `mkdocs.yml` | Navigation structure, theme features, logo reference |
| `docs/stylesheets/extra.css` | Custom colors, layout overrides, hero/card styles |
| `docs/assets/logo.svg` | Terminal prompt `>_` logo for header |

---

### Task 1: Update Navigation & Theme Config

**Files:**
- Modify: `mkdocs.yml`

**Context:** The current `nav` is flat and `navigation.tabs` puts topics in the header. We want grouped left sidebar.

- [ ] **Step 1: Replace flat nav with grouped sections**

Replace the `nav:` block in `mkdocs.yml` with:
```yaml
nav:
  - Home: index.md
  - Beginner:
    - 01 Introduction: 01-introduction.md
    - 02 Installation: 02-installation.md
    - 03 Ad-hoc Commands: 03-ad-hoc-commands.md
    - 04 Inventory: 04-inventory.md
    - 05 First Playbook: 05-first-playbook.md
    - 06 Variables: 06-variables.md
  - Intermediate:
    - 07 Handlers: 07-handlers.md
    - 08 Roles: 08-roles.md
    - 09 Templates & Jinja2: 09-templates-jinja2.md
    - 10 Conditionals & Loops: 10-conditionals-loops.md
    - 11 Vault: 11-vault.md
  - Advanced:
    - 12 Error Handling: 12-error-handling.md
    - 13 Dynamic Inventory: 13-dynamic-inventory.md
    - 14 Collections: 14-collections.md
    - 15 Capstone Project: 15-capstone-project.md
```

- [ ] **Step 2: Update theme features and add logo**

In `mkdocs.yml`, under `theme:`:
1. Replace `logo: assets/logo.svg` — add this line at the top of `theme:`
2. In `features:`, **remove** `- navigation.tabs`
3. In `features:`, **add** `- navigation.expand`

After changes, `theme:` should look like:
```yaml
theme:
  name: material
  logo: assets/logo.svg
  palette:
    - scheme: default
      primary: custom
      accent: custom
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: custom
      accent: custom
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.sections
    - navigation.expand
    - navigation.top
    - navigation.instant
    - search.highlight
    - search.suggest
    - content.code.copy
    - content.code.annotate
```

- [ ] **Step 3: Verify YAML is valid and build passes**

Run:
```bash
cd /home/nkydigitech/ansible-guide && python3 -c "import yaml; yaml.safe_load(open('mkdocs.yml'))"
```
Expected: no output (success)

Run:
```bash
cd /home/nkydigitech/ansible-guide && ~/.local/bin/mkdocs build --strict 2>&1 | tail -5
```
Expected: `Documentation built in X seconds` with no errors or warnings.

---

### Task 2: Create Terminal Prompt Logo

**Files:**
- Create: `docs/assets/logo.svg`

- [ ] **Step 1: Write the SVG logo**

Create `docs/assets/logo.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <rect width="64" height="64" rx="12" fill="#0ea5e9"/>
  <text x="10" y="48" font-family="'JetBrains Mono', monospace" font-size="36" font-weight="bold" fill="#0f172a">&gt;_</text>
</svg>
```

- [ ] **Step 2: Verify build includes logo**

Run:
```bash
cd /home/nkydigitech/ansible-guide && ~/.local/bin/mkdocs build --strict 2>&1 | tail -5
```
Expected: `Documentation built in X seconds` with no errors.

---

### Task 3: Replace Orange Palette with DevOps Teal

**Files:**
- Modify: `docs/stylesheets/extra.css`

**Context:** Current CSS uses `#ff6b2b` (orange) extensively. Replace all orange references with `#0ea5e9` (electric teal). Keep structural CSS (hero, cards, terminal, output boxes).

- [ ] **Step 1: Replace brand color variables**

At the top of `extra.css`, replace the `:root` block:
```css
/* ── Brand colours ── */
:root {
  --md-primary-fg-color:        #0ea5e9;
  --md-primary-fg-color--light: #38bdf8;
  --md-primary-fg-color--dark:  #0284c7;
  --md-accent-fg-color:         #0ea5e9;
  --md-accent-fg-color--transparent: #0ea5e91a;
}
```

- [ ] **Step 2: Replace orange in hero section**

Replace the `.hero` gradient and accents:
```css
/* ── Hero section ── */
.hero {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
  border-radius: 12px;
  padding: 3rem 2rem;
  margin: 2rem 0;
  text-align: center;
  position: relative;
  overflow: hidden;
  border: 1px solid #0ea5e933;
}

.hero::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, #0ea5e90d 0%, transparent 60%);
  animation: pulse 4s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { transform: scale(1); opacity: 0.5; }
  50% { transform: scale(1.1); opacity: 1; }
}

.hero-badge {
  display: inline-block;
  background: #0ea5e922;
  border: 1px solid #0ea5e966;
  color: #0ea5e9;
  padding: 0.3rem 1rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 1.5rem;
}

.hero h1 {
  font-size: 2.4rem;
  font-weight: 800;
  color: #ffffff;
  margin: 0.5rem 0;
  line-height: 1.2;
}

.hero h1 span {
  color: #0ea5e9;
}

.hero p {
  color: #94a3b8;
  font-size: 1.1rem;
  max-width: 600px;
  margin: 1rem auto;
  line-height: 1.6;
}

.hero-tagline {
  font-style: italic;
  color: #0ea5e9 !important;
  font-size: 1rem !important;
  font-weight: 500;
}

.hero-stats {
  display: flex;
  justify-content: center;
  gap: 2rem;
  margin-top: 2rem;
  flex-wrap: wrap;
}

.stat {
  text-align: center;
}

.stat-number {
  display: block;
  font-size: 1.8rem;
  font-weight: 800;
  color: #0ea5e9;
}

.stat-label {
  font-size: 0.8rem;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.hero-cta {
  display: inline-block;
  background: #0ea5e9;
  color: white !important;
  padding: 0.8rem 2rem;
  border-radius: 8px;
  font-weight: 700;
  text-decoration: none !important;
  margin-top: 1.5rem;
  transition: all 0.2s;
  font-size: 1rem;
}

.hero-cta:hover {
  background: #0284c7;
  transform: translateY(-2px);
  box-shadow: 0 8px 25px #0ea5e944;
}
```

- [ ] **Step 3: Replace orange in module cards and output boxes**

Replace `.module-card` section:
```css
/* ── Module card grid ── */
.module-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
  margin: 1.5rem 0;
}

.module-card {
  background: linear-gradient(135deg, #0f172a, #1e293b);
  border: 1px solid #1e293b;
  border-radius: 10px;
  padding: 1.2rem;
  transition: all 0.2s;
  position: relative;
  overflow: hidden;
}

.module-card:hover {
  border-color: #0ea5e966;
  transform: translateY(-3px);
  box-shadow: 0 8px 24px #0ea5e922;
}

.module-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0;
  right: 0; height: 2px;
  background: linear-gradient(90deg, #0ea5e9, #38bdf8);
}

.module-number {
  font-size: 0.7rem;
  color: #0ea5e9;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
}

.module-card h3 {
  color: #ffffff;
  margin: 0.3rem 0;
  font-size: 1rem;
}

.module-card p {
  color: #94a3b8;
  font-size: 0.85rem;
  margin: 0;
}
```

Replace `.output-box` section:
```css
/* ── Output expectation box ── */
.output-box {
  border: 1px solid #0ea5e944;
  border-left: 4px solid #0ea5e9;
  border-radius: 0 8px 8px 0;
  padding: 1rem 1.5rem;
  margin: 1.5rem 0;
  background: #0ea5e908;
}

.output-box-title {
  color: #0ea5e9;
  font-weight: 700;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.5rem;
}
```

- [ ] **Step 4: Replace orange in author card and header**

Replace `.author-card` and `.author-avatar`:
```css
/* ── Author card ── */
.author-card {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  background: linear-gradient(135deg, #0f172a, #1e293b);
  border: 1px solid #1e293b;
  border-radius: 12px;
  padding: 1.5rem;
  margin: 2rem 0;
}

.author-avatar {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  font-weight: 800;
  color: white;
  flex-shrink: 0;
}

.author-info h3 {
  color: #ffffff;
  margin: 0 0 0.3rem;
}

.author-info p {
  color: #94a3b8;
  margin: 0;
  font-size: 0.9rem;
}

/* ── Navigation header ── */
.md-header {
  background: #0f172a !important;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
}

.md-tabs {
  background: #0b1120 !important;
}
```

- [ ] **Step 5: Replace orange in terminal path color**

In `.terminal-body .path`, change the color:
```css
.terminal-body .path   { color: #0ea5e9; }
```

- [ ] **Step 6: Verify build passes with new styles**

Run:
```bash
cd /home/nkydigitech/ansible-guide && ~/.local/bin/mkdocs build --strict 2>&1 | tail -5
```
Expected: `Documentation built in X seconds` with no errors or warnings.

---

### Task 4: Add Active Nav Item Highlight

**Files:**
- Modify: `docs/stylesheets/extra.css`

- [ ] **Step 1: Append nav highlight CSS**

Add at the very end of `extra.css`:
```css
/* ── Active nav item highlight ── */
.md-nav__item .md-nav__link--active {
  color: #0ea5e9 !important;
  font-weight: 600;
  border-left: 3px solid #0ea5e9;
  padding-left: 0.6rem;
  background: #0ea5e90d;
  border-radius: 0 4px 4px 0;
}

.md-nav__item .md-nav__link--active:hover {
  background: #0ea5e91a;
}
```

- [ ] **Step 2: Final build verification**

Run:
```bash
cd /home/nkydigitech/ansible-guide && ~/.local/bin/mkdocs build --strict 2>&1 | tail -10
```
Expected: `Documentation built in X seconds` with no errors or warnings.

---

## Self-Review Checklist

- [ ] **Spec coverage:** Grouped nav? → Task 1. Teal palette? → Task 3. Logo? → Task 2. Active nav highlight? → Task 4.
- [ ] **Placeholder scan:** No TBDs, no "implement later", all code blocks contain real CSS/SVG/YAML.
- [ ] **Type consistency:** CSS variables match across all tasks (`--md-primary-fg-color: #0ea5e9`).

---

## Execution

**Plan saved to:** `docs/superpowers/plans/2025-06-06-ansible-guide-redesign.md`

Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
