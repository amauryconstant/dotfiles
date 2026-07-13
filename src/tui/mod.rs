use anyhow::Result;
use std::time::{Duration, Instant};

mod app;
mod components;
mod events;
mod screens;
pub mod terminal;
mod ui;

use app::App;
use events::{is_quit_key, EventHandler, TuiEvent};
use screens::{DownloadScreenState, Screen, ScreenAction, UploadScreenState};

use crate::config::{load_config, ConfigPaths};

pub fn run(paths: ConfigPaths, mut terminal: terminal::Tui) -> Result<()> {
    // Load config
    let config = load_config(&paths)?;

    // Create app state
    let mut app = App::new(paths, config)?;

    // Create event handler (250ms tick rate)
    let events = EventHandler::new(Duration::from_millis(250));

    // Main event loop
    loop {
        // Render UI
        terminal.draw(|frame| {
            if let Err(e) = ui::render(&mut app, frame) {
                eprintln!("Render error: {}", e);
            }
        })?;

        // Handle events
        match events.next()? {
            TuiEvent::Key(key) => {
                // Check for quit
                if is_quit_key(&key) {
                    break;
                }

                // Handle global keys first
                let handled = app.handle_global_key(key.code)?;

                // If not handled globally, pass to current screen
                if !handled {
                    if let Some(action) = app.current_screen.handle_key(key)? {
                        match action {
                            ScreenAction::Back => app.navigate_back(),
                            ScreenAction::Refresh => app.needs_refresh = true,
                            ScreenAction::None => {}
                        }
                    }
                }
            }
            TuiEvent::Mouse(_) => {
                // Mouse support (optional for MVP)
            }
            TuiEvent::Resize(_, _) => {
                // Terminal resized - ratatui handles this automatically
            }
            TuiEvent::Tick => {
                // Check if status message expired
                if let Some(msg) = &app.status_message {
                    if msg.expires_at < Instant::now() {
                        app.status_message = None;
                    }
                }
            }
        }

        // Check if we should quit
        if app.should_quit {
            break;
        }
    }

    Ok(())
}

/// Run TUI starting directly at the upload screen
pub fn run_upload(paths: ConfigPaths) -> Result<()> {
    let mut terminal = terminal::init()?;

    let result = run_upload_inner(paths, &mut terminal);

    terminal::restore()?;
    result
}

fn run_upload_inner(paths: ConfigPaths, terminal: &mut terminal::Tui) -> Result<()> {
    let config = load_config(&paths)?;
    let mut app = App::new(paths, config)?;

    // Start on upload screen with sidebar hidden
    app.current_screen = Screen::Upload(UploadScreenState::default());
    app.current_screen.on_activate(&app.paths, &app.config)?;
    app.sidebar.collapsed = true;
    if let Some(index) = app.sidebar.index_for("Upload Modules") {
        app.sidebar.selected_index = index;
    }

    let events = EventHandler::new(Duration::from_millis(250));

    loop {
        terminal.draw(|frame| {
            if let Err(e) = ui::render(&mut app, frame) {
                eprintln!("Render error: {}", e);
            }
        })?;

        match events.next()? {
            TuiEvent::Key(key) => {
                if is_quit_key(&key) {
                    break;
                }

                // Handle global keys first (m to toggle sidebar, navigation when open)
                let handled = app.handle_global_key(key.code)?;

                // If not handled globally, pass to current screen
                if !handled {
                    if let Some(action) = app.current_screen.handle_key(key)? {
                        match action {
                            ScreenAction::Back => break, // Exit on back for direct launch
                            ScreenAction::Refresh => app.needs_refresh = true,
                            ScreenAction::None => {}
                        }
                    }
                }
            }
            TuiEvent::Tick => {
                if let Some(msg) = &app.status_message {
                    if msg.expires_at < Instant::now() {
                        app.status_message = None;
                    }
                }
            }
            _ => {}
        }

        if app.should_quit {
            break;
        }
    }

    Ok(())
}

/// Run TUI starting directly at the download screen
pub fn run_download(paths: ConfigPaths) -> Result<()> {
    let mut terminal = terminal::init()?;

    let result = run_download_inner(paths, &mut terminal);

    terminal::restore()?;
    result
}

fn run_download_inner(paths: ConfigPaths, terminal: &mut terminal::Tui) -> Result<()> {
    let config = load_config(&paths)?;
    let mut app = App::new(paths, config)?;

    // Start on download screen with sidebar hidden
    app.current_screen = Screen::Download(DownloadScreenState::default());
    app.current_screen.on_activate(&app.paths, &app.config)?;
    app.sidebar.collapsed = true;
    if let Some(index) = app.sidebar.index_for("Download Modules") {
        app.sidebar.selected_index = index;
    }

    let events = EventHandler::new(Duration::from_millis(250));

    loop {
        terminal.draw(|frame| {
            if let Err(e) = ui::render(&mut app, frame) {
                eprintln!("Render error: {}", e);
            }
        })?;

        match events.next()? {
            TuiEvent::Key(key) => {
                if is_quit_key(&key) {
                    break;
                }

                // Handle global keys first (m to toggle sidebar, navigation when open)
                let handled = app.handle_global_key(key.code)?;

                // If not handled globally, pass to current screen
                if !handled {
                    if let Some(action) = app.current_screen.handle_key(key)? {
                        match action {
                            ScreenAction::Back => break, // Exit on back for direct launch
                            ScreenAction::Refresh => app.needs_refresh = true,
                            ScreenAction::None => {}
                        }
                    }
                }
            }
            TuiEvent::Tick => {
                if let Some(msg) = &app.status_message {
                    if msg.expires_at < Instant::now() {
                        app.status_message = None;
                    }
                }
            }
            _ => {}
        }

        if app.should_quit {
            break;
        }
    }

    Ok(())
}
