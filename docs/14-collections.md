# Chapter 14: Ansible Collections

## Learning Objectives

- Understand what Ansible Collections are and how they organize content
- Navigate the collection directory structure and `galaxy.yml` manifest
- Install collections from Ansible Galaxy and other sources
- Use collection modules and plugins in playbooks with proper namespaces
- Create and publish a basic collection

## Explanation

### The Evolution of Ansible Content

Before Ansible 2.9, Ansible content lived in a monolithic repository. Modules, plugins, and roles were distributed with Ansible itself or shared through Ansible Galaxy as standalone roles. This worked, but had limitations:

- The Ansible release cycle governed when new modules could be shipped
- All content was lumped together regardless of source or maintainer
- Large collection size made updates cumbersome

**Ansible Collections** introduced in Ansible 2.10 solved this by creating a standardized, composable unit for distributing Ansible content. A collection can contain:

- Modules
- Plugins (inventory, lookup, filter, callback, etc.)
- Roles
- Playbooks
- Documentation
- Tests

This modularity means:
- Collections can be updated independently of Ansible itself
- Vendors (AWS, Azure, Google, VMware) can ship and update their modules on their own schedule
- The community can maintain collections with different release cadences

### Collection Namespace

Collections live in namespaces to avoid naming conflicts. A fully qualified collection name looks like:

```
namespace.collection.name
```

Examples:
- `amazon.aws.ec2_instance` (AWS module)
- `ansible.posix.firewalld` (Linux firewall module)
- `community.general.docker_container` (Docker module)
- `kubernetes.core.k8s` (Kubernetes module)

The namespace typically corresponds to the organization or community maintaining the collection.

### The Ansible Galaxy Marketplace

[Ansible Galaxy](https://galaxy.ansible.com) is the primary repository for sharing and discovering collections. It hosts thousands of collections from Red Hat, cloud providers, and the community.

> **Pro Tip**: When installing collections, prefer official vendor collections (e.g., `amazon.aws`, `azure.azcollection`, `google.cloud`) over community alternatives when available. Vendor-maintained collections receive regular updates, security patches, and support.

### Collection Structure

A collection follows a standardized directory structure:

```
namespace/
  └── collection_name/
      ├── galaxy.yml              # Collection metadata
      ├── README.md               # Collection documentation
      ├── LICENSE                 # License file
      ├── docs/                   # Additional documentation
      ├── playbooks/              # Example playbooks
      │   └── files/
      ├── roles/                  # Roles bundled in the collection
      │   ├── role1/
      │   └── role2/
      ├── plugins/
      │   ├── modules/            # Module files
      │   │   └── module_name.py
      │   ├── inventory/          # Inventory plugins
      │   ├── lookup/             # Lookup plugins
      │   ├── filter/             # Filter plugins
      │   └── callback/           # Callback plugins
      └── tests/                  # Integration and unit tests
```

The `galaxy.yml` file is the collection's manifest, containing metadata that Galaxy uses to index and categorize the collection.

## Examples

### Installing Collections

Install collections using `ansible-galaxy collection install`:

```bash
# Install a single collection
ansible-galaxy collection install amazon.aws

# Install a specific version
ansible-galaxy collection install amazon.aws:1.5.0

# Install multiple collections
ansible-galaxy collection install amazon.aws community.general

# Install from a requirements file
ansible-galaxy collection install -r requirements.yml
```

A `requirements.yml` file allows you to pin versions and specify sources:

```yaml
# requirements.yml
---
collections:
  - name: amazon.aws
    version: ">=1.5.0,<2.0.0"
  - name: community.general
  - name: azure.azcollection
    source: https://github.com/azure/azure-dba.git
  - name: myorg.mycollection
    source: /path/to/local/collection
```

### Using Collection Modules

After installation, use collection modules with their fully qualified names:

```yaml
# playbook.yml
---
- name: Deploy infrastructure with collection modules
  hosts: localhost
  gather_facts: false
  tasks:
    # AWS EC2 instance using amazon.aws collection
    - name: Launch EC2 instance
      amazon.aws.ec2_instance:
        name: web-server
        instance_type: t3.medium
        image:
          id: ami-0abcdef1234567890
        security_groups: ["web-sg"]
        tags:
          Environment: production
          Role: web
        count_tag:
          Name: web-server
        exact_count: 1
      register: ec2_result

    - name: Print instance details
      ansible.builtin.debug:
        msg: "Created instance {{ ec2_result.instance_ids }}"

    # Firewalld using ansible.posix collection
    - name: Configure firewall for web traffic
      ansible.posix.firewalld:
        service: http
        permanent: true
        state: enabled

    # Docker container using community.general collection
    - name: Start nginx container
      community.general.docker_container:
        name: nginx
        image: nginx:latest
        ports:
          - "80:80"
          - "443:443"
        state: started
```

### FQCN vs. Short Names

Modules within a collection can be referenced in two ways:

1. **Fully Qualified Collection Name (FQCN)**:
   ```yaml
   amazon.aws.ec2_instance
   ```

2. **Short name** (requires the collection to be listed in `collections:` in the play):
   ```yaml
   ---
   - name: Using short names
     hosts: localhost
     collections:
       - amazon.aws
     tasks:
       - name: Launch instance
         ec2_instance:  # Ansible resolves this to amazon.aws.ec2_instance
           name: web-server
           instance_type: t3.small
   ```

> **Pro Tip**: In production playbooks, prefer FQCNs. They make the module origin unambiguous, prevent conflicts when multiple collections provide modules with the same name, and make the playbook self-documenting.

### Creating a Collection

**Step 1: Initialize the collection structure**

```bash
ansible-galaxy collection init myorg.mycollection
```

This creates:
```
myorg/
  └── mycollection/
      ├── docs/
      ├── galaxy.yml
      ├── plugins/
      │   ├── modules/
      │   └── README.md
      ├── README.md
      ├── roles/
      └── tests/
```

**Step 2: Define collection metadata in `galaxy.yml`**

```yaml
# myorg/mycollection/galaxy.yml
namespace: myorg
name: mycollection
version: 1.0.0
readme: README.md
authors:
  - Your Name <your.email@example.com>
description: A custom collection for internal use
license:
  - GPL-3.0-or-later
license_files:
  - LICENSE
tags:
  - custom
  - internal
  - example
dependencies:
  community.general: ">=3.0.0"
repository: https://github.com/myorg/ansible-collection-mycollection
documentation: https://github.com/myorg/ansible-collection-mycollection/docs
issues: https://github.com/myorg/ansible-collection-mycollection/issues
```

**Step 3: Add a module to the collection**

Create `myorg/mycollection/plugins/modules/hello_world.py`:

```python
#!/usr/bin/env python3
from ansible.module_utils.basic import AnsibleModule

def run_module():
    module_args = dict(
        name=dict(type='str', required=True),
        greeting=dict(type='str', default='Hello'),
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    result = dict(
        changed=False,
        message="{greeting}, {name}!".format(
            greeting=module.params['greeting'],
            name=module.params['name']
        )
    )

    if module.check_mode:
        module.exit_json(**result)

    result['changed'] = True
    module.exit_json(**result)

def main():
    run_module()

if __name__ == '__main__':
    main()
```

**Step 4: Use the module in a playbook**

```yaml
# myorg/mycollection/playbooks/hello.yml
---
- name: Test my collection module
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Greet the world
      myorg.mycollection.hello_world:
        name: "Ansible User"
        greeting: "Hi"
```

**Step 5: Install and run**

```bash
# Install the collection locally (from the collection root)
ansible-galaxy collection install myorg/mycollection -p ./collections

# Or install from the directory
cd myorg/mycollection
ansible-galaxy collection install . -p /path/to/collections

# Run the playbook
ansible-playbook -i localhost, -c local myorg/mycollection/playbooks/hello.yml
```

### Key Collections to Know

| Collection | Namespace | Content |
|-----------|-----------|---------|
| **ansible.posix** | `ansible.posix` | POSIX-specific modules: firewalld, sysctl, mount, etc. |
| **community.general** | `community.general` | General-purpose modules: Docker, PostgreSQL, etc. |
| **amazon.aws** | `amazon.aws` | AWS services: EC2, S3, RDS, IAM, VPC, etc. |
| **azure.azcollection** | `azure.azcollection` | Azure services: VMs, networking, storage |
| **google.cloud** | `google.cloud` | GCP services: Compute, GKE, Cloud SQL |
| **community.docker** | `community.docker` | Docker and Docker Compose modules |
| **kubernetes.core** | `kubernetes.core` | Kubernetes and OpenShift modules |
| **ansible.windows** | `ansible.windows` | Windows-specific modules and plugins |

## Hands-On Exercises

### Exercise 1: Install and Explore a Collection

**Objective**: Install a collection and explore its structure.

**Steps**:
1. Install the `ansible.posix` collection:
   ```bash
   ansible-galaxy collection install ansible.posix
   ```
2. Find where the collection was installed (typically `~/.ansible/collections/ansible_collections/`)
3. Explore the directory structure: read `galaxy.yml`, list the modules, check the `plugins/` subdirectories
4. List available modules in the collection:
   ```bash
   ansible-doc -t module ansible.posix --list
   ```

**Expected Outcome**: You understand the collection directory structure and can navigate its contents.

**Hint**: Use `ansible-galaxy collection list` to see all installed collections and their versions.

---

### Exercise 2: Use Multiple Collection Modules

**Objective**: Write a playbook that uses modules from different collections.

**Steps**:
1. Install required collections:
   ```bash
   ansible-galaxy collection install community.general ansible.posix
   ```
2. Write a playbook that:
   - Uses `ansible.posix.firewalld` to configure firewall rules
   - Uses `community.general.sysctl` to set a kernel parameter
   - Uses `community.general.pip` to install a Python package
3. Run the playbook against `localhost` with `-c local`
4. Verify the changes took effect

**Expected Outcome**: The playbook runs successfully, and you see the fully qualified module names resolved and executed.

**Hint**: If you run against localhost without actual firewall/service configuration, some tasks may fail—but you can verify Ansible correctly resolves the FQCNs.

---

### Exercise 3: Create a Custom Collection with a Role

**Objective**: Package a role inside a collection.

**Steps**:
1. Initialize a new collection: `ansible-galaxy collection init myorg.tools`
2. Create a role inside the collection: move or create `myorg/tools/roles/common/`
3. Add tasks to the role (`roles/common/tasks/main.yml`):
   ```yaml
   ---
   - name: Create log directory
     ansible.builtin.file:
       path: /var/log/myapp
       state: directory
       mode: '0755'
   ```
4. Install the collection locally
5. Use the role in a playbook:
   ```yaml
   ---
   - name: Use role from collection
     hosts: localhost
     roles:
       - myorg.tools.common
   ```
6. Run the playbook

**Expected Outcome**: The role from the collection is discovered and executed correctly.

**Hint**: When referencing roles from collections in a playbook, use the format `namespace.collection.role_name`.

---

### Exercise 4: Understand Collection Dependencies

**Objective**: Define and manage collection dependencies.

**Steps**:
1. Create a collection with a dependency in `galaxy.yml`:
   ```yaml
   dependencies:
     community.general: ">=5.0.0"
   ```
2. Attempt to install your collection without the dependency already present
3. Observe that Ansible automatically installs the dependency
4. Check with `ansible-galaxy collection list` that both collections are installed

**Expected Outcome**: Ansible automatically resolves and installs collection dependencies.

**Hint**: Dependencies must also be collections (not standalone roles) for automatic resolution to work properly.

---

### Exercise 5: Publish a Collection to Galaxy (Conceptual)

**Objective**: Understand the process of publishing a collection.

**Steps**:
1. Create a GitHub repository for your collection
2. Push your collection structure to the repository
3. Create a release (git tag) in GitHub
4. Connect your GitHub account to Ansible Galaxy
5. Import the collection from GitHub
6. Document the import process and what happens if the collection fails validation

**Expected Outcome**: You understand the full publishing workflow, even if you only go through it conceptually.

**Hint**: Galaxy validates collections for structure, required files (`galaxy.yml`), and proper formatting before accepting them.

## Summary

- Collections are the standard packaging format for Ansible content, replacing the old "Ansible itself ships all modules" model
- A collection is identified by `namespace.collection.name` and can contain modules, plugins, roles, and playbooks
- Install collections with `ansible-galaxy collection install` or a `requirements.yml` file
- Use collection modules with their FQCN (e.g., `amazon.aws.ec2_instance`) or short names with `collections:` in the play
- Key collections include `ansible.posix`, `community.general`, `amazon.aws`, and `kubernetes.core`
- Create collections with `ansible-galaxy collection init` and publish them through Ansible Galaxy
- Collections enable independent release cycles and vendor-specific module maintenance

## Additional Resources

- [Ansible Collections Documentation](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html) - Official guide to using and creating collections
- [Ansible Galaxy](https://galaxy.ansible.com) - Browse and install thousands of community and vendor collections
- [Developing Collections](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html) - Detailed guide to building and publishing your own collections.

```md
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../13-dynamic-inventory/" style="color:#8892b0; text-decoration:none;">← Previous: Dynamic Inventory</a>
  <a href="../15-capstone-project/" style="background:#00d4aa; color:#000; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:700;">Next: Capstone Project →</a>
</div>
```
