//! Download screen for browsing and downloading community modules.

use anyhow::Result;
use crossterm::event::{KeyCode, KeyEvent};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Tabs, Wrap},
    Frame,
};

use crate::config::{Config, ConfigPaths};
use crate::sharing::git::{self, RemoteModuleInfo};
use crate::tui::screens::{ScreenAction, ScreenTrait};

/// Standard categories for filtering
const CATEGORIES: &[&str] = &[
    "all",
    "window-managers",
    "desktop-environments",
    "development",
    "gaming",
    "media",
    "productivity",
    "system",
    "networking",
    "tools",
    "packages",
    "other",
];

/// Current phase of the download process
#[derive(Clone, PartialEq)]
enum DownloadPhase {
    Disclaimer,
    Loading,
    Browse,
    Confirming,
    Downloading,
    PromptEnable,
    Complete,
    Error(String),
}

/// State for the download screen
#[derive(Clone)]
pub struct DownloadScreenState {
    /// All remote modules
    all_modules: Vec<RemoteModuleInfo>,
    /// Filtered modules (by current category)
    filtered_modules: Vec<RemoteModuleInfo>,
    /// Current category filter index
    category_index: usize,
    /// Selected module index
    selected: usize,
    /// List state
    list_state: ListState,
    /// Current phase
    phase: DownloadPhase,
    /// Has data been loaded?
    loaded: bool,
    /// Downloaded module path (for prompt enable)
    downloaded_path: Option<std::path::PathBuf>,
}

impl Default for DownloadScreenState {
    fn default() -> Self {
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        Self {
            all_modules: Vec::new(),
            filtered_modules: Vec::new(),
            category_index: 0, // "all"
            selected: 0,
            list_state,
            phase: DownloadPhase::Disclaimer,
            loaded: false,
            downloaded_path: None,
        }
    }
}

impl ScreenTrait for DownloadScreenState {
    fn on_activate(&mut self, _paths: &ConfigPaths, _config: &Config) -> Result<()> {
        // Will load on first render after disclaimer is accepted
        Ok(())
    }

    fn handle_key(&mut self, key: KeyEvent) -> Result<Option<ScreenAction>> {
        match &self.phase {
            DownloadPhase::Disclaimer => match key.code {
                KeyCode::Char('y') | KeyCode::Char('Y') | KeyCode::Enter => {
                    self.phase = DownloadPhase::Loading;
                }
                KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
                    // User declined - go back
                    return Ok(Some(ScreenAction::Back));
                }
                _ => {}
            },
            DownloadPhase::Browse => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    if self.selected > 0 {
                        self.selected -= 1;
                        self.list_state.select(Some(self.selected));
                    }
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    if self.filtered_modules.len() > 0
                        && self.selected < self.filtered_modules.len() - 1
                    {
                        self.selected += 1;
                        self.list_state.select(Some(self.selected));
                    }
                }
                KeyCode::Left | KeyCode::Char('h') => {
                    if self.category_index > 0 {
                        self.category_index -= 1;
                        self.apply_filter();
                    }
                }
                KeyCode::Right | KeyCode::Char('l') => {
                    if self.category_index < CATEGORIES.len() - 1 {
                        self.category_index += 1;
                        self.apply_filter();
                    }
                }
                KeyCode::Enter => {
                    if !self.filtered_modules.is_empty() {
                        self.phase = DownloadPhase::Confirming;
                    }
                }
                KeyCode::Char('r') => {
                    // Refresh
                    self.loaded = false;
                    self.phase = DownloadPhase::Loading;
                }
                KeyCode::Esc => {
                    return Ok(Some(ScreenAction::Back));
                }
                _ => {}
            },
            DownloadPhase::Confirming => match key.code {
                KeyCode::Char('y') | KeyCode::Char('Y') => {
                    self.phase = DownloadPhase::Downloading;
                }
                KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
                    self.phase = DownloadPhase::Browse;
                }
                _ => {}
            },
            DownloadPhase::PromptEnable => match key.code {
                KeyCode::Char('y') | KeyCode::Char('Y') => {
                    // TODO: Actually enable the module
                    self.phase = DownloadPhase::Complete;
                }
                KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Enter => {
                    self.phase = DownloadPhase::Complete;
                }
                _ => {}
            },
            DownloadPhase::Complete | DownloadPhase::Error(_) => {
                if key.code == KeyCode::Enter || key.code == KeyCode::Esc {
                    self.phase = DownloadPhase::Browse;
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
        // Handle loading phase
        if self.phase == DownloadPhase::Loading && !self.loaded {
            self.load_remote_modules();
        }

        // Handle downloading phase
        if self.phase == DownloadPhase::Downloading {
            self.perform_download(paths);
        }

        // Show disclaimer overlay if needed
        if self.phase == DownloadPhase::Disclaimer {
            self.render_disclaimer(frame, area);
            return Ok(());
        }

        // Main layout
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(3), Constraint::Min(0)])
            .split(area);

        self.render_category_tabs(frame, chunks[0]);

        let content_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
            .split(chunks[1]);

        self.render_module_list(frame, content_chunks[0]);
        self.render_details(frame, content_chunks[1]);

        Ok(())
    }
}

impl DownloadScreenState {
    fn load_remote_modules(&mut self) {
        match git::sync_repo(false) {
            Ok(repo_dir) => match git::list_remote_modules(&repo_dir) {
                Ok(modules) => {
                    self.all_modules = modules;
                    self.apply_filter();
                    self.phase = DownloadPhase::Browse;
                    self.loaded = true;
                }
                Err(e) => {
                    self.phase = DownloadPhase::Error(format!("Failed to list modules:\n{}", e));
                }
            },
            Err(e) => {
                self.phase = DownloadPhase::Error(format!("Failed to sync repository:\n{}", e));
            }
        }
    }

    fn apply_filter(&mut self) {
        let category = CATEGORIES[self.category_index];

        self.filtered_modules = if category == "all" {
            self.all_modules.clone()
        } else {
            self.all_modules
                .iter()
                .filter(|m| m.category == category)
                .cloned()
                .collect()
        };

        self.selected = 0;
        self.list_state.select(Some(0));
    }

    fn perform_download(&mut self, paths: &ConfigPaths) {
        if self.filtered_modules.is_empty() {
            self.phase = DownloadPhase::Browse;
            return;
        }

        let module = &self.filtered_modules[self.selected];

        match git::download_module(module, &paths.modules_dir()) {
            Ok(path) => {
                self.downloaded_path = Some(path);
                self.phase = DownloadPhase::PromptEnable;
            }
            Err(e) => {
                self.phase = DownloadPhase::Error(format!("Failed to download:\n{}", e));
            }
        }
    }

    fn render_disclaimer(&self, frame: &mut Frame, area: Rect) {
        let text = vec![
            Line::from(""),
            Line::from(Span::styled(
                "Community Modules Disclaimer",
                Style::default()
                    .fg(Color::Yellow)
                    .add_modifier(Modifier::BOLD),
            )),
            Line::from(""),
            Line::from("You are about to browse community-contributed modules."),
            Line::from(""),
            Line::from(Span::styled(
                "WARNING:",
                Style::default().fg(Color::Red).add_modifier(Modifier::BOLD),
            )),
            Line::from(""),
            Line::from("  - Modules are NOT reviewed by dcli maintainers"),
            Line::from("  - Modules may contain scripts that run on your system"),
            Line::from("  - Always review module contents before enabling"),
            Line::from("  - Use at your own risk"),
            Line::from(""),
            Line::from("By continuing, you acknowledge these risks."),
            Line::from(""),
            Line::from(Span::styled(
                "[Y/Enter] I understand, continue  [N/Esc] Go back",
                Style::default().fg(Color::DarkGray),
            )),
        ];

        let paragraph = Paragraph::new(text)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Yellow))
                    .title(" Disclaimer "),
            )
            .wrap(Wrap { trim: true });

        // Center the disclaimer
        let centered = centered_rect(60, 60, area);
        frame.render_widget(Clear, centered);
        frame.render_widget(paragraph, centered);
    }

    fn render_category_tabs(&self, frame: &mut Frame, area: Rect) {
        let titles: Vec<Line> = CATEGORIES
            .iter()
            .map(|c| Line::from(Span::styled(*c, Style::default().fg(Color::White))))
            .collect();

        let tabs = Tabs::new(titles)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Blue))
                    .title(" Categories [</>] "),
            )
            .select(self.category_index)
            .highlight_style(
                Style::default()
                    .fg(Color::Cyan)
                    .add_modifier(Modifier::BOLD),
            );

        frame.render_widget(tabs, area);
    }

    fn render_module_list(&mut self, frame: &mut Frame, area: Rect) {
        let items: Vec<ListItem> = self
            .filtered_modules
            .iter()
            .map(|m| {
                let author = m.author.as_deref().unwrap_or("unknown");
                ListItem::new(Line::from(vec![
                    Span::styled(&m.name, Style::default().fg(Color::Cyan)),
                    Span::raw(" by "),
                    Span::styled(author, Style::default().fg(Color::DarkGray)),
                ]))
            })
            .collect();

        let title = format!(" Modules ({}) ", self.filtered_modules.len());
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
            DownloadPhase::Loading => {
                vec![
                    Line::from(Span::styled("Loading...", Style::default().fg(Color::Blue))),
                    Line::from(""),
                    Line::from("Fetching module list from repository..."),
                ]
            }
            DownloadPhase::Browse => {
                if self.filtered_modules.is_empty() {
                    vec![
                        Line::from(Span::styled(
                            "No modules in this category",
                            Style::default().fg(Color::Yellow),
                        )),
                        Line::from(""),
                        Line::from("Try selecting a different category,"),
                        Line::from("or press [r] to refresh."),
                    ]
                } else {
                    let m = &self.filtered_modules[self.selected];
                    let mut lines = vec![
                        Line::from(Span::styled(
                            &m.name,
                            Style::default()
                                .fg(Color::Cyan)
                                .add_modifier(Modifier::BOLD),
                        )),
                        Line::from(""),
                        Line::from(vec![
                            Span::raw("Author:   "),
                            Span::styled(
                                m.author.as_deref().unwrap_or("unknown"),
                                Style::default().fg(Color::Green),
                            ),
                        ]),
                        Line::from(vec![
                            Span::raw("Version:  "),
                            Span::styled(
                                m.version.as_deref().unwrap_or("?"),
                                Style::default().fg(Color::Green),
                            ),
                        ]),
                        Line::from(vec![
                            Span::raw("Category: "),
                            Span::styled(&m.category, Style::default().fg(Color::Yellow)),
                        ]),
                        Line::from(""),
                        Line::from(&m.description[..]),
                    ];

                    if !m.tags.is_empty() {
                        lines.push(Line::from(""));
                        lines.push(Line::from(vec![
                            Span::raw("Tags: "),
                            Span::styled(m.tags.join(", "), Style::default().fg(Color::DarkGray)),
                        ]));
                    }

                    lines.push(Line::from(""));
                    lines.push(Line::from(Span::styled(
                        "[Enter] Download  [r] Refresh  [Esc] Back",
                        Style::default().fg(Color::DarkGray),
                    )));

                    lines
                }
            }
            DownloadPhase::Confirming => {
                let m = &self.filtered_modules[self.selected];
                vec![
                    Line::from(Span::styled(
                        "Confirm Download",
                        Style::default()
                            .fg(Color::Yellow)
                            .add_modifier(Modifier::BOLD),
                    )),
                    Line::from(""),
                    Line::from(format!("Download '{}' to your modules?", m.name)),
                    Line::from(""),
                    Line::from(format!(
                        "From: {}",
                        m.author.as_deref().unwrap_or("unknown")
                    )),
                    Line::from(""),
                    Line::from(Span::styled(
                        "[Y] Yes  [N] No",
                        Style::default().fg(Color::DarkGray),
                    )),
                ]
            }
            DownloadPhase::Downloading => {
                vec![
                    Line::from(Span::styled(
                        "Downloading...",
                        Style::default().fg(Color::Blue),
                    )),
                    Line::from(""),
                    Line::from("Please wait..."),
                ]
            }
            DownloadPhase::PromptEnable => {
                let m = &self.filtered_modules[self.selected];
                vec![
                    Line::from(Span::styled(
                        "Download Complete!",
                        Style::default()
                            .fg(Color::Green)
                            .add_modifier(Modifier::BOLD),
                    )),
                    Line::from(""),
                    Line::from(format!("Module '{}' downloaded.", m.name)),
                    Line::from(""),
                    Line::from("Enable this module now?"),
                    Line::from(""),
                    Line::from(Span::styled(
                        "[Y] Yes  [N] No",
                        Style::default().fg(Color::DarkGray),
                    )),
                ]
            }
            DownloadPhase::Complete => {
                let m = &self.filtered_modules[self.selected];
                vec![
                    Line::from(Span::styled(
                        "Done!",
                        Style::default()
                            .fg(Color::Green)
                            .add_modifier(Modifier::BOLD),
                    )),
                    Line::from(""),
                    Line::from(format!("Module '{}' is ready.", m.name)),
                    Line::from(""),
                    Line::from("Run 'dcli sync' to install packages."),
                    Line::from(""),
                    Line::from(Span::styled(
                        "[Enter] Continue",
                        Style::default().fg(Color::DarkGray),
                    )),
                ]
            }
            DownloadPhase::Error(msg) => {
                vec![
                    Line::from(Span::styled(
                        "Error",
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
            _ => vec![],
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

/// Helper to create a centered rectangle
fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}
