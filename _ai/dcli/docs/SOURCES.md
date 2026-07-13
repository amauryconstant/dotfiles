# Build from Source

## Overview

The `sources` feature lets you declaratively build and install packages directly from a git repository using `makepkg`. The result is a proper pacman-tracked package — meaning you get clean installs, version tracking, and simple uninstalls with `pacman -R`, all without touching the AUR.

**Use sources when you need:**

- A package that doesn't exist in pacman repos or the AUR
- A specific git branch or fork of a package
- Full control over build flags and install steps
- Packages that must be compiled from source on your exact hardware

**Requirements:** `base-devel` must be installed (it provides `makepkg`).

---

## How It Works

1. You create a `source.yaml` (or `source.lua`) config file describing the git repo and build steps
2. `dcli` generates a temporary `PKGBUILD` from that config and runs `makepkg -si`
3. `makepkg` clones the repo, runs your build commands, and installs the resulting package via pacman
4. The package is now tracked by pacman — uninstall with `dcli source remove <name>` or `pacman -R <name>`

Sources are automatically built during `dcli sync` if the package isn't already installed.

---

## Directory Structure

Place source configs in `~/.config/arch-config/sources/`. Two layouts are supported:

**Directory layout (recommended):**
```
sources/
└── hyprland-git/
    └── source.yaml    # or source.lua
```

**Flat file layout:**
```
sources/
├── hyprland-git.yaml
└── myapp-git.lua
```

---

## YAML Configuration

### Minimal Example

```yaml
# ~/.config/arch-config/sources/hello-git/source.yaml
name: hello-git
description: GNU Hello from git

source:
  url: https://github.com/example/hello.git

build:
  build_commands:
    - ./configure --prefix=/usr
    - make

  package_commands:
    - make DESTDIR="$pkgdir" install
```

### Full Example

```yaml
# ~/.config/arch-config/sources/hyprland-git/source.yaml
name: hyprland-git
description: Hyprland Wayland compositor built from git

source:
  url: https://github.com/hyprwm/Hyprland.git
  branch: main                # Optional: branch, tag, or commit (defaults to repo default)

build:
  dependencies:               # Build-time only — removed after install (makedepends)
    - cmake
    - meson
    - ninja
    - pkg-config

  runtime_dependencies:       # Kept after install (depends)
    - wayland
    - libxkbcommon
    - pixman

  build_commands:             # Runs inside build() — working dir is $srcdir/<repo>
    - meson setup build --prefix=/usr --buildtype=release
    - ninja -C build

  package_commands:           # Runs inside package() — working dir is $srcdir/<repo>
    - ninja -C build DESTDIR="$pkgdir" install

# Optional: use your own PKGBUILD instead of generating one
# custom_pkgbuild: pkgbuild/PKGBUILD

# Optional: keep build directory between builds for faster rebuilds (default: false)
# cache_builds: true
```

### All YAML Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Package name. Used as the pacman package name after install. |
| `description` | No | Short description shown in `dcli source list` and the generated PKGBUILD. |
| `source.url` | Yes | Git URL to clone. |
| `source.branch` | No | Branch, tag, or commit to check out. Defaults to the repo's default branch. |
| `build.dependencies` | No | Build-time dependencies (`makedepends`). Installed before build and removed after. |
| `build.runtime_dependencies` | No | Runtime dependencies (`depends`). Kept after install. |
| `build.build_commands` | No | Shell commands run in the `build()` function. Working directory is `$srcdir/<repo>`. |
| `build.package_commands` | No | Shell commands run in the `package()` function. Working directory is `$srcdir/<repo>`. |
| `custom_pkgbuild` | No | Path to a custom PKGBUILD file (relative to the source config directory). Skips generation. |
| `cache_builds` | No | If `true`, reuses `~/.cache/dcli/sources/<name>/` between builds instead of a temp directory. |

---

## Lua Configuration

Lua sources support the same fields as YAML but allow conditional logic using the full dcli Lua API (hardware detection, system queries, etc.).

### Minimal Example

```lua
-- ~/.config/arch-config/sources/hello-git/source.lua
return {
    name = "hello-git",
    description = "GNU Hello from git",
    url = "https://github.com/example/hello.git",
    build_commands = {
        "./configure --prefix=/usr",
        "make",
    },
    package_commands = {
        "make DESTDIR='$pkgdir' install",
    },
}
```

### Full Example

```lua
-- ~/.config/arch-config/sources/hyprland-git/source.lua
local deps = {"cmake", "meson", "ninja", "pkg-config"}

-- Add extra deps on Nvidia systems
if dcli.hardware.has_nvidia() then
    table.insert(deps, "libglvnd")
end

return {
    name        = "hyprland-git",
    description = "Hyprland Wayland compositor built from git",

    url    = "https://github.com/hyprwm/Hyprland.git",
    branch = "main",

    dependencies = deps,

    runtime_dependencies = {
        "wayland",
        "libxkbcommon",
        "pixman",
    },

    build_commands = {
        "meson setup build --prefix=/usr --buildtype=release",
        "ninja -C build",
    },

    package_commands = {
        "ninja -C build DESTDIR='$pkgdir' install",
    },

    cache_builds = true,
}
```

### All Lua Fields

The Lua table accepts the same fields as YAML, but flat (no nested `source:` / `build:` sections):

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Package name. |
| `description` | No | string | Short description. |
| `url` | Yes | string | Git URL to clone. |
| `branch` | No | string | Branch, tag, or commit. |
| `dependencies` | No | table of strings | Build-time dependencies. |
| `runtime_dependencies` | No | table of strings | Runtime dependencies. |
| `build_commands` | No | table of strings | Commands run in `build()`. |
| `package_commands` | No | table of strings | Commands run in `package()`. |
| `custom_pkgbuild` | No | string | Path to a custom PKGBUILD (relative to config dir). |
| `cache_builds` | No | boolean | Reuse build directory between builds. |

The full dcli Lua API is available — see [DCLI-LUA-API.md](DCLI-LUA-API.md) for all `dcli.hardware`, `dcli.system`, `dcli.package`, etc. helpers.

---

## Generated PKGBUILD

When no `custom_pkgbuild` is specified, dcli generates a PKGBUILD like this:

```bash
# Generated by dcli — do not edit manually
pkgname=hyprland-git
pkgver=0
pkgrel=1
pkgdesc="Hyprland Wayland compositor built from git"
arch=('x86_64')
url="https://github.com/hyprwm/Hyprland.git"
makedepends=('cmake' 'meson' 'ninja' 'pkg-config')
depends=('wayland' 'libxkbcommon' 'pixman')
source=("git+https://github.com/hyprwm/Hyprland.git#branch=main")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/Hyprland"
    git describe --long --tags --abbrev=7 2>/dev/null \
        | sed 's/\([^-]*-g\)/r\1/;s/-/./g' \
        || printf "r%s.g%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short=7 HEAD)"
}

build() {
    cd "$srcdir/Hyprland"
    meson setup build --prefix=/usr --buildtype=release
    ninja -C build
}

package() {
    cd "$srcdir/Hyprland"
    ninja -C build DESTDIR="$pkgdir" install
}
```

The `pkgver()` function auto-detects the version from git tags (e.g. `0.45.0.r123.gabc1234`). If the repo has no tags, it falls back to `r{commit_count}.g{short_hash}`.

---

## Commands

```bash
# List all declared sources and whether they are installed
dcli source list

# Show install status summary
dcli source status

# Build all sources that are not yet installed
dcli source build

# Build a specific source
dcli source build hyprland-git

# Force a clean rebuild (even if already installed)
dcli source rebuild
dcli source rebuild hyprland-git

# Uninstall a source-built package
dcli source remove hyprland-git
```

Sources are also built automatically as part of `dcli sync` — any source that is not yet installed will be built and installed when you run `dcli sync`.

---

## Build Directories

By default, each build uses a temporary directory (`/tmp/dcli-source-<name>/`) that is cleaned up after a successful build.

If a build **fails**, the directory is kept so you can inspect the PKGBUILD and build output:

```
Build directory kept for inspection: /tmp/dcli-source-hyprland-git/
```

To keep the build directory between builds (useful for large repos that take a long time to clone):

```yaml
cache_builds: true
```

This stores the build in `~/.cache/dcli/sources/<name>/` and reuses the existing git clone on subsequent builds.

---

## Custom PKGBUILD

If the auto-generated PKGBUILD is insufficient — for example, you need a `prepare()` function, patches, or special install logic — you can provide your own:

```yaml
name: myapp-git
description: My app

source:
  url: https://github.com/user/myapp.git

custom_pkgbuild: pkgbuild/PKGBUILD
```

The path is relative to the directory containing `source.yaml`. Place your `PKGBUILD` there:

```
sources/
└── myapp-git/
    ├── source.yaml
    └── pkgbuild/
        └── PKGBUILD
```

dcli will copy your PKGBUILD into the build directory and run `makepkg` as normal.

---

## Tips

- **Naming:** Use the `-git` suffix convention (e.g. `hyprland-git`) to make it clear the package is built from a VCS source, consistent with AUR `-git` packages.
- **Conflicts with repos:** If a package with the same name exists in the official repos or AUR, makepkg will still install your locally-built version. dcli will warn you when listing.
- **Uninstalling build deps:** `makepkg --rmdeps` is used by default, so build-time dependencies are removed after the package is installed.
- **Inspecting the PKGBUILD:** Run `dcli source build <name>` and look in `/tmp/dcli-source-<name>/PKGBUILD` before it completes (or check a failed build dir) to see exactly what dcli generated.
