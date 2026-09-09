import "../"
import "../../"
import Quickshell.Hyprland
import QtQuick

// Waybar's hyprland/window: the focused window's title.
//
// 🚨 Bounded in PIXELS, not characters. This used to cut at 50 characters to
// match Waybar's max-length, which does not bound the bar at all — a title of
// 50 W's is roughly three times the width of 50 i's, so the centre zone moved
// with the content. Width plus Text.elide is the only cap that means anything.
//
// With no focused window the element is REMOVED rather than blanked (BarWidget
// hides on an empty label), so the clock keeps its centre position.
BarWidget {
    id: root

    // Set by the bar under width pressure: the title is the first element to
    // give up width, shrinking to titleMinW before it drops entirely.
    property int maxWidth: Config.titleMaxW
    readonly property string title: Hyprland.activeToplevel?.title ?? ""

    hoverBackground: false
    label: root.title
    // A path's identifying half is its tail, so it elides mid-string; anything
    // else elides at the end.
    labelElideMode: root.title.includes("/") ? Text.ElideMiddle : Text.ElideRight
    labelMaxWidth: root.maxWidth
    // Only worth a tooltip when something was actually cut off.
    tooltipText: root.labelTruncated ? root.title : ""
}
