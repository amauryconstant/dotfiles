//! Upload screen for sharing modules to the community repository.

use anyhow::Result;
use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
    Frame,
};

use crate::config::{load_module, Config, ConfigPaths};
use crate::module::ModuleManager;
use crate::sharing::{git, SharingMetadata};
use crate::tui::screens::{ScreenAction, ScreenTrait};

/// Information about a module that can be uploaded
#[derive(Clone)]
struct UploadableModule {
    name: String,
    path: std::path::PathBuf,
    metadata: SharingMetadata,
    is_directory: bool,
    is_lua: bool,
}

/// Current phase of the upload process
#[derive(Clone, PartialEq)]
enum UploadPhase {
    SelectModule,
    Confirming,
    Uploading,
    Complete,
    Error(String),
}

/// State for the upload screen
#[derive(Clone)]
pub struct UploadScreenState {
    /// List of uploadable modules (have valid metadata)
    modules: Vec<UploadableModule>,
    /// Currently selected index
    selected: usize,
    /// List state for ratatui
    list_state: ListState,
    /// Current phase of upload
    phase: UploadPhase,
    /// Has data been loaded?
    loaded: bool,
}

impl Default for UploadScreenState {
    fn default() -> Self {
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        Self {
            modules: Vec::new(),
            selected: 0,
            list_state,
            phase: UploadPhase::SelectModule,
            loaded: false,
        }
    }
}

impl ScreenTrait for UploadScreenState {
    fn on_activate(&mut self, paths: &ConfigPaths, _config: &Config) -> Result<()> {
        if !self.loaded {
            self.load_uploadable_modules(paths)?;
            self.loaded = true;
        }
        Ok(())
    }

    fn handle_key(&mut self, key: KeyEvent) -> Result<Option<ScreenAction>> {
        match &self.phase {
            UploadPhase::SelectModule => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    if self.selected > 0 {
                        self.selected -= 1;
                        self.list_state.select(Some(self.selected));
                    }
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    if self.selected < self.modules.len().saturating_sub(1) {
                        self.selected += 1;
                        self.list_state.select(Some(self.selected));
                    }
                }
                KeyCode::Enter => {
                    if !self.modules.is_empty() {
                        self.phase = UploadPhase::Confirming;
                    }
                }
                KeyCode::Esc => {
                    return Ok(Some(ScreenAction::Back));
                }
                _ => {}
            },
            UploadPhase::Confirming => match key.code {
                KeyCode::Char('y') | KeyCode::Char('Y') => {
                    self.phase = UploadPhase::Uploading;
                }
                KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
                    self.phase = UploadPhase::SelectModule;
                }
                _ => {}
            },
            UploadPhase::Complete | UploadPhase::Error(_) => {
                if key.code == KeyCode::Enter || key.code == KeyCode::Esc {
                    self.phase = UploadPhase::SelectModule;
                }
            }
            _ => {}
        }
        Ok(None)
    }

    fn render(
        &mut self,
        paths: &ConfigPaths,
        _config: &Config,
        frame: &mut Frame,
        area: Rect,
    ) -> Result<()> {
        // Handle uploading phase (do the actual upload)
        if self.phase == UploadPhase::Uploading {
            self.perform_upload(paths);
        }

        // Main layout: module list on left, details on right
        let chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
            .split(area);

        self.render_module_list(frame, chunks[0]);
        self.render_details(frame, chunks[1]);

        Ok(())
    }
}

impl UploadScreenState {
    fn load_uploadable_modules(&mut self, paths: &ConfigPaths) -> Result<()> {
        let module_manager = ModuleManager::new(paths.clone());
        let all_modules = module_manager.list_modules()?;

        self.modules.clear();

        for module_info in all_modules {
            let modules_dir = paths.modules_dir();

            // Determine the actual path
            let module_path = if module_info.is_directory {
                modules_dir.join(&module_info.name)
            } else if module_info.is_lua {
                modules_dir.join(format!("{}.lua", &module_info.name))
            } else {
                // Skip legacy single-file YAML modules
                continue;
            };

            // Load and check metadata
            if let Ok(module) = load_module(&module_path) {
                if let Some(metadata) = module.sharing_metadata() {
                    if metadata.validate().is_ok() {
                        self.modules.push(UploadableModule {
                            name: module_info.name,
                            path: module_path,
                            metadata,
                            is_directory: module_info.is_directory,
                            is_lua: module_info.is_lua,
                        });
                    }
                }
            }
        }

        // Sort by name
        self.modules.sort_by(|a, b| a.name.cmp(&b.name));

        Ok(())
    }

    fn perform_upload(&mut self, _paths: &ConfigPaths) {
        if let Err(e) = git::check_git_credentials() {
            self.phase = UploadPhase::Error(format!("Credential check failed: {}", e));
            return;
        }

        let module = &self.modules[self.selected];

        // Sync repository
        let use_ssh = git::has_ssh_key();
        let repo_dir = match git::sync_repo(use_ssh) {
            Ok(dir) => dir,
            Err(e) => {
                self.phase = UploadPhase::Error(format!("Failed to sync repo:\n{}", e));
                return;
            }
        };

        // Stage module
        let category = module.metadata.effective_category();
        if let Err(e) =
            git::stage_module_for_upload(&module.path, &module.name, category, &repo_dir)
        {
            self.phase = UploadPhase::Error(format!("Failed to stage module:\n{}", e));
            return;
        }

        // Commit and push
        let message = format!(
            "Add {} by {} (v{})",
            module.name, module.metadata.author, module.metadata.version
        );

        if let Err(e) = git::commit_and_push(&repo_dir, &message, use_ssh) {
            self.phase = UploadPhase::Error(format!("Failed to push:\n{}", e));
            return;
        }

        self.phase = UploadPhase::Complete;
    }

    fn render_module_list(&mut self, frame: &mut Frame, area: Rect) {
        let items: Vec<ListItem> = self
            .modules
            .iter()
            .map(|m| {
                let format_type = if m.is_directory {
                    "[dir]"
                } else if m.is_lua {
                    "[lua]"
                } else {
                    "[yaml]"
                };
                ListItem::new(Line::from(vec![
                    Span::styled(&m.name, Style::default().fg(Color::Cyan)),
                    Span::raw(" "),
                    Span::styled(format_type, Style::default().fg(Color::DarkGray)),
                ]))
            })
            .collect();

        let title = format!(" Uploadable Modules ({}) ", self.modules.len());
        let list = List::new(items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Blue))
                    .title(title),
            )
            .highlight_style(
                Style::default()
                    .bg(Color::DarkGray)
                    .add_modifier(Modifier::BOLD),
            )
            .highlight_symbol("> ");

        frame.render_stateful_widget(list, area, &mut self.list_state);
    }

    fn render_details(&self, frame: &mut Frame, area: Rect) {
        let content = match &self.phase {
            UploadPhase::SelectModule => {
                if self.modules.is_empty() {
                    vec![
                        Line::from(""),
                        Line::from(Span::styled(
                            "No uploadable modules found",
                            Style::default().fg(Color::Yellow),
                        )),
                        Line::from(""),
                        Line::from("Modules need the following to be uploadable:"),
                        Line::from(""),
                        Line::from("  - Directory format (module.yaml/module.lua/module.nix)"),
                        Line::from("  - author field (your username)"),
                        Line::from("  - version field (semver: X.Y.Z)"),
                        Line::from("  - description field"),
                        Line::from(""),
                        Line::from("Example module.yaml:"),
                        Line::from(""),
                        Line::from(Span::styled(
                            "  author: your-username",
                            Style::default().fg(Color::Green),
                        )),
                        Line::from(Span::styled(
                            "  version: \"1.0.0\"",
                            Style::default().fg(Color::Green),
                        )),
                        Line::from(Span::styled(
                            "  description: My module",
                            Style::default().fg(Color::Green),
                        )),
                    ]
                } else {
                    let m = &self.modules[self.selected];
                    vec![
                        Line::from(Span::styled(
                            &m.name,
                            Style::default()
                                .fg(Color::Cyan)
                                .add_modifier(Modifier::BOLD),
                        )),
                        Line::from(""),
                        Line::from(vec![
                            Span::raw("Author:   "),
                            Span::styled(&m.metadata.author, Style::default().fg(Color::Green)),
                        ]),
                        Line::from(vec![
                            Span::raw("Version:  "),
                            Span::styled(&m.metadata.version, Style::default().fg(Color::Green)),
                        ]),
                        Line::from(vec![
                            Span::raw("Category: "),
                            Span::styled(
                                m.metadata.effective_category(),
                                Style::default().fg(Color::Yellow),
                            ),
                        ]),
                        Line::from(""),
                        Line::from(&m.metadata.description[..]),
                        Line::from(""),
                        if !m.metadata.tags.is_empty() {
                            Line::from(vec![
                                Span::raw("Tags: "),
                                Span::styled(
                                    m.metadata.tags.join(", "),
                                    Style::default().fg(Color::DarkGray),
                                ),
                            ])
                        } else {
                            Line::from("")
                        },
                        Line::from(""),
                        Line::from(Span::styled(
                            "[Enter] Upload  [Esc] Back",
                            Style::default().fg(Color::DarkGray),
                        )),
                    ]
                }
            }
            UploadPhase::Confirming => {
                let m = &self.modules[self.selected];
                vec![
                    Line::from(Span::styled(
                        "Confirm Upload",
                        Style::default()
                            .fg(Color::Yellow)
                            .add_modifier(Modifier::BOLD),
                    )),
                    Line::from(""),
                    Line::from(format!("Upload '{}' to dcli-modules?", m.name)),
                    Line::from(""),
                    Line::from(format!("Category: {}", m.metadata.effective_category())),
                    Line::from(format!("Version:  {}", m.metadata.version)),
                    Line::from(format!("Author:   {}", m.metadata.author)),
                    Line::from(""),
                    Line::from(Span::styled(
                        "[Y] Yes  [N] No",
                        Style::default().fg(Color::DarkGray),
                    )),
                ]
            }
            UploadPhase::Uploading => {
                vec![
                    Line::from(Span::styled(
                        "Uploading...",
                        Style::default().fg(Color::Blue),
                    )),
                    Line::from(""),
                    Line::from("Please wait..."),
                ]
            }
            UploadPhase::Complete => {
                let m = &self.modules[self.selected];
                vec![
                    Line::from(Span::styled(
                        "Upload Complete!",
                        Style::default()
                            .fg(Color::Green)
                            .add_modifier(Modifier::BOLD),
                    )),
                    Line::from(""),
                    Line::from(format!("Module '{}' uploaded successfully.", m.name)),
                    Line::from(""),
                    Line::from("It is now available in the community repository."),
                    Line::from(""),
                    Line::from(Span::styled(
                        "[Enter] Continue",
                        Style::default().fg(Color::DarkGray),
                    )),
                ]
            }
            UploadPhase::Error(msg) => {
                vec![
                    Line::from(Span::styled(
                        "Upload Failed",
                        Style::default().fg(Color::Red).add_modifier(Modifier::BOLD),
                    )),
                    Line::from(""),
                    Line::from(msg.as_str()),
                    Line::from(""),
                    Line::from(Span::styled(
                        "[Enter] Back",
                        Style::default().fg(Color::DarkGray),
                    )),
                ]
            }
        };

        let paragraph = Paragraph::new(content)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Blue))
                    .title(" Details "),
            )
            .wrap(Wrap { trim: true });

        frame.render_widget(paragraph, area);
    }
}
