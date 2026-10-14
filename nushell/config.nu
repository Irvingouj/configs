# config.nu
#
# Installed by:
# version = "0.111.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
#

# ============================================
# 迁移自 PowerShell Profile
# ============================================

# -------------------
# 1. 别名 (Aliases)
# -------------------
alias got = git
alias g = git
alias carog = cargo
alias celar = clear

# -------------------
# 2. 自定义命令 (Custom Commands)
# -------------------

# i - 统一开发环境 CLI
def i [...args] {
    pwsh -File C:\Users\jou\Desktop\scripts\bin\i.ps1 ...$args
}

# lvim - LazyVim 启动脚本
def lvim [...args] {
    pwsh -File C:\Users\jou\.local\bin\lvim.ps1 ...$args
}

# rgf - 搜索文件名（支持 glob 模式）
def rgf [...patterns] {
    rg --files -g ...$patterns
}

# nvf - 用 fzf 选择文件后用 nvim 打开
def nvf [] {
    let file = (fzf | str trim)
    if ($file != "") {
        nvim ($file | str replace --all '\\' '/')
    }
}

# ws - workspaces 快速切换目录
def ws [] {
    workspaces
    let result_file = $"($env.USERPROFILE)/AppData/Roaming/workspaces-rs/result.txt"
    if ($result_file | path exists) {
        cd (open $result_file | str trim)
    }
}

# code - VSCode Insiders
def code [...args] {
    code-insiders ...$args
}

# ii - 打开 Windows 文件资源管理器
def ii [path?: string] {
    if ($path == null) {
        explorer .
    } else {
        explorer $path
    }
}

# vs - 打开 Visual Studio 解决方案
def vs [...args] {
    ^pwsh -NoProfile -File C:\Users\jou\Desktop\scripts\bin\vs.ps1 ...$args
}

# copilot - GitHub Copilot CLI（独立版本）
def copilot [...args] {
    ^"C:/Users/jou/AppData/Local/Microsoft/WinGet/Links/copilot.exe" ...$args
}

# cop - copilot 的简短别名
def cop [...args] {
    copilot ...$args
}

# btm / bottom - 使用自定义配置启动 bottom
def --wrapped btm [...args] {
    let config_path = ($env.APPDATA | path join "bottom" "bottom.toml")
    ^btm -C $config_path ...$args
}

def --wrapped bottom [...args] {
    btm ...$args
}

# -------------------
# 3. 环境变量
# -------------------
$env.MSBUILDMAXCPUCOUNT = 4

# -------------------
# 4. 工具集成
# -------------------

# zoxide 集成（目录跳转）
source ~/.zoxide.nu

# -------------------
# 5. 补全和历史优化
# -------------------

# 模糊匹配补全（更智能的命令补全）
$env.config.completions.algorithm = "fuzzy"

# SQLite 历史记录（支持时间戳、工作目录等元数据）
$env.config.history.file_format = "sqlite"
$env.config.history.max_size = 1_000_000  # 最多 100 万条历史
$env.config.history.isolation = false     # 不隔离会话，所有窗口共享历史

# -------------------
# 6. 主题
# -------------------

# 颜色要配合终端背景，所以跟着 follow-os-theme.nu 写出的 Alacritty 主题走
use std/config [light-theme dark-theme]
$env.config.hooks.pre_prompt ++= [{||
    let alacritty = if $nu.os-info.name == "windows" {
        $env.APPDATA | path join alacritty
    } else {
        $env.XDG_CONFIG_HOME? | default ('~/.config' | path expand) | path join alacritty
    }
    let mode = if (open --raw ($alacritty | path join themes current.toml) | str contains "Solarized Light") { "light" } else { "dark" }
    if $mode != ($env.SOLARIZED_MODE? | default "") {
        $env.config.color_config = if $mode == "light" { light-theme } else { dark-theme }
        $env.SOLARIZED_MODE = $mode
    }
}]


def --wrapped cc [...args: string] {
    ^"C:/Program Files/Git/bin/bash.exe" -c $"claude --dangerously-skip-permissions ($args | str join ' ')"
}

# bro: Q&A with session + doc context (gpt-5.4-nano)
#   bro <question>        → continues session (or starts new with docs)
#   bro --new <question>  → resets session, re-injects docs
#   bro-local <question>  → offline via ollama, no docs
def --wrapped bro [...args: string] {
    let reset = ($args | any {|a| $a in ["--new", "--reset", "--clear"]})
    let query = ($args | where {|a| $a not-in ["--new", "--reset", "--clear"]} | str join " ")
    let session_file = $"($env.APPDATA)/aichat/sessions/bro.yaml"
    let is_new = ($reset or (not ($session_file | path exists)))
    if $is_new {
        glob ~/docs/**/*.md | each { open $in } | str join "\n---\n"
        | aichat -s bro --empty-session --save-session --prompt "You are a concise technical assistant. Give short, direct answers. No markdown formatting unless the user asks. Prefer one-liners when possible." $query
    } else {
        aichat -s bro --save-session $query
    }
}

def --wrapped bro-local [...args: string] {
    aichat -m ollama:qwen-fast ($args | str join " ")
}
