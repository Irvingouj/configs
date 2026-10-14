#!/usr/bin/env nu
# Alacritty and Zellij can't see the OS light/dark setting, so this polls it and
# rewrites the two config lines they live-reload: the Alacritty theme and Zellij's hue.

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

def apply [mode: string, zellij_kdl: path] {
    cp ($THEMES | path join $"solarized_($mode).toml") ($THEMES | path join current.toml)

    let kdl = (open --raw $zellij_kdl)
    if not ($kdl =~ '(?m)^explicit_theme_hue ') {
        error make { msg: $"no `explicit_theme_hue` line in ($zellij_kdl)" }
    }
    let updated = ($kdl | str replace --regex '(?m)^explicit_theme_hue "\w+"' $'explicit_theme_hue "($mode)"')
    if $updated != $kdl {
        $updated | save --raw --force $zellij_kdl
    }
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
