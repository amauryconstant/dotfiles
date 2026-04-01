# mise Troubleshooting Guide

Always start with:

```sh
mise doctor        # Comprehensive diagnostic report
```

## Common Issues

### Version Not Switching When I cd Into Directory

**Symptom:** `mise use node@22` in project, but `node -v` still shows old version

**Likely causes:**

1. **Shell integration not activated**

   ```sh
   # Check if activated
   echo $MISE_SHELL_INIT    # Should be non-empty

   # Add to ~/.zshrc or ~/.bashrc
   eval "$(mise activate zsh)"
   ```

2. **Using shims instead of activate**
   - Shims don't dynamically switch; they're static
   - Only activate mode (not --shims) provides dynamic switching
   - GUI apps need --shims, but interactive shells need activate

3. **Shell rc file not being sourced**

   ```sh
   # Verify rc file is loaded
   grep "mise activate" ~/.zshrc    # For zsh
   source ~/.zshrc                  # Reload manually
   ```

**Solution:**

```sh
# 1. Add to shell rc
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# 2. Start a new shell
exec zsh

# 3. Verify
mise current    # Should show your configured versions
```

---

### Command Not Found Even After `mise use`

**Symptom:** `npm -v` says "command not found" but `mise install` succeeded

**Causes:**

1. **Tools installed but not in PATH**

   ```sh
   mise which npm      # Should show path
   echo $PATH          # Should include ~/.local/share/mise/shims
   ```

2. **Wrong activation mode for environment**
   - Interactive shell: use `eval "$(mise activate zsh)"`
   - Non-interactive (cron, systemd): use `eval "$(mise activate bash --shims)"`
   - GUI app (Hyprland): use --shims in `~/.profile` or session env

3. **Shell doesn't source activation**

   ```sh
   # Test directly
   eval "$(mise activate bash)"
   npm -v
   ```

**Solution:**

```sh
# For interactive shells
eval "$(mise activate zsh)"

# For non-interactive (add to ~/.profile or ~/.bashrc)
eval "$(mise activate bash --shims)"

# Then reload shell or restart session
```

---

### `mise doctor` Reports Errors

**Common doctor errors:**

### Error: "mise not found in PATH"

```sh
# Reinstall or add to PATH
~/.local/bin/mise --version
export PATH="$HOME/.local/bin:$PATH"
```

### Error: "No tools defined"

```sh
# Create a mise.toml
echo '[tools]
node = "22"' > mise.toml
mise install
```

### Error: "Tool version not installed"

```sh
# Install tools defined in mise.toml
mise install

# Or install specific tool
mise install node@22
```

---

### Performance Issues / Slow Installation

**Slow downloads:**

```sh
# Check timeout setting (default 30s)
mise env | grep TIMEOUT

# Increase timeout for slow connections
export MISE_HTTP_TIMEOUT=60

# Check download status
mise ls-remote node    # If slow, network issue
```

**Slow version switching:**

Use shims for better performance in non-interactive contexts:

```sh
eval "$(mise activate bash --shims)"   # vs activate
```

**Keep downloaded archives:**

```toml
[settings]
always_keep_download = true   # Don't delete after install
```

---

### Task Not Being Discovered

**Symptom:** `mise tasks` shows nothing or task is missing

**TOML tasks:**

```sh
# Verify mise.toml exists and has [tasks]
cat mise.toml | grep "\[tasks"

# Check for typos
mise tasks                    # Lists all available tasks
```

**File-based tasks:**

```sh
# Task must be in correct directory
ls mise-tasks/                # or .mise/tasks/, .mise-tasks/, etc.

# Script must be executable
chmod +x mise-tasks/mytask
ls -l mise-tasks/mytask       # Should show 'x' permission

# Test directly
./mise-tasks/mytask
```

**Namespace/domain not found:**

```sh
# For task in directory structure
ls mise-tasks/build/          # File: mise-tasks/build/compile
mise run build:compile        # Correct invocation

# For TOML tasks with domain
[tasks.test:unit]
run = "..."
# Correct: mise run test:unit
```

---

### Config Not Being Applied

**Symptom:** Changes in mise.toml don't take effect

**Causes:**

1. **Wrong file being loaded**

   ```sh
   # Check which config is active
   mise config                      # Shows current config path

   # Check file search order
   mise doctor | grep "Config"
   ```

2. **Parent directory config overriding**

   ```sh
   # Check if parent has different config
   cat ../mise.toml

   # Local override takes precedence
   echo '[tools]
   node = "22"' > mise.local.toml
   ```

3. **min_version check**

   ```sh
   # Verify installed version meets requirement
   mise --version
   # If older than min_version, update mise
   ```

**Solution:**

```sh
# 1. Verify config file location
cat mise.toml

# 2. Check for conflicting parent configs
ls ../mise.toml

# 3. Reload shell to pick up changes
exec zsh

# 4. Verify tools are installed
mise install
mise current
```

---

### Environment Variables Not Set

**Symptom:** Env vars defined in `[env]` section not available

**Causes:**

1. **Shell activation missing**

   ```sh
   # Env vars only set when activated
   eval "$(mise activate zsh)"
   env | grep MY_VAR
   ```

2. **Wrong syntax in `[env]`**

   ```toml
   # Wrong:
   [env]
   VAR = { required }

   # Correct:
   [env]
   VAR = { required = true }
   ```

3. **Variable redacted in output**

   ```sh
   # Sensitive vars are redacted by default
   mise env                    # Shows [redacted]
   mise env --redacted         # Reveals values
   ```

4. **Templating syntax error**

   ```toml
   # Check for typos in template
   LD_LIBRARY_PATH = "{{env.LD_LIBRARY_PATH}}"  # Correct
   LD_LIBRARY_PATH = "{{env.LD_PATH}}"          # Wrong
   ```

**Debug:**

```sh
mise env                       # See all vars
mise env --json                # Structured format
MISE_LOG_LEVEL=debug mise env # Verbose
```

---

### Shell Integration Doesn't Work in IDE

**Symptom:** Tool versions work in terminal but not in IDE (VSCode, Neovim, etc.)

**Cause:** IDEs run in non-interactive context; need shim activation

**Solution:**

1. **Add to `~/.profile` or `~/.bashrc` (not rc files)**

   ```sh
   eval "$(mise activate bash --shims)"
   ```

2. **Or set env var in IDE settings:**
   - VSCode: `terminal.integrated.shellArgs.linux: ["-l"]` (load profile)
   - Neovim: run `:!eval "$(mise activate bash --shims)" && vim`

3. **Verify PATH in IDE:**
   - Open IDE from terminal: `code .` (inherits PATH)
   - Check IDE terminal: `echo $PATH` includes `~/.local/share/mise/shims`

---

### `mise run` Task Fails Silently

**Symptom:** `mise run mytask` exits with no output

**Causes:**

1. **Task defined but has error**

   ```sh
   # Run with verbose output
   MISE_LOG_LEVEL=debug mise run mytask
   ```

2. **File-based task not executable**

   ```sh
   chmod +x mise-tasks/mytask
   ```

3. **External script missing**

   ```toml
   [tasks.mytask]
   file = "scripts/build.sh"
   # Verify scripts/build.sh exists
   ```

4. **Task has dependencies that fail**

   ```toml
   [tasks.mytask]
   depends = ["other_task"]    # Check if other_task succeeds
   ```

**Debug:**

```sh
# Run task with output
mise run mytask --verbose

# Run underlying command directly
bash scripts/build.sh

# Check task definition
mise tasks mytask
```

---

### Permission Denied When Installing Tools

**Symptom:** `Permission denied` or `cannot create directory`

**Cause:** MISE_DATA_DIR not writable

**Solution:**

```sh
# Check where tools are installed
echo $MISE_DATA_DIR            # Usually ~/.local/share/mise

# Verify directory is writable
touch ~/.local/share/mise/test
rm ~/.local/share/mise/test

# Or set custom location
export MISE_DATA_DIR=~/my_tools
mkdir -p $MISE_DATA_DIR
```

---

### Multiple Node/Python Versions Interfering

**Symptom:** Multiple version managers installed (nvm, pyenv, mise), causing conflicts

**Solution:**

1. **Remove or disable other version managers**

   ```sh
   # Remove from shell rc
   grep -n "nvm\|pyenv\|asdf" ~/.zshrc
   # Comment out or remove those lines
   ```

2. **Use mise exclusively**

   ```toml
   [tools]
   node = "22"
   python = "3.12"
   ```

3. **Verify only mise is active**

   ```sh
   which node
   # Should show ~/.local/share/mise/shims/node
   ```

---

## Getting Help

1. **Run diagnostics:**

   ```sh
   mise doctor        # Comprehensive check
   ```

2. **Check logs:**

   ```sh
   MISE_LOG_LEVEL=debug mise install
   ```

3. **Verify config:**

   ```sh
   cat mise.toml
   mise config
   ```

4. **Test specific tool:**

   ```sh
   mise exec node@22 -- node -v
   ```

5. **Check documentation:**
   - <https://mise.jdx.dev>
   - `mise --help`
   - `mise <command> --help`
