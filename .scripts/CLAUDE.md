# Repository Helper Scripts

**Location**: `.scripts/` (repo utilities — never applied to the system)
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

Two scripts live here:

| Script | Role |
|--------|------|
| `template-merge-driver.sh` | Git merge driver that preserves `{{ }}` template syntax in `*.tmpl` files |
| `install-password-manager-and-encryption.sh` | chezmoi init bootstrap — invoked by `.chezmoi.yaml.tmpl` (`scriptEnv`/prompt) to install the password manager + age tooling before first apply |

---

## Template Merge Driver

**Why**: a normal Git merge of a `.tmpl` file can resolve to the *rendered* value (`{{ .firstname }}` → `John`), silently corrupting the template. This driver keeps the side that still contains template syntax.

**Algorithm** (`template-merge-driver.sh`): detect `{{ }}` (via `grep -q '{{.*}}'`) in base/ours/theirs; prefer the version that retains templates; fall back to a standard merge when both sides are templated. Exit `0` = merged, `1` = conflict needing manual resolution.

**Wiring** (two halves, both required):
- **`.gitattributes`** (repo root): `*.tmpl merge=chezmoi-template` (and `*.age binary` — encrypted files are never merged).
- **Driver registration**: `.chezmoiscripts/run_once_after_001_configure_developer_tools.sh.tmpl` runs `git config merge.chezmoi-template.driver "<sourceDir>/.scripts/template-merge-driver.sh %O %A %B %L %P"` in the **chezmoi source repo's local git config**. It is *not* defined in `private_dot_config/git/config.tmpl` (that file only registers the unrelated `mergiraf` driver for source-code files). The driver runs in place from the source dir — it is not copied to `~/.scripts/`.

Driver args: `%O` base, `%A` ours, `%B` theirs, `%L` conflict-marker size, `%P` real pathname.

**Don't confuse** `chezmoi-template` (this repo's `.tmpl` files) with `mergiraf` (syntax-aware merge for `.go`/`.rs`/`.yaml`/… deployed via `~/.gitattributes`). They are independent.

See `private_dot_config/git/CLAUDE.md` for the merge-conflict resolution workflow.
