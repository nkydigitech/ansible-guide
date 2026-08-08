# 2 AM Production Runbook - When Prod is Down

> Based on poll: 45 votes - 44% check logs, 31% check monitoring

## The Order That Saves You

### Step 1: Check Monitoring FIRST (Not Logs)
**Why:** Logs tell you WHAT broke. Monitoring tells you HOW BIG.
- Is it 1 server or ALL servers?
- Is it CPU, Memory, or App?
- Grafana / CloudWatch / Datadog

```bash
# Quick scope check
kubectl get pods -A | grep -v Running
```

### Step 2: Check Logs - What Changed?
```bash
git log --oneline --graph --decorate -n 5
tail -n 20 deploy.log
```

Look for:
- Config file changed: config/app.yaml
- Last deploy timestamp
- 429 errors spiking post-deploy

### Step 3: Rollback in 1 Command
No SSH and pray at 2 AM.

```bash
ansible-playbook rollback.yml --extra-vars "target_version=v1.4.2-stable"
```

Tasks:
1. Stop current release (systemd)
2. Restore previous version (Git tag)
3. Verify health checks (liveness/readiness = PASS)

**Result:** Rollback completed in 42s - All checks passed
PLAY RECAP: ok=5 changed=3 unreachable=0 failed=0

---

**EST Runtime:** ~45s | **ZERO DOWNTIME** | **AUTO VERIFIED**

Built with: AWS + Ansible + Terraform
Author: @nkydigitech | Nkechi Anna Ahanonye
Guide: https://nkydigitech.github.io/ansible-guide/
Lab: https://nkydigitech.github.io/ansible-lab/
