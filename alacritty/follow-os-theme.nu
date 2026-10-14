#!/usr/bin/env nu
# Alacritty, Zellij, Claude Code and OpenCode don't reliably follow the OS light/dark setting,
# so this polls it and rewrites the config each one live-reloads.

const THEMES = path self themes

def os-mode []: nothing -> string {
    match $nu.os-info.name {
        "windows" => {
            let light = (registry query --hkcu 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' AppsUseLightTheme | get value)
            if $light == 1 { "light" } else { "dark" }
        }
        "macos" => {
            # `defaults` exits non-zero when the key is missing, which means light mode
            let style = (^defaults read -g AppleInterfaceStyle | complete | get stdout)
            if ($style | str contains "Dark") { "dark" } else { "light" }
        }
        _ => {
            let scheme = (^gsettings get org.gnome.desktop.interface color-scheme | complete | get stdout)
            if ($scheme | str contains "dark") { "dark" } else { "light" }
        }
    }
}

def zellij-config []: nothing -> path {
    ^zellij setup --check
    | lines
    | where $it starts-with "[CONFIG DIR]"
    | first
    | parse '[CONFIG DIR]: "{dir}"'
    | get 0.dir
    | path join config.kdl
}

def claude-settings []: nothing -> path {
    $env.CLAUDE_CONFIG_DIR? | default ('~/.claude' | path expand) | path join settings.json
}

def opencode-cli []: nothing -> path {
    $env.XDG_CONFIG_HOME? | default ('~/.config' | path expand) | path join opencode cli.json
}

def replace-line [file: path, pattern: string, replacement: string] {
    let text = (open --raw $file)
    if not ($text =~ $pattern) {
        error make { msg: $"no line matching `($pattern)` in ($file)" }
    }
    let updated = ($text | str replace --regex $pattern $replacement)
    if $updated != $text {
        $updated | save --raw --force $file
    }
}

def apply [mode: string, zellij_kdl: path] {
    cp ($THEMES | path join $"solarized_($mode).toml") ($THEMES | path join current.toml)
    replace-line $zellij_kdl '(?m)^explicit_theme_hue "\w+"' $'explicit_theme_hue "($mode)"'
    # The ANSI themes draw with the terminal's palette, which is Solarized
    replace-line (claude-settings) '"theme":\s*"[^"]*"' $'"theme": "($mode)-ansi"'
    # Only the theme mode is light/dark; `tabs.mode` is "off", so it never matches
    replace-line (opencode-cli) '"mode":\s*"(light|dark)"' $'"mode": "($mode)"'
}

def main [] {
    let zellij_kdl = (zellij-config)
    mut last = ""
    loop {
        let mode = (os-mode)
        if $mode != $last {
            apply $mode $zellij_kdl
            $last = $mode
        }
        sleep 2sec
    }
}
