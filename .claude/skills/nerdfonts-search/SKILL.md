---
name: nerdfonts-search
description: Search Nerd Fonts glyph database by keyword or concept to find appropriate icons. Use when users need to find glyphs/icons for UI elements, terminal output, status indicators, or any visual representation. Triggers include requests like "find an icon for battery", "what glyph for folder", "search for arrow icons", or any task requiring Nerd Fonts symbols.
---

# Nerd Fonts Glyph Search

Search the Nerd Fonts glyph database (v3.4.0) by keyword or concept to find appropriate icons and symbols.

## Quick Start

Use the search script to find glyphs by keyword:

```bash
python scripts/search_glyphs.py <keyword> [--limit N]
```

**Examples:**

```bash
# Find battery glyphs
python scripts/search_glyphs.py battery

# Find folder icons, limit to 5 results
python scripts/search_glyphs.py folder --limit 5

# Find arrow glyphs
python scripts/search_glyphs.py arrow
```

**Output format:**
```
  󰁹  md-battery
     Code: U+F0079
```

Each result shows:
- The actual glyph character (requires Nerd Font)
- The glyph name
- Unicode codepoint

## Search Strategy

The script uses fuzzy matching with scoring:

1. **Exact match bonus**: Keywords matching the readable part of the glyph name score highest
2. **Partial match**: Keywords appearing anywhere in the name
3. **Fuzzy similarity**: Similar words are matched

**Glyph name format**: `prefix-name` (e.g., `cod-battery`, `fa-folder`, `md-chevron-right`)

**Common prefixes:**
- `cod-` - Codicons (VSCode)
- `fa-` - Font Awesome
- `md-` - Material Design
- `oct-` - Octicons (GitHub)
- `dev-` - Devicons
- `weather-` - Weather Icons
- `seti-` - Seti UI

## Workflow

When a user asks to find glyphs:

1. **Identify key concepts** from the request
   - "battery level indicator" → search "battery"
   - "navigation arrows" → search "arrow"
   - "file system icons" → search "folder" or "file"

2. **Run search** with the keyword
   ```bash
   python scripts/search_glyphs.py <keyword>
   ```

3. **Review results** and present relevant options to user
   - Show the character, name, and code
   - Explain different variants if available (e.g., battery levels, arrow directions)

4. **Suggest usage** based on context
   - Copy/paste the character directly
   - Use the Unicode code in configs
   - Note that Nerd Fonts must be installed to display correctly

## Tips

- **Broad searches**: Use general terms ("battery" not "battery-half")
- **Multiple searches**: Try related keywords if first search doesn't match
- **Limit results**: Use `--limit` to focus on top matches
- **Icon sets**: Different prefixes offer different design styles

## Updating the Glyph Database

Keep the glyph database current with the latest Nerd Fonts release:

```bash
python scripts/update_glyphs.py
```

**Features:**
- Downloads latest glyphnames.json from [Nerd Fonts GitHub](https://github.com/ryanoasis/nerd-fonts)
- Checks current version and compares with remote
- Creates timestamped backup before updating
- Shows version, release date, and glyph count

**Force reinstall:**
```bash
python scripts/update_glyphs.py --force
```

The script downloads from:
```
https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json
```

## Resources

- `scripts/search_glyphs.py` - Search script with fuzzy matching
- `scripts/update_glyphs.py` - Update script to download latest glyphs
- `references/glyphnames.json` - Full Nerd Fonts database (10k+ glyphs, v3.4.0)
