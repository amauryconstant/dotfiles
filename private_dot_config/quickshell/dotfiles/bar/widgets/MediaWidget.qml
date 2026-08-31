import "../"
import "../../"
import Quickshell.Services.Mpris
import QtQuick

// Waybar's mpris module. Waybar delegated player choice to playerctld;
// Quickshell exposes every player, so the same "most relevant one" rule is
// applied here: prefer a playing player, ignore browsers as Waybar did.
BarWidget {
    id: root

    readonly property MprisPlayer player: {
        const usable = Mpris.players.values.filter(p => !root.ignored.some(name => (p.dbusName ?? "").toLowerCase().includes(name)));
        return usable.find(p => p.isPlaying) ?? usable[0] ?? null;
    }
    // Waybar delegated to playerctld exclusively; here every player is
    // visible, so the playerctld proxy has to go or it double-counts the
    // real player it is proxying. Browsers were Waybar's ignored-players.
    readonly property list<string> ignored: ["firefox", "chromium", "playerctld"]

    icon: {
        if (!root.player)
            return "";
        return root.player.isPlaying ? "󰐊" : root.player.playbackState === MprisPlaybackState.Paused ? "󰏤" : "󰓛";
    }
    // The track title is the one label the bar cannot move to a tooltip: it is
    // what the widget is for.
    label: {
        const title = root.player?.trackTitle ?? "";
        if (title === "")
            return "";
        const artist = root.player.trackArtist ?? "";
        const text = String(artist === "" ? title : `${title} - ${artist}`);
        // Waybar's dynamic-len 35 with a unicode ellipsis.
        return text.length > Config.mediaMaxLength ? text.substring(0, Config.mediaMaxLength - 1) + "…" : text;
    }
    tooltipText: root.player ? `${root.player.identity}\n${root.player.trackTitle}\n${root.player.trackArtist} - ${root.player.trackAlbum}` : ""

    onClicked: root.player?.togglePlaying()
    onMiddleClicked: root.player?.previous()
    onRightClicked: root.player?.next()
    onScrolledDown: {
        if (root.player?.volumeSupported)
            root.player.volume = Math.max(0, root.player.volume - Config.volumeStep);
    }
    onScrolledUp: {
        if (root.player?.volumeSupported)
            root.player.volume = Math.min(1, root.player.volume + Config.volumeStep);
    }
}
