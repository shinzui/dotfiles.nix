# Tmux Setup Documentation

## Overview

This document describes the tmux configuration, including all plugins and keybindings. The prefix key is `Ctrl-a` (shown as `prefix` below).

## Table of Contents

- [Configuration Settings](#configuration-settings)
- [Default Tmux Keybindings](#default-tmux-keybindings)
- [Plugins](#plugins)
- [Custom Keybindings](#custom-keybindings)
- [Plugin Keybindings](#plugin-keybindings)
- [Copy Mode (Vi Keybindings)](#copy-mode-vi-keybindings)
- [Tips](#tips)
- [Quick Reference](#quick-reference)

---

## Configuration Settings

| Setting | Value | Description |
|---------|-------|-------------|
| Prefix Key | `Ctrl-a` | Changed from default `Ctrl-b` |
| Key Mode | vi | Vi-style keybindings in copy mode |
| Terminal | screen-256color | With RGB color support |
| History Limit | 10,000 lines | Scrollback buffer size |
| Clock Format | 24-hour | For `prefix + t` |
| Aggressive Resize | Enabled | Resize windows to smallest client viewing |
| Window Renumbering | Automatic | Gaps in window numbers are filled |
| Detach on Destroy | Off | Keeps tmux running when closing a session |

---

## Default Tmux Keybindings

These are essential built-in tmux shortcuts (not overridden by config).

### Session Management

| Key | Action |
|-----|--------|
| `prefix + d` | Detach from current session |
| `prefix + s` | List and select sessions interactively |
| `prefix + $` | Rename current session |
| `prefix + (` | Switch to previous session |
| `prefix + )` | Switch to next session |
| `prefix + L` | Switch to last (previously used) session |

### Window Management

| Key | Action |
|-----|--------|
| `prefix + c` | Create new window |
| `prefix + n` | Move to next window |
| `prefix + p` | Move to previous window |
| `prefix + l` | Move to last (previously used) window |
| `prefix + 0-9` | Select window by number |
| `prefix + w` | List windows interactively (tree view) |
| `prefix + &` | Kill current window (with confirmation) |
| `prefix + ,` | Rename current window |
| `prefix + .` | Move window to another index |
| `prefix + f` | Find window by name |
| `prefix + '` | Prompt for window index to select |

### Pane Management

| Key | Action |
|-----|--------|
| `prefix + %` | Split pane horizontally (left/right) |
| `prefix + "` | Split pane vertically (top/bottom) |
| `prefix + q` | Show pane numbers; type number to switch |
| `prefix + o` | Cycle to next pane |
| `prefix + ;` | Switch to last active pane |
| `prefix + x` | Kill current pane (with confirmation) |
| `prefix + z` | Toggle pane zoom (fullscreen) |
| `prefix + !` | Break pane into new window |
| `prefix + {` | Swap pane with previous |
| `prefix + }` | Swap pane with next |
| `prefix + Space` | Cycle through pane layouts |
| `prefix + Ctrl-o` | Rotate panes in current window |
| `prefix + Arrow` | Navigate to pane in direction |

### Resize Panes (Default)

| Key | Action |
|-----|--------|
| `prefix + Ctrl-Arrow` | Resize pane by 1 cell |
| `prefix + Alt-Arrow` | Resize pane by 5 cells |

### Miscellaneous

| Key | Action |
|-----|--------|
| `prefix + ?` | List all keybindings |
| `prefix + :` | Enter command mode |
| `prefix + t` | Show clock |
| `prefix + i` | Display window information |
| `prefix + r` | Force redraw of client |
| `prefix + ~` | Show previous tmux messages |

---

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

## Copy Mode (Vi Keybindings)

Since `keyMode = "vi"` is enabled, the following vi-style keybindings are available in copy mode:

### Entering/Exiting Copy Mode

| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `prefix + PgUp` | Enter copy mode and scroll up one page |
| `q` or `Escape` | Exit copy mode |

### Navigation

| Key | Action |
|-----|--------|
| `h` | Move cursor left |
| `j` | Move cursor down |
| `k` | Move cursor up |
| `l` | Move cursor right |
| `w` | Move to next word |
| `b` | Move to previous word |
| `e` | Move to end of word |
| `0` | Move to start of line |
| `$` | Move to end of line |
| `^` | Move to first non-blank character |
| `g` | Go to top of buffer |
| `G` | Go to bottom of buffer |
| `Ctrl-b` | Page up |
| `Ctrl-f` | Page down |
| `Ctrl-u` | Half page up |
| `Ctrl-d` | Half page down |
| `H` | Move to top of visible area |
| `M` | Move to middle of visible area |
| `L` | Move to bottom of visible area |

### Search

| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next search result |
| `N` | Previous search result |

### Selection and Copying

| Key | Action |
|-----|--------|
| `Space` | Start selection |
| `v` | Start selection (alternate) |
| `V` | Select entire line |
| `Ctrl-v` | Toggle rectangular selection |
| `o` | Move to other end of selection |
| `y` | Copy selection (yank) |
| `Enter` | Copy selection and exit copy mode |
| `Escape` | Clear selection |

### Scrolling (without entering copy mode)

| Key | Action |
|-----|--------|
| `prefix + PgUp` | Scroll up |
| `prefix + PgDown` | Scroll down |

## Tips

1. **Quick session switching**: Use `prefix + T` to quickly switch between projects and sessions
2. **Navigate like vim**: Use `Ctrl-h/j/k/l` to move between panes without thinking about vim vs tmux
3. **Extract anything**: Use `prefix + Tab` to extract paths, URLs, or text from terminal output
4. **Search efficiently**: Use `prefix + Ctrl-f` to find file paths in your terminal history
5. **Clipboard integration**: Use `y` in copy mode or `prefix + y` to copy to system clipboard
6. **List all bindings**: Use `prefix + ?` to see all available keybindings
7. **Command mode**: Use `prefix + :` to run tmux commands directly

---

## Quick Reference

Most frequently used shortcuts at a glance:

| Category | Key | Action |
|----------|-----|--------|
| **Sessions** | `prefix + T` | Sesh session manager (custom) |
| | `prefix + d` | Detach |
| | `prefix + s` | List sessions |
| **Windows** | `prefix + c` | New window |
| | `prefix + n/p` | Next/previous window |
| | `prefix + 0-9` | Go to window |
| | `prefix + w` | Window list |
| **Panes** | `Ctrl-h/j/k/l` | Navigate panes (vim-style) |
| | `prefix + \|` | Split horizontal |
| | `prefix + -` | Split vertical |
| | `prefix + z` | Zoom pane |
| | `prefix + x` | Kill pane |
| **Copy** | `prefix + [` | Enter copy mode |
| | `Space` | Start selection |
| | `y` | Yank selection |
| | `prefix + ]` | Paste buffer |
| **Plugins** | `prefix + F` | tmux-fzf menu |
| | `prefix + Tab` | Extrakto (extract text) |
| | `prefix + /` | Copycat regex search |
