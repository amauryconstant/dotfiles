import "../"
import "../../"
import Quickshell.Hyprland
import QtQuick

// Waybar's hyprland/window: the focused window's title, truncated at 50.
// Truncation is by character count rather than Qt's pixel-based elide, so the
// cut lands in the same place Waybar's max-length put it.
BarWidget {
    id: root

    readonly property string title: Hyprland.activeToplevel?.title ?? ""

    hoverBackground: false
    label: root.title.length > Config.titleMaxLength ? root.title.substring(0, Config.titleMaxLength - 1) + "…" : root.title
    // Only worth a tooltip when something was actually cut off.
    tooltipText: root.title.length > Config.titleMaxLength ? root.title : ""
}
