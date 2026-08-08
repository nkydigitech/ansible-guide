# Chapter 13: Dynamic Inventory in Ansible

## Learning Objectives

- Understand the difference between static and dynamic inventory and when to use each
- Configure the AWS EC2 dynamic inventory plugin to discover and manage cloud instances
- Filter dynamic inventory results using tags, regions, and instance states
- Work with inventory caching to improve performance
- Create a custom dynamic inventory script for non-standard environments

## Explanation

### Static vs. Dynamic Inventory

In Chapter 4, you learned about static inventory—manually defined lists of hosts in INI or YAML files. Static inventory works well for infrastructure that does not change often:

```ini
# static_inventory.ini
[web_servers]
web1.example.com
web2.example.com

[database_servers]
db1.example.com
```

However, modern infrastructure is dynamic. Cloud instances spin up and down based on demand, containers spawn and terminate, and hosts may be provisioned by auto-scaling groups. Maintaining a static inventory file in these environments is tedious and error-prone. You would need to update your inventory file every time a new instance launches—defeating the purpose of automation.

**Dynamic inventory** solves this problem by pulling the current list of hosts from an external source at runtime. Instead of listing hosts manually, you point Ansible to a script or plugin that queries your cloud provider, container orchestrator, or CMDB, and returns the current host list.

### Dynamic Inventory Sources

Ansible supports dynamic inventory from numerous sources:

| Source | Plugin/Module | Use Case |
|--------|--------------|----------|
| Amazon Web Services (EC2) | `amazon.aws.aws_ec2` | AWS cloud instances |
| Google Cloud Platform | `google.cloud.gcp_compute` | GCE virtual machines |
| Microsoft Azure | `azure.azcollection.azure_rm_compute` | Azure VMs |
| DigitalOcean | `community.digitalocean.digitalocean` | Droplets |
| VMware | `community.vmware.vmware_vm_inventory` | VMware VMs |
| Red Hat Satellite | `redhat.satellite.foreman` | Managed infrastructure |
| Container clusters | Various | Kubernetes, Docker Swarm |

### How Dynamic Inventory Works

A dynamic inventory source (whether a plugin or script) must output hosts in a specific JSON format that Ansible understands:

```json
{
  "web_servers": {
    "hosts": ["web-01.example.com", "web-02.example.com"],
    "vars": {
      "environment": "production"
    }
  },
  "database_servers": {
    "hosts": ["db-01.example.com"]
  },
  "_meta": {
    "hostvars": {
      "web-01.example.com": {
        "ansible_host": "10.0.1.10",
        "ec2_tag_Name": "web-01"
      }
    }
  }
}
```

The `ansible-inventory` command can consume this format, making it easy to visualize what hosts Ansible has discovered.

### AWS EC2 Dynamic Inventory (The Most Common Use Case)

AWS EC2 is the most widely used dynamic inventory source. Ansible provides the `amazon.aws.aws_ec2` inventory plugin, which queries the AWS API for running instances and organizes them into groups based on tags, instance types, VPC, security groups, and more.

> **Pro Tip**: When using dynamic inventory with AWS, ensure your control node has appropriate AWS credentials. Use IAM roles where possible—never hardcode access keys. The AWS SDK will automatically pick up credentials from environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), shared credentials file (`~/.aws/credentials`), or IAM instance profiles.

## Examples

### Setting Up the AWS EC2 Inventory Plugin

The AWS EC2 inventory plugin uses a YAML configuration file to define how to query AWS and how to group the results.

**Step 1: Install the AWS collection**

```bash
ansible-galaxy collection install amazon.aws
```

**Step 2: Create an inventory configuration file `inventory/aws_ec2.yml`**

```yaml
---
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
boto_profile: default  # Or use boto_profile for named credentials

# AWS region(s) to query
regions:
  - us-east-1
  - us-west-2

# Filter instances by their state
filters:
  instance-state-name: running

# Organize hosts into groups based on EC2 tags
keyed_groups:
  # Create a group per tag value, prefixed with "tag_"
  - prefix: tag
    key: tags
    separator: '_'
  # Create groups based on instance type, prefixed with "type_"
  - prefix: type
    key: instance_type
  # Create groups based on VPC, prefixed with "vpc_"
  - prefix: vpc
    key: vpc_id

# Use specific hostname variables
hostnames:
  - tag:Name  # Prefer the Name tag for hostname
  - private-ip-address

# Compose variables for each host
compose:
  # Use the public IP if available, otherwise private IP
  ansible_host: public_ip_address | default(private_ip_address)
```

**Step 3: Verify the inventory**

```bash
# List all discovered hosts
ansible-inventory -i inventory/aws_ec2.yml --list

# Visualize groups
ansible-inventory -i inventory/aws_ec2.yml --graph
```

Sample `--graph` output:
```
@all:
  |--@aws_ec2:
  |  |--web-01.example.com
  |  |--web-02.example.com
  |  |--db-01.example.com
  |--@tag_Environment_Production:
  |  |--web-01.example.com
  |  |--web-02.example.com
  |  |--db-01.example.com
  |--@tag_Role_Web:
  |  |--web-01.example.com
  |  |--web-02.example.com
  |--@tag_Role_Database:
  |  |--db-01.example.com
  |--@type_t3_medium:
  |  |--web-01.example.com
  |  |--web-02.example.com
```

### Filtering EC2 Instances

The `filters` parameter uses boto3 query syntax. You can filter by any EC2 instance attribute:

```yaml
# inventory/production_webservers.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1

filters:
  instance-state-name: running
  tag:Environment: production
  tag:Role: web
  instance-type: t3.medium

keyed_groups:
  - prefix: tag
    key: tags
```

This inventory only includes production web servers of type t3.medium.

### Using Inventory Variables from EC2

EC2 plugin automatically populates host variables from instance metadata:

```yaml
# playbook.yml
---
- name: Manage EC2 instances
  hosts: tag_Role_Web
  gather_facts: true
  tasks:
    - name: Display instance information
      ansible.builtin.debug:
        msg: |
          Instance: {{ inventory_hostname }}
          Private IP: {{ ansible_host }}
          Region: {{ aws_region }}
          VPC: {{ vpc_id }}
          Tags: {{ ec2_tags }}
```

### Inventory Caching

Querying cloud APIs on every playbook run can be slow and may hit rate limits. The `cache` option stores inventory results locally:

```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
# ... other settings ...

# Enable caching
cache: true
cache_plugin: jsonfile  # Store to local JSON file
cache_timeout: 3600     # Cache validity in seconds (1 hour)
cache_connection: /tmp/ansible_inventory_cache
cache_prefix: aws_ec2_
```

For short-lived environments, use a shorter cache timeout. For stable infrastructure, a 5-minute cache is often sufficient.

### Using Multiple Inventory Sources

You can combine multiple inventory sources in one Ansible command:

```bash
ansible-playbook -i inventory/aws_ec2.yml -i inventory/static_servers.yml site.yml
```

Or configure them together in `ansible.cfg`:

```ini
[defaults]
inventory = inventory/aws_ec2.yml,inventory/static_servers.yml
```

### Custom Dynamic Inventory Script

If your infrastructure does not have a built-in plugin, you can write a custom inventory script. A script must output JSON to stdout when called with `--list` and optionally support `--host <hostname>` for individual host variables.

**Example: Simple JSON-based custom inventory script**

```python
#!/usr/bin/env python3
# inventory/custom_inventory.py

import json
import sys

def get_inventory():
    """Return inventory data in Ansible's expected format."""
    inventory = {
        "webservers": {
            "hosts": ["web1.example.com", "web2.example.com"],
            "vars": {
                "ansible_user": "admin",
                "app_port": 8080
            }
        },
        "databases": {
            "hosts": ["db1.example.com"],
            "vars": {
                "ansible_user": "dbadmin",
                "db_port": 5432
            }
        },
        "_meta": {
            "hostvars": {
                "web1.example.com": {
                    "ansible_host": "192.168.1.10",
                    "custom_var": "web1_specific"
                },
                "web2.example.com": {
                    "ansible_host": "192.168.1.11",
                    "custom_var": "web2_specific"
                },
                "db1.example.com": {
                    "ansible_host": "192.168.2.10"
                }
            }
        }
    }
    return inventory

def get_host_vars(hostname):
    """Return variables for a specific host."""
    inventory = get_inventory()
    return inventory["_meta"]["hostvars"].get(hostname, {})

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        print(json.dumps(get_inventory()))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        print(json.dumps(get_host_vars(sys.argv[2])))
    else:
        print(json.dumps({"error": "Unknown command"}))
```

Make the script executable and test it:

```bash
chmod +x inventory/custom_inventory.py
ansible-inventory -i inventory/custom_inventory.py --list
ansible-inventory -i inventory/custom_inventory.py --graph
```

> **Pro Tip**: When writing custom inventory scripts, always include the `_meta` section with `hostvars`. Without it, Ansible cannot look up variables for individual hosts efficiently.

### GCP Dynamic Inventory

For Google Cloud Platform, use the `google.cloud.gcp_compute` inventory plugin:

```yaml
# inventory/gcp_compute.yml
plugin: google.cloud.gcp_compute
projects:
  - my-project-id
zones:
  - us-central1-a
  - us-central1-b
filters:
  - status = RUNNING
keyed_groups:
  - key: labels
    prefix: label
  - key: zone
    prefix: zone
```

## Hands-On Exercises

### Exercise 1: Explore the AWS EC2 Plugin Configuration

**Objective**: Understand the structure of an AWS EC2 inventory configuration file.

**Steps**:
1. Create the directory structure: `mkdir -p inventory`
2. Create `inventory/aws_ec2.yml` with the configuration shown in the examples section
3. Add at least three `keyed_groups` (try `tag`, `instance_type`, and `vpc_id`)
4. Use `ansible-inventory -i inventory/aws_ec2.yml --graph` to visualize groups
5. Try adding an `include_filters` section and observe how it changes the output

**Expected Outcome**: You understand how keyed groups and filters shape the inventory structure.

**Hint**: If you do not have AWS credentials, you can use `boto_profile: null` and rely on environment mock variables for learning purposes, but the actual listing will fail without valid credentials.

---

### Exercise 2: Create a Static-to-Dynamic Hybrid Inventory

**Objective**: Combine dynamic EC2 inventory with static groups for on-premises servers.

**Steps**:
1. Create `inventory/aws_ec2.yml` for cloud instances (even a minimal config)
2. Create `inventory/on_prem.yml` with static hosts:
   ```yaml
   ---
   plugin: custom
   hosts:
     onprem-server-1.example.com:
       ansible_host: 10.0.0.5
     onprem-server-2.example.com:
       ansible_host: 10.0.0.6
   ```
3. Test with `ansible-inventory -i inventory/aws_ec2.yml -i inventory/on_prem.yml --list`
4. Run a playbook targeting both inventories with `hosts: all`

**Expected Outcome**: Ansible discovers hosts from both the dynamic and static sources, allowing unified management.

**Hint**: A simple custom inventory plugin can be a YAML file with a `plugin: yaml` type and `hosts:` mapping for static entries.

---

### Exercise 3: Configure Inventory Caching

**Objective**: Implement inventory caching to reduce API calls.

**Steps**:
1. Add caching configuration to your AWS EC2 inventory file:
   ```yaml
   cache: true
   cache_plugin: jsonfile
   cache_timeout: 600
   cache_connection: /tmp/ansible_cache
   ```
2. Run `ansible-inventory -i inventory/aws_ec2.yml --list` twice
3. Check if files were created in `/tmp/ansible_cache`
4. Modify the cache timeout to 10 seconds and run again after waiting
5. Observe how Ansible uses the cache

**Expected Outcome**: After the first run, subsequent runs use cached data. When the cache expires, Ansible re-queries the cloud API.

**Hint**: You can force Ansible to bypass the cache with the `--flush-cache` flag on `ansible-playbook` or `ansible-inventory`.

---

### Exercise 4: Write a Basic Custom Inventory Script

**Objective**: Build a custom inventory script that returns hosts from a JSON file.

**Steps**:
1. Create `inventory/simple_inventory.py` with the script template from the examples
2. Modify it to read hosts from an external JSON file (create a separate `hosts.json`)
3. Make the script executable
4. Test with `ansible-inventory -i inventory/simple_inventory.py --list`
5. Test with `ansible-inventory -i inventory/simple_inventory.py --graph`

**Expected Outcome**: Your custom script outputs inventory in the format Ansible expects, and both list and graph commands work.

**Hint**: The `--host <hostname>` function is optional but improves performance when Ansible needs variables for specific hosts.

---

### Exercise 5: Filter Dynamic Inventory by Tags

**Objective**: Use AWS tags to create targeted inventories.

**Steps**:
1. Design an inventory file that creates separate groups for:
   - `tag_Environment_dev`, `tag_Environment_staging`, `tag_Environment_prod`
   - `tag_Role_web`, `tag_Role_api`, `tag_Role_database`
2. Create an inventory configuration with at least two keyed_groups using EC2 tags
3. Write a playbook that targets only `tag_Environment_prod:&tag_Role_web` (intersection of prod and web)
4. Verify the playbook would only run against hosts matching both criteria

**Expected Outcome**: Using `&` in the host pattern selects hosts that are in both groups, allowing precise targeting.

**Hint**: The pattern `tag_Environment_prod:&tag_Role_web` uses Ansible's group intersection syntax. The `:` means "intersection" when between two group names.

## Summary

- Dynamic inventory pulls host lists from external sources at runtime, eliminating manual maintenance
- Ansible supports dynamic inventory via plugins (preferred) or legacy scripts
- The AWS EC2 plugin (`amazon.aws.aws_ec2`) is the most common, organizing instances by tags, types, VPC, and more
- `keyed_groups` automatically create inventory groups based on instance attributes
- Inventory caching improves performance by reducing API calls and avoiding rate limits
- Multiple inventory sources can be combined in a single Ansible command
- Custom inventory scripts must output JSON in Ansible's inventory format
- For production AWS usage, rely on IAM roles rather than hardcoded access keys

## Additional Resources

- [Ansible Inventory Plugins](https://docs.ansible.com/ansible/latest/collections/community/general/openstack_inventory.html) - Official documentation on inventory plugins including AWS EC2
- [AWS EC2 Inventory Plugin](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html) - Detailed configuration options for the AWS EC2 plugin
- [Dynamic Inventory Examples](https://github.com/ansible/ansible/tree/devel/contrib/inventory) - Example inventory scripts for various cloud providers and infrastructure types

<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../12-error-handling/" style="color:#8892b0; text-decoration:none;">← Previous: Error Handling</a>
  <a href="../14-collections/" style="background:#6c63ff; color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:600;">Next: Collections →</a>
</div>
