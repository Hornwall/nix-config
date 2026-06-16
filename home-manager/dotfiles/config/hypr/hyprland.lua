-- Migrated from hyprland.conf.
-- Keep hyprland.conf around as a fallback while validating the Lua config.

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "", mode = "1920x1080", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "1" })
hl.monitor({ output = "DP-1", mode = "preferred", position = "-1920x0", scale = "auto" })
hl.monitor({ output = "desc:LG Electronics LG ULTRAWIDE 506NTCZJZ651", mode = "preferred", position = "-1920x0", scale = "1.25" })
hl.monitor({ output = "desc:Dell Inc. Dell AW3423DW", mode = "preferred", position = "-1920x0", scale = "auto" })
hl.monitor({ output = "HDMI-A-2", disabled = true })
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "auto", scale = "auto" })

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "dolphin"
local menu        = "walker"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("elephant")
    hl.exec_cmd("walker --gapplication-service")
    hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])
    hl.exec_cmd([[gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"]])
    hl.exec_cmd("gnome-keyring-daemon --start --components=ssh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("ironbar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(terminal)
    hl.exec_cmd("firefox")
    hl.exec_cmd("slack")
    hl.exec_cmd("voxtype daemon")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita-HyprCursor")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("SSH_AUTH_SOCK", "$XDG_RUNTIME_DIR/keyring/ssh")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("QT_STYLE_OVERRIDE", "Adwaita-Dark")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_SCALE", "2")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 6,
        border_size = 0,
        -- Borderless — colours kept for reference if re-enabled.
        col = {
            active_border = "rgba(68b5abff)",
            inactive_border = "rgba(5c656e55)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 14,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        shadow = {
            enabled = false,
        },
        -- Frosted-glass backdrop.
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            noise = 0.012,
            contrast = 1.1,
            brightness = 1.0,
            vibrancy = 0.25,
            vibrancy_darkness = 0.05,
            popups = true,
            popups_ignorealpha = 0.2,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Glass: frost the wallpaper behind layer-shell surfaces. The .conf form is:
--   layerrule = blur, <ironbar|walker|swaync-control-center|swaync-notification-window>
--   layerrule = ignorezero, <same>
-- Port these once the layer-rule binding is confirmed in the Lua API; until
-- then hyprland.conf (the live config) carries them.

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 }   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 }   } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 }      } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 }    } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 2,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 2,    bezier = "easeOutQuint",   style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",         style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint",   style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",         style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear",   style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear",   style = "fade" })

hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "1", monitor = "desc:Dell Inc. Dell AW3423DW", default = true })
hl.workspace_rule({ workspace = "2", monitor = "desc:Dell Inc. Dell AW3423DW", default = true })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1", default = true })

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 1,
        disable_hyprland_logo = true,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us-custom",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q",              hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + CTRL + ALT + P", hl.dsp.exec_cmd("ironbar toggle"))
hl.bind(mainMod .. " + SHIFT + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + M",      hl.dsp.exit())
hl.bind(mainMod .. " + E",              hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE",          hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",              hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + o",              hl.dsp.exec_cmd("voxtype record toggle"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind("CTRL + ALT + " .. mainMod .. " + H", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind("CTRL + ALT + " .. mainMod .. " + L", hl.dsp.workspace.move({ monitor = "r" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | tee ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy]]))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("gradia --screenshot"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | tesseract stdin stdout | wl-copy && notify-send "OCR" "Text copied to clipboard"]]))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd([[wf-recorder -g "$(slurp)" -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4 && notify-send "Screen Recording" "Recording started" -i video-x-generic]]))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd([[pkill -SIGINT wf-recorder && notify-send "Screen Recording" "Recording stopped" -i video-x-generic]]))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprlock"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "on" }), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name = "slack-workspace-3",
    match = { class = "^(Slack)$" },
    workspace = "3",
})

hl.window_rule({
    name = "firefox-workspace-2",
    match = { class = "^(firefox)$" },
    workspace = "2",
})

hl.window_rule({
    name = "ghostty-workspace-1",
    match = { class = "^(com\\.mitchellh\\.ghostty)$" },
    workspace = "1",
})

hl.window_rule({
    name = "pip-workspace-5",
    match = { title = "^(Picture-in-Picture)$" },
    workspace = "5",
})
