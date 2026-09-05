import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.kspringall.grammarchy"
  property bool busy: false
  property string status: ""
  property var settings: ({ widget: { width_px: 680, auto_parse_on_open: true }, parser: { timeout_ms: 2000 }, display: { mode: "reed_kellogg" } })
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") !== "" ? Quickshell.env("XDG_CONFIG_HOME") : Quickshell.env("HOME") + "/.config"
  readonly property string helper: configHome + "/omarchy/plugins/io.github.kspringall.grammarchy/bin/grammarchy"
  readonly property bool opened: panel.open
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function validSettings(next) {
    return next && next.widget && next.parser && next.display && Number.isInteger(next.widget.width_px) && next.widget.width_px >= 620 && next.widget.width_px <= 760 && typeof next.widget.auto_parse_on_open === "boolean" && Number.isInteger(next.parser.timeout_ms) && next.parser.timeout_ms >= 100 && next.parser.timeout_ms <= 10000 && (next.display.mode === "reed_kellogg" || next.display.mode === "dependency")
  }
  function openFromClipboard() {
    if (busy) return
    busy = true; status = "Reading clipboard…"
    clipboard.command = [helper, "clipboard"]; clipboard.running = true; clipboardTimer.restart()
  }
  // Standard bar-panel contract: lets Omarchy activate this widget through
  // keyboard navigation and shell IPC as well as by pointer click.
  function open() { openFromClipboard() }
  function close() { panel.closePanel() }
  function toggle() { if (panel.open) close(); else open() }
  function cancelClipboard(message) {
    if (!busy) return
    clipboardTimer.stop(); clipboard.signal(15); clipboard.running = false; busy = false; status = message
    panel.showSentence("", message + " Type a sentence instead.", false)
  }

  Process {
    id: config
    command: [root.helper, "config"]
    stdout: StdioCollector { id: configOut; waitForEnd: true }
    onExited: function(code) {
      var raw = String(configOut.text || "")
      if (code !== 0 || raw.length > 4096) return
      try { var next = JSON.parse(raw); if (root.validSettings(next)) root.settings = next } catch (error) {}
    }
  }
  Process {
    id: clipboard
    stdout: StdioCollector { id: clipboardOut; waitForEnd: true }
    stderr: StdioCollector { id: clipboardErr; waitForEnd: true }
    onExited: function(code) {
      clipboardTimer.stop(); root.busy = false
      if (code !== 0) {
        root.status = String(clipboardErr.text || "Clipboard is unavailable.").trim()
        panel.showSentence("", root.status + " Type a sentence instead.", false)
        return
      }
      var raw = String(clipboardOut.text || "")
      if (raw.length > 4096) {
        root.status = "Clipboard response was too large."
        panel.showSentence("", root.status + " Type a sentence instead.", false)
        return
      }
      try {
        var result = JSON.parse(raw)
        if (!result || typeof result.text !== "string" || result.text.length > 1000 || typeof result.requires_confirmation !== "boolean" || (result.status !== undefined && (typeof result.status !== "string" || result.status.length > 240))) throw new Error("invalid clipboard response")
        panel.showSentence(result.text, result.status || "Ready", result.requires_confirmation)
        root.status = ""
      } catch (error) {
        root.status = "Could not read a safe sentence from the clipboard."
        panel.showSentence("", root.status + " Type a sentence instead.", false)
      }
    }
  }
  Timer { id: clipboardTimer; interval: 2000; onTriggered: root.cancelClipboard("Clipboard request timed out.") }
  Component.onCompleted: config.running = true

  BarIconButton {
    id: button; anchors.fill: parent; bar: root.bar
    text: "G"; slotSize: Style.bar.statusSlot; fontSize: Style.font.caption; active: panel.open; activeColor: Color.accent; dimmed: root.busy
    tooltipText: root.status !== "" ? root.status : "Grammarchy — inspect clipboard sentence"
    onPressed: function() { root.toggle() }
  }
  GrammarchyPanel { id: panel; hostWidget: root; triggerItem: button; helper: root.helper; settings: root.settings }
}
