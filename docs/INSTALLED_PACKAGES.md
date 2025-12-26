# Installed Packages Documentation

This document provides a comprehensive overview of all packages installed through Nix and Homebrew in this dotfiles configuration.

## Table of Contents

- [Network & HTTP Tools](#network--http-tools)
- [System & File Management](#system--file-management)
- [Data Processing](#data-processing)
- [Development Tools](#development-tools)
- [Programming Languages & Toolchains](#programming-languages--toolchains)
- [Cloud & Container Tools](#cloud--container-tools)
- [Kubernetes Ecosystem](#kubernetes-ecosystem)
- [Database Tools](#database-tools)
- [AI & Machine Learning](#ai--machine-learning)
- [Terminal & Session Management](#terminal--session-management)
- [Documentation & Media](#documentation--media)
- [Security & Credentials](#security--credentials)
- [Desktop Applications](#desktop-applications)
- [Fonts](#fonts)
- [Nix-Specific Tools](#nix-specific-tools)
- [Additional Utilities](#additional-utilities)
- [Previously Installed](#previously-installed)
- [Temporarily Removed](#temporarily-removed)

---

## Network & HTTP Tools

### Installed via Nix (nixpkgs)

- **[bandwhich](https://github.com/imsnif/bandwhich)** - Terminal bandwidth utilization tool
- **[curl](https://curl.se/)** - Command line tool for transferring data with URLs
- **[trurl](https://github.com/curl/trurl)** - Command line tool for URL parsing and manipulation
- **[hurl](https://hurl.dev/)** - Run and test HTTP requests with plain text
- **[httpstat](https://github.com/reorx/httpstat)** - Curl statistics made simple
- **[lychee](https://github.com/lycheeverse/lychee)** - Fast, async, stream-based link checker
- **[xh](https://github.com/ducaale/xh)** - Friendly and fast tool for sending HTTP requests
- **[dogdns](https://github.com/ogham/dog)** - Command-line DNS client like dig
- **[wget](https://www.gnu.org/software/wget/)** - Network downloader
- **[openapi-tui](https://github.com/zaghaghi/openapi-tui)** - Terminal UI for browsing OpenAPI specifications
- **[oq](https://github.com/tui-rs-revival/oq)** - Terminal-based viewer for OpenAPI specifications
- **[trippy](https://github.com/fujiapple852/trippy)** - Network diagnostic tool combining traceroute and ping
- **[snitch](https://github.com/evilsocket/snitch)** - Inspect network connections made by processes

---

## System & File Management

### Installed via Nix (nixpkgs)

- **[bottom](https://github.com/ClementTsang/bottom)** - Yet another cross-platform graphical process/system monitor
- **[dateutils](http://www.fresse.org/dateutils/)** - Tools for fiddling with dates and times
- **[moreutils](https://joeyh.name/code/moreutils/)** - Collection of Unix tools that nobody thought to write
- **[du-dust](https://github.com/bootandy/dust)** - A more intuitive version of du written in Rust
- **[eza](https://github.com/eza-community/eza)** - Modern, maintained replacement for ls
- **[lstr](https://github.com/acarl005/ls-go)** - Terminal file browser written in Go
- **[fdupes](https://github.com/adrianlopezroche/fdupes)** - Identify and delete duplicate files
- **[fd](https://github.com/sharkdp/fd)** - Simple, fast and user-friendly alternative to find
- **[tree](http://mama.indstate.edu/users/ice/tree/)** - Display directory tree structures
- **[gnused](https://www.gnu.org/software/sed/)** - GNU stream editor
- **[sd](https://github.com/chmln/sd)** - Intuitive find & replace CLI (sed/awk alternative)
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Recursively search directories for a regex pattern
- **[ripgrep-all](https://github.com/phiresky/ripgrep-all)** - rga: ripgrep, but also search in PDFs, E-Books, Office documents, etc.
- **[ast-grep](https://ast-grep.github.io/)** - Code searching, linting, rewriting made easy
- **[imagemagick](https://imagemagick.org/)** - Create, edit, compose, or convert digital images
- **[jpegoptim](https://github.com/tjko/jpegoptim)** - Utility to optimize/compress JPEG files
- **[rnr](https://github.com/ismaelgv/rnr)** - Command-line tool to batch rename files and directories
- **[pigz](https://zlib.net/pigz/)** - Parallel implementation of gzip
- **[kondo](https://github.com/tbillington/kondo)** - Clean software project artifacts (node_modules, target, etc.)
- **[duti](https://github.com/moretension/duti)** - Select default applications for document types and URL schemes on macOS
- **[procs](https://github.com/dalance/procs)** - Modern replacement for ps written in Rust
- **[retry](https://github.com/kadwanev/retry)** - Retry a command until it succeeds
- **[watchexec](https://github.com/watchexec/watchexec)** - Execute commands in response to file modifications
- **[watchman](https://facebook.github.io/watchman/)** - Watches files and records, or triggers actions, when they change
- **[viddy](https://github.com/sachaos/viddy)** - Modern watch command with time machine and diff highlight
- **[hwatch](https://github.com/blacknon/hwatch)** - Alternative watch command that records command results
- **[biff](https://github.com/BurntSushi/biff)** - A command line tool for datetime arithmetic, parsing, formatting
- **[ffmpeg](https://ffmpeg.org/)** - Complete solution to record, convert and stream audio and video
- **[exiftool](https://exiftool.org/)** - Read, write and edit meta information in files
- **[silicon](https://github.com/Aloxaf/silicon)** - Create beautiful images of your source code 

### Installed via Homebrew

- **[tidy-html5](http://www.html-tidy.org/)** - HTML syntax checker and reformatter
- **[xq](https://github.com/sibprogrammer/xq)** - Command-line XML and HTML beautifier and content extractor

---

## Data Processing

### Installed via Nix (nixpkgs)

- **[miller](https://miller.readthedocs.io/)** - Like awk, sed, cut, join, and sort for CSV, TSV, and tabular JSON
- **[jacinda](https://github.com/vmchale/jacinda)** - Functional, expression-oriented data processing language
- **[xan](https://github.com/bstrie/xan)** - The CSV Toolkit (forked from xsv)
- **[jq](https://jqlang.github.io/jq/)** - Command-line JSON processor
- **[yq-go](https://github.com/mikefarah/yq)** - Portable command-line YAML, JSON, XML, CSV and properties processor
- **[gron](https://github.com/tomnomnom/gron)** - Make JSON greppable by transforming it into discrete assignments

### Installed via Homebrew

- **[duckdb](https://duckdb.org/)** - In-process SQL OLAP database management system

---

## Development Tools

### Installed via Nix (nixpkgs)

- **[angle-grinder](https://github.com/rcoh/angle-grinder)** - Log analysis tool for extracting data from logs
- **[git-extras](https://github.com/tj/git-extras)** - GIT utilities -- repo summary, repl, changelog population, and more
- **[git-absorb](https://github.com/tummychow/git-absorb)** - git commit --fixup, but automatic
- **[gitui](https://github.com/extrawurst/gitui)** - Blazing fast terminal-ui for git written in Rust
- **[zsh-forgit](https://github.com/wfxr/forgit)** - Interactive git commands powered by fzf
- **[lazygit](https://github.com/jesseduffield/lazygit)** - Simple terminal UI for git commands
- **[difftastic](https://difftastic.wilfred.me.uk/)** - Structural diff tool that compares files based on their syntax
- **[tokei](https://github.com/XAMPPRocky/tokei)** - Count your code, quickly
- **[hyperfine](https://github.com/sharkdp/hyperfine)** - Command-line benchmarking tool
- **[k6](https://k6.io/)** - Modern load testing tool using Go and JavaScript
- **[just](https://github.com/casey/just)** - Command runner like make, but simpler
- **[treefmt](https://github.com/numtide/treefmt)** - One CLI to format your repo
- **[devenv](https://devenv.sh/)** - Fast, Declarative, Reproducible, and Composable Developer Environments
- **[jujutsu](https://github.com/martinvonz/jj)** - Git-compatible distributed version control system
- **[gh](https://cli.github.com/)** - GitHub's official command line tool
- **[gh-dash](https://github.com/dlvhdr/gh-dash)** - GitHub CLI extension to display a dashboard of PRs and issues
- **[git](https://git-scm.com/)** - Distributed version control system
- **[delta](https://github.com/dandavison/delta)** - Syntax-highlighting pager for git, diff, and grep output
- **[uv](https://github.com/astral-sh/uv)** - Extremely fast Python package installer and resolver

### Installed via Homebrew

- **[aider](https://aider.chat/)** - AI pair programming in your terminal
- **[keyboardSwitcher](https://github.com/Lutzifer/keyboardSwitcher)** - Command line tool to switch keyboard layouts on macOS

---

## Programming Languages & Toolchains

### Haskell (via Nix)

- **[ghc](https://www.haskell.org/ghc/)** - Glasgow Haskell Compiler
- **[hlint](https://github.com/ndmitchell/hlint)** - Haskell source code suggestions
- **[hackage-diff](https://hackage.haskell.org/package/hackage-diff)** - Compare Hackage packages
- **[cabal-install](https://www.haskell.org/cabal/)** - Command-line interface for Cabal and Hackage
- **[hoogle](https://hoogle.haskell.org/)** - Haskell API search engine
- **[implicit-hie](https://github.com/Avi-D-coder/implicit-hie)** - Auto-generate hie.yaml files
- **[cabal-fmt](https://github.com/phadej/cabal-fmt)** - Format .cabal files
- **[haskell-language-server](https://github.com/haskell/haskell-language-server)** - Language Server Protocol for Haskell

### Rust (via Nix)

- **[cargo](https://doc.rust-lang.org/cargo/)** - Rust package manager

### JavaScript/Node.js (via Nix)

- **[nodejs_22](https://nodejs.org/)** - JavaScript runtime built on Chrome's V8 engine
- **[bun](https://bun.sh/)** - All-in-one JavaScript runtime & toolkit
- **[typescript](https://www.typescriptlang.org/)** - Typed superset of JavaScript
- **[prettier](https://prettier.io/)** - Opinionated code formatter
- **[pnpm](https://pnpm.io/)** - Fast, disk space efficient package manager
- **[typescript-language-server](https://github.com/typescript-language-server/typescript-language-server)** - Language Server Protocol implementation for TypeScript

### Configuration Languages (via Nix)

- **[dhall](https://dhall-lang.org/)** - Programmable configuration language
- **[dhall-json](https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-json)** - Convert Dhall to JSON or YAML
- **[dhall-lsp-server](https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server)** - Language Server Protocol for Dhall
- **[nickel](https://nickel-lang.org/)** - Configuration programming language
- **[nls](https://github.com/tweag/nickel)** - Nickel Language Server

### Other Languages & LSPs (via Nix)

- **[ocaml-lsp](https://github.com/ocaml/ocaml-lsp)** - OCaml Language Server Protocol implementation
- **[lua-language-server](https://github.com/LuaLS/lua-language-server)** - Language Server for Lua
- **[yaml-language-server](https://github.com/redhat-developer/yaml-language-server)** - Language Server for YAML
- **[terraform-ls](https://github.com/hashicorp/terraform-ls)** - Terraform Language Server
- **[nil](https://github.com/oxalica/nil)** - Nix Language Server
- **[@tailwindcss/language-server](https://github.com/tailwindlabs/tailwindcss-intellisense)** - Language Server for Tailwind CSS
- **[ls_emmet](https://github.com/aca/emmet-ls)** - Emmet support for language servers

### Formatters (via Nix)

- **[nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)** - Nix code formatter
- **[stylua](https://github.com/JohnnyMorganz/StyLua)** - Opinionated Lua code formatter
- **[yamllint](https://github.com/adrienverge/yamllint)** - Linter for YAML files
- **[yamlfmt](https://github.com/google/yamlfmt)** - Extensible command line tool to format YAML files
- **[pgformatter](https://github.com/darold/pgFormatter)** - PostgreSQL SQL syntax beautifier

---

## Cloud & Container Tools

### Installed via Nix (nixpkgs)

- **[google-cloud-sdk](https://cloud.google.com/sdk)** - Google Cloud Platform command-line interface
- **[google-cloud-sql-proxy](https://github.com/GoogleCloudPlatform/cloud-sql-proxy)** - Provides secure access to Cloud SQL instances
- **[docker](https://www.docker.com/)** - Platform for developing, shipping, and running applications in containers
- **[colima](https://github.com/abiosoft/colima)** - Container runtimes on macOS (and Linux) with minimal setup
- **[hadolint](https://github.com/hadolint/hadolint)** - Dockerfile linter, validate inline bash
- **[lazydocker](https://github.com/jesseduffield/lazydocker)** - Terminal UI for Docker and Docker Compose

---

## Kubernetes Ecosystem

### Installed via Nix (nixpkgs)

- **[kubectl](https://kubernetes.io/docs/reference/kubectl/)** - Kubernetes command-line tool
- **[kubernetes-helm](https://helm.sh/)** - Kubernetes package manager
- **[kustomize](https://kustomize.io/)** - Kubernetes native configuration management
- **[krew](https://krew.sigs.k8s.io/)** - Plugin manager for kubectl
- **[k9s](https://k9scli.io/)** - Terminal UI to interact with Kubernetes clusters
- **[argocd](https://argo-cd.readthedocs.io/)** - Declarative GitOps CD for Kubernetes
- **[argocd-autopilot](https://github.com/argoproj-labs/argocd-autopilot)** - Opinionated way of installing Argo CD and managing GitOps repositories
- **[stern](https://github.com/stern/stern)** - Multi pod and container log tailing for Kubernetes
- **[kubetail](https://github.com/johanhaleby/kubetail)** - Bash script to tail Kubernetes logs from multiple pods
- **[kubefwd](https://github.com/txn2/kubefwd)** - Bulk port forwarding Kubernetes services
- **[gonzo](https://github.com/kscarlett/gonzo)** - Log analysis tool for Kubernetes

---

## Database Tools

### Installed via Nix (nixpkgs)

- **[postgresql_17](https://www.postgresql.org/)** - Powerful, open-source object-relational database system
- **[pgcli](https://www.pgcli.com/)** - Command line interface for PostgreSQL with auto-completion
- **[pspg](https://github.com/okbob/pspg)** - Unix pager designed for work with tables
- **[harlequin](https://harlequin.sh/)** - Terminal-based SQL IDE for DuckDB and PostgreSQL

---

## AI & Machine Learning

### Installed via Nix (nixpkgs)

- **[claude-code](https://docs.anthropic.com/en/docs/claude-code)** - Anthropic's official CLI for Claude
- **[llm](https://llm.datasette.io/)** - CLI utility and Python library for interacting with Large Language Models
- **[goose-cli](https://github.com/block/goose)** - Extensible AI agent for autonomous development
- **[tmuxai](https://github.com/samueldr/tmuxai)** - AI-powered tmux assistant
- **[repomix](https://github.com/yamadashy/repomix)** - Pack repository contents into a single file for AI consumption

---

## Terminal & Session Management

### Installed via Nix (nixpkgs)

- **[sesh](https://github.com/joshmedeski/sesh)** - Smart session manager for tmux
- **[tmuxp](https://tmuxp.git-pull.com/)** - tmux session manager built on libtmux
- **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer
- **[vivid](https://github.com/sharkdp/vivid)** - LS_COLORS generator with multiple themes
- **[bat](https://github.com/sharkdp/bat)** - Cat clone with syntax highlighting and Git integration
- **[direnv](https://direnv.net/)** - Load/unload environment variables based on current directory
- **[fzf](https://github.com/junegunn/fzf)** - Command-line fuzzy finder
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smarter cd command, inspired by z and autojump
- **[atuin](https://github.com/atuinsh/atuin)** - Magical shell history
- **[starship](https://starship.rs/)** - Minimal, blazing-fast, and customizable prompt for any shell
- **[btop](https://github.com/aristocratos/btop)** - Resource monitor that shows usage and stats
- **[pay-respects](https://github.com/arzg/pay-respects)** - Command correction tool
- **[tealdeer](https://github.com/dbrgn/tealdeer)** - Fast implementation of tldr in Rust
- **[wezterm](https://wezfurlong.org/wezterm/)** - GPU-accelerated terminal emulator (terminfo)
- **[neovim](https://neovim.io/)** - Hyperextensible Vim-based text editor
- **[television](https://github.com/alexpasmantier/television)** - TV-like fuzzy finder for the terminal
- **[nix-search-tv](https://github.com/3timeslazy/nix-search-tv)** - Nix package search with television integration
- **[navi](https://github.com/denisidoro/navi)** - Interactive cheatsheet tool for the command-line

### Installed via Homebrew (Casks)

- **[ghostty](https://ghostty.org/)** - Fast, native terminal emulator

---

## Documentation & Media

### Installed via Nix (nixpkgs)

- **[pandoc](https://pandoc.org/)** - Universal document converter
- **[glow](https://github.com/charmbracelet/glow)** - Render markdown on the CLI with style
- **[presenterm](https://github.com/mfontanini/presenterm)** - Terminal-based presentation tool with markdown support
- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** - Feature-rich command-line audio/video downloader
- **[asciinema](https://asciinema.org/)** - Record and share terminal sessions
- **[asciinema-agg](https://github.com/asciinema/agg)** - Generate animated GIFs from asciinema recordings

---

## Security & Credentials

### Installed via Nix (nixpkgs)

- **[_1password-cli](https://developer.1password.com/docs/cli/)** - 1Password command-line tool
- **[sops](https://github.com/getsops/sops)** - Simple and flexible tool for managing secrets
- **[agenix](https://github.com/ryantm/agenix)** - age-encrypted secrets for NixOS and Home Manager

---

## Desktop Applications

### Installed via Nix (nixpkgs)

- **[element-desktop](https://element.io/)** - Secure collaboration and messaging app
- **[terminal-notifier](https://github.com/julienXX/terminal-notifier)** - Send macOS User Notifications from the command-line

### Installed via Homebrew (Casks)

- **[tuple](https://tuple.app/)** - Remote pair programming app
- **[zoom](https://zoom.us/)** - Video conferencing platform
- **[visual-studio-code](https://code.visualstudio.com/)** - Source code editor
- **[discord](https://discord.com/)** - Voice, video, and text communication platform
- **[microsoft-teams](https://www.microsoft.com/microsoft-teams/)** - Business communication platform
- **[anki](https://apps.ankiweb.net/)** - Spaced repetition flashcard program
- **[insomnia](https://insomnia.rest/)** - API design and testing tool
- **[min](https://minbrowser.org/)** - Minimal web browser

---

## Fonts

### Installed via Nix (private-fonts flake)

- **[PragmataPro](https://fsd.it/shop/fonts/pragmatapro/)** - Programming font with extensive Unicode support

---

## Nix-Specific Tools

### Installed via Nix (nixpkgs)

- **[cachix](https://cachix.org/)** - Binary cache hosting for Nix
- **[comma](https://github.com/nix-community/comma)** - Run software from Nixpkgs without installing it
- **[statix](https://github.com/nerdypepper/statix)** - Lints and suggestions for Nix code
- **[deadnix](https://github.com/astro/deadnix)** - Find and remove unused code in Nix files
- **[hydra-check](https://github.com/nix-community/hydra-check)** - Check Hydra build status from the command line
- **[manix](https://github.com/nix-community/manix)** - Fast CLI documentation searcher for Nix
- **[nix-prefetch-git](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/fetchgit/nix-prefetch-git)** - Prefetch git repositories for Nix expressions
- **[nix-tree](https://github.com/utdemir/nix-tree)** - Interactively browse dependency graphs of Nix derivations
- **[node2nix](https://github.com/svanderburg/node2nix)** - Generate Nix expressions to build NPM packages
- **[nix-script](https://github.com/BrianHicks/nix-script)** - Write scripts in compiled languages with Nix

---

## Additional Utilities

### Installed via Homebrew

- **[pam-reattach](https://github.com/fabianishere/pam_reattach)** - PAM module for reattaching to the user's GUI session on macOS

---

## Previously Installed

These packages were previously installed but have been removed from the configuration.

### Removed from Nix

- **[cai](https://github.com/seaplane-io/cai)** - CLI tool for prompting LLMs from the command line

---

## Temporarily Removed

These packages are currently commented out in the configuration and may be re-enabled in the future.

### Nix Packages (Commented Out)

- **coreutils** - GNU core utilities
- **[curl-impersonate](https://github.com/lwthiker/curl-impersonate)** - curl impersonating Chrome/Firefox
- **[monolith](https://github.com/Y2Z/monolith)** - CLI tool for saving complete web pages as a single HTML file
- **[aider-chat](https://aider.chat/)** (withPlaywright) - AI pair programming with browser automation
- **[gitui](https://github.com/extrawurst/gitui)** - Blazing fast terminal UI for git (disabled due to build failures on ARM64)
- **graphql-language-service-cli** - GraphQL Language Server
- **duckdb** (Nix version) - In-process SQL OLAP database (available via Homebrew instead)
- **[ormolu](https://github.com/tweag/ormolu)** - Haskell source code formatter
- **[cabal-plan](https://hackage.haskell.org/package/cabal-plan)** - Library for interacting with cabal's plan.json
- **[cabal-hoogle](https://github.com/phadej/cabal-extras)** - Run hoogle on your cabal project
- **[ocaml](https://ocaml.org/)** - OCaml programming language
- **[dune-release](https://github.com/ocamllabs/dune-release)** - Release dune packages to opam
- **[opam](https://opam.ocaml.org/)** - OCaml package manager

### Homebrew Casks (Commented Out)

- **[raycast](https://raycast.com/)** - Productivity tool and launcher
- **[google-chrome](https://www.google.com/chrome/)** - Web browser (conflicting apps issue)

### Mac App Store Apps (Disabled)

The entire masApps section is disabled due to continual update issues ([malob/nixpkgs#9](https://github.com/malob/nixpkgs/issues/9)):

- **1Password** - Password manager
- **Slack** - Team communication platform
- **Xcode** - Apple development IDE
- **1Blocker** - Ad blocker for Safari

### Disabled Programs

- **[broot](https://dystroy.org/broot/)** - Interactive tree view file manager (programs.broot.enable = false)
- **[carapace](https://carapace.sh/)** - Multi-shell completion framework (programs.carapace.enable = false)

---

## Notes

- **Source**: Packages marked as "Installed via Nix" are installed from nixpkgs
- **Source**: Packages marked as "Installed via Homebrew" are installed through Homebrew (either as brews or casks)
- **Custom Derivations**: Some packages like `tmuxai`, `oq`, and fonts are custom derivations or from private flakes
- **Language Servers**: Most language servers are installed to support the Neovim development environment
- **Terminal Tools**: Heavy emphasis on modern CLI replacements (eza for ls, fd for find, ripgrep for grep, etc.)
