# Tmux Setup Documentation

## Overview

This document describes the tmux configuration, including all plugins and keybindings.

## Configuration Settings

- **Prefix Key**: `Ctrl-a` (instead of default `Ctrl-b`)
- **Key Mode**: vi
- **Terminal**: screen-256color with RGB support
- **History Limit**: 10,000 lines
- **Clock Format**: 24-hour
- **Aggressive Resize**: Enabled
- **Window Renumbering**: Automatic
- **Detach on Destroy**: Off (keeps tmux running when closing a session)

## Plugins

The following plugins are installed and configured:

1. **sensible** - Basic tmux settings and sensible defaults
2. **vim-tmux-navigator** - Seamless navigation between tmux panes and vim splits
3. **open** - Quick opening of highlighted files or URLs
4. **copycat** - Enhanced search functionality
5. **yank** - Copy to system clipboard
6. **pain-control** - Pane management utilities
7. **sessionist** - Session manipulation utilities
8. **nord** - Nord color theme
9. **tmux-fzf** - FZF integration for tmux management
10. **extrakto** - Extract text without mouse

## Custom Keybindings

| Key | Action | Description |
|-----|--------|-------------|
| `prefix + T` | Session switcher | Opens sesh/fzf session manager with multiple modes |

### Sesh Session Manager (prefix + T)

The session manager provides an interactive fuzzy finder with the following modes:

| Key Combo | Mode | Description |
|-----------|------|-------------|
| `Ctrl-a` | All | Show all sessions |
| `Ctrl-t` | Tmux | Show only tmux sessions |
| `Ctrl-g` | Configs | Show config directories |
| `Ctrl-x` | Zoxide | Show zoxide directories |
| `Ctrl-f` | Find | Find directories (depth 2) |
| `Ctrl-d` | Delete | Kill selected session |
| `Tab` | Down | Move selection down |
| `Shift-Tab` | Up | Move selection up |

## Built-in Tmux Keybindings

Essential built-in tmux shortcuts:

| Key | Action | Description |
|-----|--------|-------------|
| `prefix + q` | Show pane numbers | Displays pane numbers; type a number to switch to that pane |
| `prefix + o` | Next pane | Cycle to next pane |
| `prefix + ;` | Last pane | Switch to last active pane |
| `prefix + x` | Kill pane | Close current pane (with confirmation) |
| `prefix + z` | Zoom pane | Toggle full-screen for current pane |

## Plugin Keybindings

### tmux-sensible

Provides sensible default settings (no additional keybindings).

### vim-tmux-navigator

Navigate seamlessly between vim splits and tmux panes:

| Key | Action |
|-----|--------|
| `Ctrl-h` | Move to left pane/split |
| `Ctrl-j` | Move to pane/split below |
| `Ctrl-k` | Move to pane/split above |
| `Ctrl-l` | Move to right pane/split |
| `Ctrl-\` | Move to previous pane/split |

### tmux-open

Quick file/URL opening from selection:

| Key | Action |
|-----|--------|
| `prefix + o` | Open highlighted selection |
| `prefix + Ctrl-o` | Open highlighted selection with $EDITOR |

### tmux-copycat

Enhanced search with predefined patterns:

| Key | Search For |
|-----|-----------|
| `prefix + /` | Regex search |
| `prefix + Ctrl-f` | File paths |
| `prefix + Ctrl-g` | Git status files |
| `prefix + Alt-h` | SHA-1 hashes |
| `prefix + Ctrl-u` | URLs |
| `prefix + Ctrl-d` | Numbers |
| `prefix + Alt-i` | IP addresses |

After search:
- `n` - Jump to next match
- `N` - Jump to previous match

### tmux-yank

Copy to system clipboard:

| Key | Action |
|-----|--------|
| `prefix + y` | Copy current command line to clipboard |
| `prefix + Y` | Copy current pane's working directory |

**In copy mode (vi):**

| Key | Action |
|-----|--------|
| `y` | Copy selection to clipboard |
| `Y` | Copy selection and paste to command line |

### tmux-pain-control

Enhanced pane management:

**Navigation:**
| Key | Action |
|-----|--------|
| `prefix + h` | Select pane on the left |
| `prefix + j` | Select pane below |
| `prefix + k` | Select pane above |
| `prefix + l` | Select pane on the right |

**Resizing:**
| Key | Action |
|-----|--------|
| `prefix + H` | Resize pane left |
| `prefix + J` | Resize pane down |
| `prefix + K` | Resize pane up |
| `prefix + L` | Resize pane right |

**Splitting:**
| Key | Action |
|-----|--------|
| `prefix + \|` | Split pane horizontally |
| `prefix + -` | Split pane vertically |
| `prefix + \` | Split full width horizontally |
| `prefix + _` | Split full height vertically |

**Swapping:**
| Key | Action |
|-----|--------|
| `prefix + <` | Swap pane with previous |
| `prefix + >` | Swap pane with next |

### tmux-sessionist

Session management utilities:

| Key | Action |
|-----|--------|
| `prefix + g` | Prompt for session name and switch |
| `prefix + C` | Create new session |
| `prefix + X` | Kill current session without detaching |
| `prefix + S` | Switch to last session |
| `prefix + @` | Promote current pane to new session |

### tmux-fzf

FZF-powered tmux management:

| Key | Action |
|-----|--------|
| `prefix + F` | Launch tmux-fzf menu |

From the menu, you can manage:
- Sessions
- Windows
- Panes
- Commands
- Keybindings
- Clipboard history

### tmux-extrakto

Extract text without using mouse:

| Key | Action |
|-----|--------|
| `prefix + Tab` | Open extrakto (extract text/paths/URLs) |

In extrakto mode:
- Select with arrow keys or fuzzy search
- `Enter` - Copy to clipboard
- `Ctrl-o` - Open with default application
- `Tab` - Toggle filter mode

## Additional Vi Mode Keybindings

Since `keyMode = "vi"` is enabled, the following vi-style keybindings are available in copy mode:

| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `Space` | Start selection |
| `v` | Toggle rectangular selection |
| `y` | Copy selection |
| `h,j,k,l` | Navigation |
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next search result |
| `N` | Previous search result |

## Tips

1. **Quick session switching**: Use `prefix + T` to quickly switch between projects and sessions
2. **Navigate like vim**: Use `Ctrl-h/j/k/l` to move between panes without thinking about vim vs tmux
3. **Extract anything**: Use `prefix + Tab` to extract paths, URLs, or text from terminal output
4. **Search efficiently**: Use `prefix + Ctrl-f` to find file paths in your terminal history
5. **Clipboard integration**: Use `y` in copy mode or `prefix + y` to copy to system clipboard
