# Ansible Learning Guide — Site Redesign Design Document

**Date:** 2025-06-06
**Ferment:** Fix Guide Deploy Errors
**Status:** Approved by author

---

## 1. Problem Statement

The current MkDocs Material site deploys successfully but uses default navigation patterns that feel generic:
- Topics appear in top tabs, cluttering the header
- No visual grouping by skill level
- Default color scheme lacks brand personality
- No custom logo — just text title

The goal is a **breathtaking, distinctive documentation site** that:
- Groups modules logically (Beginner → Intermediate → Advanced)
- Uses a bold, modern color palette (DevOps Teal)
- Features a memorable terminal-prompt logo
- Keeps all links functional and accessible

---

## 2. Design Decisions

### 2.1 Navigation Structure

**Decision:** Use Material's left sidebar with **expandable sections** grouped by skill level.

Remove `navigation.tabs` from `mkdocs.yml`. All 15 modules move into the left sidebar under three collapsible groups:

| Group | Modules |
|-------|---------|
| **📚 Beginner** | 01 Introduction, 02 Installation, 03 Ad-hoc Commands, 04 Inventory, 05 First Playbook, 06 Variables |
| **⚙️ Intermediate** | 07 Handlers, 08 Roles, 09 Templates & Jinja2, 10 Conditionals & Loops, 11 Vault |
| **🚀 Advanced** | 12 Error Handling, 13 Dynamic Inventory, 14 Collections, 15 Capstone Project |

Enable:
- `navigation.sections` — render top-level sections as groups in sidebar
- `navigation.expand` — expand all collapsible subsections by default (optional; can be user-toggleable if Material supports it)
- `navigation.indexes` — add section index pages for each group (optional enhancement)

**Rationale:**
- Tabs consume precious horizontal space and duplicate the sidebar
- Grouping by level helps learners self-select content
- Expandable sections keep the sidebar scannable without overwhelming new visitors

---

### 2.2 Color Palette — DevOps Teal

**Decision:** Dark navy base with electric teal accents.

| Token | Hex | Role |
|-------|-----|------|
| `--md-primary-fg-color` | `#0ea5e9` | Primary accent (links, buttons, active nav) |
| `--md-primary-fg-color--dark` | `#0284c7` | Hover states |
| `--md-typeset-a-color` | `#38bdf8` | Link color |
| Background (dark mode) | `#0f172a` | Deep navy page background |
| Background (code) | `#0b1120` | Slightly darker for code blocks |
| Text primary | `#f8fafc` | Headings, body text |
| Text secondary | `#94a3b8` | Captions, secondary text |

**Implementation:** Override Material CSS variables in `docs/stylesheets/extra.css` and/or configure `extra_css` in `mkdocs.yml`.

**Rationale:**
- Teal/cyan is synonymous with modern DevOps tooling (Docker, Kubernetes, Terraform palettes)
- High contrast against dark navy ensures accessibility (WCAG AA compliant)
- Distinct from default Material indigo — creates brand recognition

---

### 2.3 Logo

**Decision:** Terminal prompt `>_` in teal (#0ea5e9), rendered as an SVG icon in the header.

- Replace default text title with icon + site name
- SVG allows crisp scaling on all devices
- Color matches primary accent for cohesion

**Placement:** Top-left in the header bar, before site name.

**Fallback:** If custom SVG logo file is unavailable, use Material's `icon.logo` config or embed inline SVG in custom header override.

---

### 2.4 Typography

**Decision:** Keep existing fonts.

- Text: `Inter` (already configured — excellent readability)
- Code: `JetBrains Mono` (already configured — developer friendly)

No changes needed. Typography is already a strength.

---

### 2.5 Extra Visual Polish

**Custom CSS enhancements in `docs/stylesheets/extra.css`:**

1. **Glowing active nav item** — left border accent in teal + subtle background tint
2. **Gradient hero section** (optional) — on homepage only, a subtle teal-to-transparent gradient behind the title
3. **Smooth scroll** — already enabled by `navigation.top`; ensure it feels polished
4. **Custom admonition colors** — match teal palette for info/warning/danger boxes
5. **Hover lift on cards** — if any grid or card layouts are added later

---

## 3. File Changes

| File | Change |
|------|--------|
| `mkdocs.yml` | Restructure `nav:` into grouped sections; remove `navigation.tabs`; add `navigation.expand` (optional) |
| `docs/stylesheets/extra.css` | Add Material CSS variable overrides for DevOps Teal palette; add custom nav styling |
| `docs/assets/logo.svg` | New — terminal prompt SVG logo (or inline in CSS/header) |
| `docs/superpowers/specs/2025-06-06-ansible-guide-redesign-design.md` | This design document |

---

## 4. Accessibility & Performance

- All color combinations must meet WCAG AA contrast ratios (teal on dark navy passes)
- Keyboard navigation through expandable sidebar groups must work
- `prefers-reduced-motion` respected for hover animations
- No heavy JavaScript additions — keep MkDocs Material's fast load times

---

## 5. Success Criteria

- [ ] Left sidebar shows all 15 modules grouped under Beginner/Intermediate/Advanced
- [ ] No top tabs appear on desktop or mobile
- [ ] Active nav item visually distinct (teal accent)
- [ ] Logo (`>_`) visible in header
- [ ] Links throughout site remain functional (verified via `mkdocs build --strict`)
- [ ] Color palette applied consistently across all pages
- [ ] Both light and dark modes look polished (Material handles toggle)

---

## 6. Out of Scope

- Rewriting content — design-only changes
- Adding new MkDocs plugins (keep existing stack)
- Complex JavaScript interactivity beyond Material's built-in features
- Custom font loading (Inter and JetBrains Mono already loaded)

---

## 7. Open Questions

_None remaining. Design approved by author on 2025-06-06._
