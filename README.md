# TurboEnhance

> Turbocharge your macOS terminal with a seamless Zsh setup,
> Powerlevel10k, and essential plugins for maximum productivity!

TurboEnhance is a setup script designed to streamline and supercharge your macOS terminal environment. It automates the installation of Zsh, Oh My Zsh, Powerlevel10k, and essential plugins, transforming your terminal into a highly efficient, visually appealing tool for developers and power users.

```mermaid
flowchart LR
    USER[("👤 fresh<br/>macOS shell")]
    SH{{"🚀 setup.sh"}}
    BREW["🍺 Homebrew + tools<br/>tmux · vim · neovim · git"]
    OMZ["🎨 Oh My Zsh +<br/>Powerlevel10k"]
    PLUG["🔌 plugins<br/>fzf · syntax-highlighting · autosuggestions"]
    BAK["📦 backup<br/>.zshrc · .zprofile"]
    OUT[/"⚡ supercharged<br/>terminal"/]

    USER --> SH
    SH --> BAK
    SH --> BREW
    SH --> OMZ
    SH --> PLUG
    BAK --> OUT
    BREW --> OUT
    OMZ --> OUT
    PLUG --> OUT

    classDef io fill:#0e1116,stroke:#2f81f7,stroke-width:1.5px,color:#e6edf3;
    classDef tool fill:#161b22,stroke:#3fb950,stroke-width:1.5px,color:#e6edf3;
    classDef brain fill:#161b22,stroke:#d29922,stroke-width:1.5px,color:#e6edf3;
    classDef out fill:#0e1116,stroke:#a371f7,stroke-width:1.5px,color:#e6edf3;
    class USER io;
    class BREW,OMZ,PLUG,BAK tool;
    class SH brain;
    class OUT out;
```

## Table of contents

- [Features](#features)
- [Installation](#installation)

## Features
- **Automated Zsh Setup**: Installs and configures Zsh with Oh My Zsh.
- **Powerlevel10k Theme**: Set up with Powerlevel10k for a beautiful and functional prompt.
- **Essential Plugins**: Includes fuzzy search (fzf), syntax highlighting, autosuggestions, and more.
- **Backup Support**: Option to backup your existing `.zshrc` and `.zprofile` files before overwriting.
- **Homebrew Integration**: Automatically installs Homebrew and essential tools if not already present.
- **Cross-Functionality**: Boost productivity with tmux, vim, neovim, and git pre-installed.
- **Fuzzy Finder**: Full fzf integration with autocomplete and keybindings.

## Installation

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/turboenhance.git
cd turboenhance
```
