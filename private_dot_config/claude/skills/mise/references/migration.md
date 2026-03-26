# Migration Guides to mise

mise is a drop-in replacement for nvm, pyenv, rbenv, asdf, direnv, and more. This guide shows step-by-step migrations.

## asdf → mise

asdf users have the easiest migration path—mise reads `.tool-versions` format natively.

**Step 1: Install mise**
```sh
curl https://mise.jdx.dev/install.sh | sh
```

**Step 2: Add to shell**
```sh
eval "$(mise activate zsh)"  # or bash, fish, etc.
```

**Step 3: Enable idiomatic version file reading**
```toml
# ~/.config/mise/config.toml
[settings]
idiomatic_version_file_enable_tools = ["node", "python", "ruby", "go"]
```

**Step 4: Install all tools**
```sh
mise install    # Reads your existing .tool-versions file
```

**Step 5 (optional): Migrate to mise.toml**
```sh
# Your .tool-versions still works, but optionally convert to mise.toml
cat .tool-versions
# asdf format:
#   node 20.0.0
#   python 3.11
#   go latest

# Create mise.toml with [tools] section
echo '[tools]
node = "20.0.0"
python = "3.11"
go = "latest"' > mise.toml
```

**Why migrate to mise.toml:**
- More powerful (env vars, tasks, settings)
- Easier to read than `.tool-versions`
- Can add tasks and environment setup

**Result:** asdf configs work immediately; optionally use mise's enhanced features.

---

## nvm → mise

Node Version Manager users have most setup in shell rc.

**Step 1: Remove nvm from shell**
```bash
# Remove or comment out from ~/.zshrc or ~/.bashrc
# Lines like:
#   export NVM_DIR=~/.nvm
#   [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

**Step 2: Install mise**
```sh
curl https://mise.jdx.dev/install.sh | sh
```

**Step 3: Add mise to shell**
```sh
eval "$(mise activate zsh)"
```

**Step 4: Migrate `.nvmrc` files**
```sh
# If you have .nvmrc in projects:
cat .nvmrc
# Output: 20.0.0

# Create mise.toml (or add [tools] section)
echo '[tools]
node = "20.0.0"' > mise.toml
```

**Step 5: Install Node versions**
```sh
mise install
```

**Step 6: Verify**
```sh
node -v        # Should show configured version
mise current   # Shows active versions
```

**Bonus: Add npm global packages**
```toml
[tools]
node = "20.0.0"
"npm:typescript" = "latest"
"npm:prettier" = "latest"
"npm:@types/node" = "^20"
```

**Result:** Node version management with added ability to manage global npm packages.

---

## pyenv → mise

Python Version Manager users have pyenv in shell rc and `.python-version` files.

**Step 1: Remove pyenv from shell**
```bash
# Remove or comment out from ~/.zshrc or ~/.bashrc
# Lines like:
#   export PYENV_ROOT=~/.pyenv
#   eval "$(pyenv init --path)"
#   eval "$(pyenv init -)"
```

**Step 2: Install mise**
```sh
curl https://mise.jdx.dev/install.sh | sh
```

**Step 3: Add mise to shell**
```sh
eval "$(mise activate zsh)"
```

**Step 4: Enable `.python-version` reading**
```toml
# ~/.config/mise/config.toml
[settings]
idiomatic_version_file_enable_tools = ["python"]
```

**Step 5: Install Python versions**
```sh
mise install    # Reads .python-version files and installs
```

**Step 6: Migrate to mise.toml (optional)**
```sh
# If you have .python-version in projects:
cat .python-version
# Output: 3.12

# Create mise.toml
echo '[tools]
python = "3.12"' > mise.toml
```

**Step 7: Add Python tools (optional)**
```toml
[tools]
python = "3.12"
"pipx:poetry" = "latest"
"pipx:black" = "latest"
"pipx:ruff" = "latest"

[settings.python]
uv_venv_auto = true    # Auto-create venvs
```

**Step 8: Verify**
```sh
python -v
poetry --version    # If added to tools
```

**Result:** Python version management with integrated tool installation and venv management.

---

## rbenv → mise

Ruby Version Manager users have rbenv in shell rc and `.ruby-version` files.

**Step 1: Remove rbenv from shell**
```bash
# Remove or comment out from ~/.zshrc or ~/.bashrc
# Lines like:
#   export RBENV_ROOT=~/.rbenv
#   eval "$(rbenv init -)"
```

**Step 2: Install mise**
```sh
curl https://mise.jdx.dev/install.sh | sh
```

**Step 3: Add mise to shell**
```sh
eval "$(mise activate zsh)"
```

**Step 4: Enable `.ruby-version` reading**
```toml
# ~/.config/mise/config.toml
[settings]
idiomatic_version_file_enable_tools = ["ruby"]
```

**Step 5: Install Ruby versions**
```sh
mise install    # Reads .ruby-version files
```

**Step 6: Migrate to mise.toml (optional)**
```sh
cat .ruby-version
# Output: 3.2.0

echo '[tools]
ruby = "3.2.0"' > mise.toml
```

**Step 7: Verify**
```sh
ruby -v
gem -v
```

**Result:** Ruby version management with full feature parity to rbenv.

---

## direnv → mise

direnv is an environment loader; mise covers environment setup via `[env]` section.

**Step 1: Remove direnv from shell**
```bash
# Remove eval "$(direnv hook zsh)" or similar from ~/.zshrc
```

**Step 2: Install mise**
```sh
curl https://mise.jdx.dev/install.sh | sh
eval "$(mise activate zsh)"
```

**Step 3: Convert `.envrc` to `mise.toml`**

**Before (direnv):**
```bash
# .envrc
export DATABASE_URL="postgres://localhost/mydb"
export LOG_LEVEL="debug"
PATH_add "./bin"
```

**After (mise):**
```toml
# mise.toml
[env]
DATABASE_URL = "postgres://localhost/mydb"
LOG_LEVEL = "debug"
_.path = "./bin"
```

**Step 4: Advanced direnv patterns**

**Load env file:**
```bash
# Before (.envrc):
dotenv .env.local

# After (mise.toml):
[env]
_.file = ".env.local"
```

**Source shell script:**
```bash
# Before (.envrc):
source_env .envrc.sh

# After (mise.toml):
[env]
_.source = ".envrc.sh"
```

**Required variable:**
```bash
# Before (.envrc):
export_if_undefined API_KEY "Get key at..."

# After (mise.toml):
[env]
API_KEY = { required = "Get key at..." }
```

**Step 5: Verify**
```sh
mise env                # See all env vars
env | grep DATABASE_URL # Should be set
```

**Result:** Environment setup without a separate tool; integrated with tool version management.

---

## Multiple Tools → mise

If using multiple tools (nvm + pyenv + rbenv), consolidate into one:

**Before:**
```bash
# ~/.zshrc has:
export NVM_DIR=~/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(rbenv init -)"
eval "$(direnv hook zsh)"
```

**After:**
```bash
# ~/.zshrc has:
eval "$(mise activate zsh)"
```

**Single mise.toml:**
```toml
[tools]
node = "22"
python = "3.12"
ruby = "3.2"

[env]
DATABASE_URL = "postgres://localhost/mydb"
LOG_LEVEL = "debug"
_.path = ["./bin", "./scripts"]

[tasks.dev]
run = "npm run dev & python manage.py runserver"
```

**Result:** Single tool managing all runtimes, environments, and tasks.

---

## Migration Checklist

- [ ] Uninstall old tool (nvm, pyenv, rbenv, asdf, direnv)
- [ ] Remove from shell rc file
- [ ] Install mise
- [ ] Add `eval "$(mise activate zsh)"` to shell rc
- [ ] Create `mise.toml` or enable idiomatic version files
- [ ] Run `mise install`
- [ ] Test: `mise current`, `mise env`, tool commands
- [ ] Delete `.nvmrc` / `.python-version` / `.ruby-version` / `.envrc` (optional—mise reads them)
- [ ] Update team documentation
- [ ] Commit `mise.toml` to git

---

## FAQ

**Q: Can I use old version files and mise together?**
A: Yes! Enable `idiomatic_version_file_enable_tools` and mise reads `.nvmrc`, `.python-version`, etc.

**Q: Do I need to delete old version files?**
A: No, they're optional. You can keep them for compatibility or migrate gradually.

**Q: What about `mise.lock` or lock files?**
A: mise doesn't use lock files for versions (versions are explicit in `mise.toml`). For task outputs, use `sources` and `outputs` for caching.

**Q: Can I keep asdf plugins?**
A: mise has its own plugins. Most tools have built-in support. Custom asdf plugins may need a mise plugin wrapper.

**Q: How do I handle different Node versions per project?**
A: Create `mise.toml` in each project with its own `[tools]` section. Mise merges configs from parent directories.

**Q: Is migration reversible?**
A: Yes—keep old tool installed and remove mise activation from shell rc. Old tools still work.
