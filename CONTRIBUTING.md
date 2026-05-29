# Contributing to Patina

Thank you for your interest in contributing. Please read this document before submitting any work.

---

## Prerequisites

1. **Clone the repository and initialise submodules**

   ```bash
   git clone ssh://git@forgejo.wulf.science/WulfScience-FOSS/patina.git
   cd patina
   ./update.sh
   ```

2. **Install the git hooks**

   ```bash
   ./scripts/install-hooks.sh
   ```

3. **Configure commit signing**

   All commits must be signed with an SSH key. Configure your local repository:

   ```bash
   git config user.email "you@example.com"
   git config user.signingkey "/path/to/your/key.pub"
   git config gpg.format ssh
   git config gpg.ssh.allowedSignersFile ".git/allowed_signers"
   git config commit.gpgsign true
   git config tag.gpgsign true
   ```

   Then add your public key to `.git/allowed_signers`:

   ```
   your@email.com ssh-ed25519 AAAA... your-key-comment
   ```

   The pre-push hook will reject any push containing unsigned commits.

---

## Workflow

Follow the branch and commit discipline defined in [CLAUDE.md](CLAUDE.md):

- One branch per unit of work: `feat/<name>`, `fix/<name>`, `docs/<name>`, etc.
- One sub-branch per discrete change: `<type>/<name>--<change>`
- Commits must be as small as possible
- All tests must pass before merging a sub-branch to its parent branch
- All tests must pass and the feature must be complete before merging to `main`

## Development workflow

Every feature follows this sequence — no exceptions:

```
PRIOR ART → SPEC → THREAT MODEL → TESTS (failing) → IMPLEMENTATION → TESTS (passing) → DOCS
```

See [CLAUDE.md](CLAUDE.md) for the full phase gate checklist.

---

## Canonical repository

This project is hosted on Forgejo at `forgejo.wulf.science/WulfScience-FOSS/patina`.
The following mirrors are read-only — please open issues and pull requests on Forgejo only:

- GitHub: `github.com/Wulf-Science-Foss/patina`
- GitLab: `gitlab.com/wulf-science-foss/patina`
