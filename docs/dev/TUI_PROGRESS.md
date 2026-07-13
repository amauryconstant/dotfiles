# dcli TUI Implementation Progress

## Current Status: Phase 1 MVP - Foundation Complete ✅

The basic TUI infrastructure is fully implemented and working. The Overview screen now loads and displays real data from your dcli configuration.

---

## ✅ Completed Tasks

### Infrastructure (100% Complete)
- [x] Added dependencies (ratatui 0.28, crossterm 0.28)
- [x] Created complete `src/tui/` directory structure
- [x] Implemented terminal initialization and cleanup (`terminal.rs`)
- [x] Built event handling system with keyboard/mouse support (`events.rs`)
- [x] Created App state management (`app.rs`)
- [x] Designed Screen trait and enum system (`screens/mod.rs`)

### UI Components (100% Complete)
- [x] Title bar component - shows "DCLI System Manager v{version}"
- [x] Status bar component - displays keybindings and status messages
- [x] Collapsible sidebar menu - navigation with icons
- [x] Modal dialog component - for confirmations and errors
- [x] Main UI rendering orchestration (`ui.rs`)

### Core Functionality (100% Complete)
- [x] Main TUI event loop in `tui/mod.rs`
- [x] Wired TUI to main.rs via `Commands::Tui`
- [x] Basic navigation working (Tab, Esc, q, m for menu toggle)
- [x] Fixed borrow checker issues with screen rendering architecture

### Overview Screen (100% Complete) ✨
- [x] **System Information Panel**
  - Hostname (from config)
  - Auto Prune status (enabled/disabled)
  - Flatpak Scope (user/system)
  - Backup Tool (name or "none")
  
- [x] **Quick Stats Panel**
  - Enabled Modules count (e.g., "9/15")
  - Declared Packages count
  - Installed Packages count (via `pacman -Q`)
  
- [x] **Configuration Structure Panel**
  - Tree view of `~/.config/arch-config/` directory
  - Shows folders and files with icons (📂, 📄, 📜)
  - Walks directory to depth 3
  
- [x] **Refresh functionality** - Press 'r' to reload data

---

## 🚧 TODO: Remaining Phase 1 MVP Screens

### 1. Modules Screen (Next Priority)
**Goal**: Interactive module management

**Features to implement**:
- Load all available modules from `modules/` directory
- Display table with columns: `[Status, Module, Packages, Description]`
  - Status: ✓ for enabled, blank for disabled
  - Module: name from filename
  - Packages: count from module YAML
  - Description: from module metadata
- **Keyboard navigation**:
  - `j`/`k` or arrow keys to navigate list
  - `Enter` or `Space` to toggle enable/disable
  - Visual highlight on selected row
- **State persistence**: Update `config.yaml` when toggling
- **Conflict detection**: Show warning if module has conflicts
- **Refresh**: Press 'r' to reload module list

**Integration points**:
- Use existing `ModuleManager::list_modules()` from `src/module.rs`
- Update `app.config.enabled_modules` vector
- Call existing config save logic

**Files to modify**:
- `/home/don/dcli/src/tui/screens/modules.rs`

---

### 2. Packages Screen
**Goal**: Package search and installation

**Features to implement**:
- **Search input field** at top
- **Filtered package list** showing:
  - Package name
  - Installation status (✓ installed / ○ available)
  - Description (if available)
- **Keyboard controls**:
  - Type to search/filter
  - Arrow keys to navigate results
  - `Enter` to install selected package
  - `d` to remove selected package
  - `Esc` to clear search
- **Confirmation dialogs** before install/remove
- **Progress indicator** during package operations

**Integration points**:
- Search AUR/pacman packages (use existing search logic)
- Add to `config.packages` list
- Call pacman/paru for installation

**Files to modify**:
- `/home/don/dcli/src/tui/screens/packages.rs`

---

### 3. Sync Screen
**Goal**: Preview and execute sync operations

**Features to implement**:
- **Preview Section** showing:
  - Packages to install (count and list)
  - Packages to remove (count and list)
  - Dotfiles to link
  - Hooks to run
- **Execution Section**:
  - "Execute Sync" button/action
  - Live progress bar during sync
  - Real-time log output scrolling
  - Success/error status
- **Keyboard controls**:
  - `Enter` or `s` to start sync
  - `Esc` to cancel (if not started)
  - Scroll through preview with arrows

**Integration points**:
- Call `crate::commands::sync::run()` with appropriate flags
- Capture stdout/stderr for live display
- Show progress using existing progress bar logic

**Files to modify**:
- `/home/don/dcli/src/tui/screens/sync.rs`

---

## 📋 Phase 2 Features (Future)

These are planned for after Phase 1 MVP is complete:

### Additional Screens
- **Config Editor Screen** - View/edit configuration files
- **Hooks Screen** - Manage pre/post hooks
- **Backups Screen** - List and restore backups

### Enhancements
- **Theme support** - Color schemes
- **Help screen** - Detailed keybinding reference (press '?')
- **Better error handling** - User-friendly error dialogs
- **Async operations** - Non-blocking package installation
- **Real-time updates** - Auto-refresh package counts
- **Search history** - Remember recent searches
- **Module preview** - Show module contents before enabling

---

## 🏗️ Technical Architecture

### Current Structure
```
src/tui/
├── mod.rs              # Main event loop, entry point
├── app.rs              # App state (config, current screen, sidebar)
├── ui.rs               # Main rendering orchestration
├── events.rs           # Event handling (keyboard, mouse)
├── terminal.rs         # Terminal init/restore
│
├── components/         # Reusable UI components
│   ├── mod.rs
│   ├── sidebar.rs      # Navigation menu (collapsible)
│   ├── statusbar.rs    # Bottom keybinding hints
│   ├── titlebar.rs     # Top app title
│   └── dialog.rs       # Modal dialogs
│
└── screens/            # Screen implementations
    ├── mod.rs          # ScreenTrait definition
    ├── overview.rs     # ✅ Dashboard (COMPLETE)
    ├── modules.rs      # ⚠️  Module management (TODO)
    ├── packages.rs     # ⚠️  Package search (TODO)
    └── sync.rs         # ⚠️  Sync operations (TODO)
```

### Key Design Patterns

#### Screen Trait
All screens implement this trait:
```rust
pub trait ScreenTrait {
    fn handle_key(&mut self, key: KeyEvent) -> Result<Option<ScreenAction>>;
    fn render(&mut self, paths: &ConfigPaths, config: &Config, frame: &mut Frame, area: Rect) -> Result<()>;
    fn on_activate(&mut self, paths: &ConfigPaths, config: &Config) -> Result<()>;
}
```

**Why this signature?**
- Takes `&ConfigPaths` and `&Config` separately (not `&App`)
- Avoids borrow checker issues when rendering
- Allows mutable screen state while borrowing config data

#### Data Loading Pattern
Screens use a lazy-loading pattern:
```rust
struct ScreenState {
    data: Vec<Item>,
    loaded: bool,
}

fn render(&mut self, paths: &ConfigPaths, config: &Config, ...) {
    if !self.loaded {
        self.load_data(paths, config)?;
        self.loaded = true;
    }
    // render using self.data
}
```

#### Navigation Flow
```
User presses Tab → App::handle_global_key() → sidebar.next_item()
User presses Enter → App::navigate_to(new_screen) → screen.on_activate()
Main loop → ui::render() → current_screen.render()
```

---

## 🚀 How to Run

### Basic TUI
```bash
cargo run -- tui
```

### Keybindings (Global)
- `q` - Quit TUI
- `m` - Toggle sidebar menu
- `Tab` - Navigate menu items
- `Esc` - Go back to previous screen
- `Enter` - Select/navigate to highlighted menu item

### Keybindings (Overview Screen)
- `r` - Refresh data

---

## 🐛 Known Issues / Notes

### Resolved Issues ✅
- ✅ Borrow checker conflict with `app.current_screen.render(app, ...)` - Fixed by splitting App into separate field references
- ✅ Data showing zeros - Fixed by implementing lazy loading in `render()`
- ✅ Config loading from pointer files - Working correctly, loads from `don-flow.yaml`

### Current Limitations
- No async operations yet (all operations block UI)
- No progress bars during long operations (planned for sync screen)
- Warnings about unused enum variants (will be used in future screens)

---

## 📝 Implementation Guide for Next Developer

### To implement Modules Screen:

1. **Read existing module code**:
   ```bash
   # See how modules are currently loaded
   cat src/module.rs
   cat src/commands/module.rs
   ```

2. **Update `/home/don/dcli/src/tui/screens/modules.rs`**:
   ```rust
   // Add state struct
   pub struct ModulesScreenState {
       modules: Vec<ModuleInfo>,
       selected_index: usize,
       loaded: bool,
   }
   
   // Implement load_data() to call ModuleManager::list_modules()
   // Implement render() to show table with ratatui Table widget
   // Implement handle_key() for j/k navigation and Enter to toggle
   ```

3. **Use ratatui widgets**:
   - `Table` widget for module list
   - `TableState` for selection tracking
   - `Row` and `Cell` for table content

4. **Test**:
   ```bash
   cargo run -- tui
   # Navigate to Modules, test enable/disable
   ```

### To implement Packages Screen:

1. **Study existing search code**:
   ```bash
   cat src/commands/search.rs
   ```

2. **Add input handling** for search field
3. **Use `List` widget** for filtered results
4. **Add confirmation dialogs** before installing

### To implement Sync Screen:

1. **Study sync command**:
   ```bash
   cat src/commands/sync.rs
   ```

2. **Create preview by running dry-run**
3. **Capture command output** for progress display
4. **Use `Gauge` widget** for progress bar

---

## 🎯 Success Criteria for Phase 1 MVP

The MVP is complete when:
- [x] User can launch `dcli tui` and see dashboard
- [x] User can navigate menu with keyboard (hjkl or arrows)
- [x] Overview screen shows real system data
- [ ] User can enable/disable modules and changes persist
- [ ] User can search and install packages
- [ ] User can preview and execute sync operations
- [ ] User sees live progress during package installation
- [x] User can quit with 'q' and returns to normal terminal
- [x] All existing dcli commands still work as before

**Current Progress: 60% complete** (Infrastructure + Overview done, 3 screens remaining)

---

## 📚 Resources

### Documentation
- [Ratatui Book](https://ratatui.rs/)
- [Ratatui Examples](https://github.com/ratatui-org/ratatui/tree/main/examples)
- [Crossterm Docs](https://docs.rs/crossterm/)

### Similar Projects for Inspiration
- `lazygit` - Git TUI
- `ytop` - System monitor TUI
- `spotify-tui` - Spotify TUI

### Useful Ratatui Widgets
- `Table` - For module lists
- `List` - For package lists
- `Paragraph` - For text display
- `Gauge` - For progress bars
- `Block` - For borders and titles
- `Layout` - For arranging widgets

---

## 🔄 Recent Changes (Session Log)

### 2026-01-05: Foundation Complete + Overview Screen
1. Set up complete TUI infrastructure with ratatui/crossterm
2. Built all core components (sidebar, statusbar, titlebar, dialogs)
3. Implemented main event loop and navigation
4. Created Overview screen with real data loading:
   - System information (hostname, settings)
   - Quick stats (module counts, package counts)
   - Config directory tree view
5. Fixed borrow checker architecture by splitting App references
6. Successfully tested - TUI launches and displays real config data

**Files Created**: 15 new files in `src/tui/`
**Files Modified**: `Cargo.toml`, `src/main.rs`
**Lines of Code**: ~1500 lines

---

## 💡 Tips for Future Development

1. **Always use the existing dcli logic** - Don't reimplement module/package handling, just call existing functions
2. **Test in small increments** - Build and test each feature before moving to the next
3. **Use cargo check** - Faster than full builds for syntax checking
4. **Handle errors gracefully** - Show error dialogs instead of panicking
5. **Keep state minimal** - Only store what you need, reload from config when possible
6. **Follow the Overview screen pattern** - It's a good template for data loading and rendering

---

**Last Updated**: 2026-01-05
**Current Phase**: Phase 1 MVP (60% complete)
**Next Task**: Implement Modules screen with interactive enable/disable
