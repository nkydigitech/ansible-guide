# Chapter 11: Ansible Vault - Securing Sensitive Data

## Learning Objectives

- Understand what Ansible Vault is and why encrypting sensitive data is critical in production
- Create, edit, encrypt, and decrypt files using Ansible Vault commands
- Work with Vault IDs to manage multiple vault passwords
- Integrate encrypted files into playbooks using proper Vault authentication methods
- Apply best practices for Vault management in version control workflows

## Explanation

### Why Ansible Vault?

When you write Ansible playbooks, you inevitably deal with sensitive data: database passwords, API tokens, SSH private keys, TLS certificates, and cloud credentials. Leaving this data in plain text files is a serious security risk. If your repository is compromised or accidentally made public, attackers gain access to your entire infrastructure.

Ansible Vault solves this problem by encrypting files at rest. You can store encrypted versions of variable files, entire playbooks, or any file containing secrets. Ansible seamlessly decrypts these files at runtime when you provide the correct password.

> **Pro Tip**: In production environments, never commit plain-text secrets to version control. Even private repositories can be breached or accidentally made public. Vault is your first line of defense.

### How Vault Works

Ansible Vault uses AES-256 encryption by default (specifically, AES-CBC with a SHA-256 hashed password). When you encrypt a file, Ansible transforms the plain text into ciphertext that is unreadable without the decryption password. At runtime, Ansible prompts for the password, decrypts the file into memory, and uses the data normally.

The original files on disk remain encrypted. Only processes with the correct password can see the actual values.

### Vault Modes

Ansible Vault operates in two modes:

1. **Single Password Mode**: A single password unlocks all encrypted files. Simple but requires careful password management.
2. **Vault ID Mode**: Multiple passwords (identities) allow you to segment secrets. For example, you might have separate vaults for `dev`, `staging`, and `prod` environments.

### Key Vault Commands

| Command | Purpose |
|---------|---------|
| `ansible-vault create` | Create a new encrypted file |
| `ansible-vault encrypt` | Encrypt an existing plain-text file |
| `ansible-vault decrypt` | Decrypt an encrypted file to plain text |
| `ansible-vault edit` | Edit an encrypted file in your default editor |
| `ansible-vault view` | Display an encrypted file without modifying it |
| `ansible-vault rekey` | Change the password on an encrypted file |
| `ansible-vault encrypt_string` | Encrypt a single string for inline use |

## Examples

### Creating an Encrypted File

The simplest way to create an encrypted file is with the `create` command. This opens your default text editor with an empty file. When you save and exit, the file is encrypted.

```bash
# Create a new encrypted variables file
ansible-vault create group_vars/all/secrets.yml
```

Your default editor opens. Add your sensitive variables:

```yaml
---
# This file is encrypted
database_password: "MySecureDBPassword123!"
api_token: "sk-prod-1234567890abcdef"
ssh_key_private: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF8QbR...
  -----END RSA PRIVATE KEY-----
```

When you save and exit, the file is saved as encrypted. You cannot read it with `cat`:

```bash
$ cat group_vars/all/secrets.yml
$ANSIBLE_VAULT;1.1;AES256
65323933396165313936643866343861666665323438323864376638636562353038393964373937
66303936343838363436333631386530316565366634313338323530303830383031393637343...
```

### Encrypting an Existing File

If you already have a file with sensitive data, encrypt it with the `encrypt` command:

```bash
# Encrypt a file containing credentials
ansible-vault encrypt group_vars/prod/vault.yml
```

You will be prompted for a password (twice for confirmation). After encryption, the file contents are no longer readable without the password.

### Viewing Encrypted Files

To view the contents of an encrypted file without modifying it:

```bash
ansible-vault view group_vars/all/secrets.yml
```

This decrypts the file temporarily and displays it to stdout. You cannot accidentally modify the file this way.

### Editing Encrypted Files

To modify an encrypted file, use the `edit` command:

```bash
ansible-vault edit group_vars/all/secrets.yml
```

This decrypts the file, opens it in your editor, and re-encrypts it when you save. This is safer than decrypting to plain text, editing, then manually encrypting again.

### Encrypting Single Strings

Sometimes you only need to encrypt one or two values rather than an entire file. Use `encrypt_string`:

```bash
# Encrypt a single password value
ansible-vault encrypt_string "MySecretPassword" --name "db_password"

# Output:
# db_password: !vault |
#       $ANSIBLE_VAULT;1.1;AES256
#       653239333961653139366438663438616666653234383238...
```

You can then paste this output into an unencrypted vars file. The variable `db_password` holds the encrypted value, which Ansible decrypts at runtime.

### Using Vault IDs for Multiple Environments

Vault IDs allow you to have different passwords for different environments:

```bash
# Create separate vault files with different IDs
ansible-vault create --vault-id dev@prompt group_vars/dev/vault.yml
ansible-vault create --vault-id staging@prompt group_vars/staging/vault.yml
ansible-vault create --vault-id prod@prompt group_vars/prod/vault.yml
```

The `@prompt` suffix tells Ansible to ask for the password interactively. In CI/CD pipelines, you might use password files instead:

```bash
# In a CI/CD pipeline with environment variables
ansible-playbook site.yml \
  --vault-id dev@~/.vault/dev_password \
  --vault-id prod@~/.vault/prod_password
```

### Running Playbooks with Vault

To run a playbook that uses encrypted files, you must provide the vault password. There are several methods:

**Interactive prompt** (not suitable for automation):
```bash
ansible-playbook site.yml --ask-vault-pass
```

**Password file** (suitable for automation):
```bash
ansible-playbook site.yml --vault-password-file ~/.vault/pass
```

**Vault ID with password file** (recommended for multiple environments):
```bash
ansible-playbook site.yml --vault-id dev@~/.vault/dev_pass --vault-id prod@~/.vault/prod_pass
```

**Environment variable** (useful in containerized environments):
```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault/pass
ansible-playbook site.yml
```

### Rekeying Encrypted Files

If you need to change the password on an encrypted file (for example, after an employee leaves or a password is compromised):

```bash
# Change the password on a file
ansible-vault rekey group_vars/all/secrets.yml

# Or with Vault IDs
ansible-vault rekey --vault-id prod@old_password_file --vault-id prod@new_password_file group_vars/prod/vault.yml
```

You will be prompted for both the old and new passwords.

## Hands-On Exercises

### Exercise 1: Create and View an Encrypted File

**Objective**: Create an encrypted variables file and view its contents.

**Steps**:
1. Create a new directory `vault_practice` and navigate to it
2. Run `ansible-vault create secrets.yml`
3. Add three variables: `db_user`, `db_password`, and `api_key` with realistic values
4. Save and exit the editor
5. Run `cat secrets.yml` to confirm the file is encrypted
6. Run `ansible-vault view secrets.yml` to display the decrypted contents

**Expected Outcome**: You can see the encrypted gibberish with `cat`, but `ansible-vault view` displays the original variable values.

**Hint**: If your default editor is not set, set it with `export EDITOR=vim` before running the create command.

---

### Exercise 2: Encrypt Existing Variables

**Objective**: Practice converting a plain-text file to encrypted.

**Steps**:
1. Create a file `group_vars/web/vars.yml` with these variables:
   ```yaml
   app_version: "2.1.0"
   admin_email: "admin@example.com"
   secret_token: "insecure_plain_text_token"
   ```
2. Encrypt the file with `ansible-vault encrypt group_vars/web/vars.yml`
3. Try to open the file with a plain text viewer—you should only see encrypted content
4. Run a test with `ansible-vault view group_vars/web/vars.yml`

**Expected Outcome**: The original variables are hidden behind encryption, but visible when using Ansible Vault commands with the correct password.

**Hint**: The `ansible-vault encrypt` command overwrites the original file. Make sure you remember your password, or keep a backup if needed.

---

### Exercise 3: Use Encrypted Variables in a Playbook

**Objective**: Integrate Vault-encrypted variables into a working playbook.

**Steps**:
1. Create an encrypted file `group_vars/all/credentials.yml` with:
   ```yaml
   deploy_user: "deploybot"
   deploy_key: "ssh-rsa AAAA... user@host"
   ```
2. Create a simple playbook `test_vault.yml`:
   ```yaml
   ---
   - name: Test Vault Integration
     hosts: localhost
     gather_facts: false
     vars_files:
       - group_vars/all/credentials.yml
     tasks:
       - name: Display deploy user (first 3 chars only, for security)
         ansible.builtin.debug:
           msg: "Deploy user is {{ deploy_user[0:3] }}***"
   ```
3. Run the playbook with `ansible-playbook test_vault.yml --ask-vault-pass`
4. Enter the vault password when prompted

**Expected Outcome**: The playbook runs successfully, displaying "Dep***" and proving that the encrypted variables were properly decrypted and used.

**Hint**: The `vars_files` directive loads encrypted variable files automatically. You do not need special syntax for Vault files—they work like regular variable files once decrypted.

---

### Exercise 4: Manage Multiple Vault IDs

**Objective**: Practice using Vault IDs to separate dev and prod secrets.

**Steps**:
1. Create two directories: `group_vars/dev/` and `group_vars/prod/`
2. Create two password files:
   - `~/.vault/dev_pass` containing `dev_password`
   - `~/.vault/prod_pass` containing `prod_password`
3. Create encrypted files for each environment:
   ```bash
   ansible-vault create --vault-id dev@~/.vault/dev_pass group_vars/dev/vault.yml
   ansible-vault create --vault-id prod@~/.vault/prod_pass group_vars/prod/vault.yml
   ```
4. Add environment-specific values (e.g., `environment: development` vs `environment: production`)
5. Run a playbook using both vault IDs:
   ```bash
   ansible-playbook test_multi_vault.yml \
     --vault-id dev@~/.vault/dev_pass \
     --vault-id prod@~/.vault/prod_pass
   ```

**Expected Outcome**: Ansible uses the correct password for each file based on the Vault ID, allowing different secrets for different environments.

**Hint**: If you use the same vault ID label for both files but with different password files, Ansible tries the passwords in order until one works. The Vault ID is a label, not the password itself.

---

### Exercise 5: Rekey and Audit Vault Usage

**Objective**: Practice changing vault passwords and auditing where Vault is used.

**Steps**:
1. Create an encrypted file with a test password
2. List all files in your project that contain `$ANSIBLE_VAULT` strings:
   ```bash
   grep -r "\$ANSIBLE_VAULT" . --include="*.yml" --include="*.yaml"
   ```
3. Rekey the file to a new password
4. Verify the file still works with the new password
5. Try to view it with the old password (it should fail)

**Expected Outcome**: You can identify encrypted files in your project, change their passwords, and verify that old passwords no longer work.

**Hint**: In production, always rotate vault passwords periodically and after any potential security incident. Store the new password securely before rekeying all files.

## Summary

- Ansible Vault encrypts sensitive files using AES-256, protecting passwords, tokens, and keys from unauthorized access
- Use `ansible-vault create` to make new encrypted files and `ansible-vault encrypt` to convert existing files
- `ansible-vault edit` and `ansible-vault view` allow safe modification and reading of encrypted content
- Vault IDs enable managing multiple passwords for different environments (dev, staging, prod)
- Provide vault passwords to playbooks via `--ask-vault-pass`, `--vault-password-file`, or `--vault-id`
- Never commit plain-text secrets to version control; always use Vault for sensitive data
- Regularly rekey vault files and audit where encrypted files are used in your infrastructure

## Additional Resources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html) - Official Ansible documentation covering all Vault operations
- [Ansible Vault Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html#vault) - Recommended patterns for using Vault in production
- [Encrypting Sensitive Data in Ansible](https://www.redhat.com/sysadmin/ansible-vault) - Red Hat sysadmin article with practical examples and security considerations

```md
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-top:50px; padding-top:24px; border-top:1px solid #2a3a5c;">
  <a href="../10-conditionals-loops/" style="color:#8892b0; text-decoration:none;">← Previous: Conditionals</a>
  <a href="../12-error-handling/" style="background:#6c63ff; color:#fff; padding:8px 18px; border-radius:8px; text-decoration:none; font-weight:600;">Next: Error Handling →</a>
</div>
```
