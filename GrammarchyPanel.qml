import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import qs.Ui as OmarchyUi

KeyboardPanel {
  id: root
  property var hostWidget: null
  property Item triggerItem: null
  property string helper: ""
  property var settings: ({ widget: { width_px: 980, auto_parse_on_open: true }, parser: { timeout_ms: 2000 }, display: { mode: "reed_kellogg" } })
  property string parserStatus: "Ready"
  property string diagnostic: ""
  property bool busy: false
  property bool livePending: false
  property bool awaitingConfirmation: false
  property var diagram: ({ mode: "reed_kellogg", nodes: [], edges: [], phrases: [], clauses: [], findings: [], constructions: [], confidence: 0, simplified: false, parser: "Local heuristic (English)" })
  anchorItem: triggerItem
  bar: hostWidget ? hostWidget.bar : null
  focusTarget: sentence
  contentWidth: fittedContentWidth(980, 1120)
  contentHeight: cappedContentHeight(820)
  onOpenChanged: if (!open && busy) cancelParse("")

  function selectedMode() { return viewTabs.currentIndex === 2 ? "dependency" : "reed_kellogg" }
  function accentFor(role) {
    if (role === "predicate") return "#6fc7ff"
    if (role === "subject" || role === "object of preposition" || role === "object / complement") return "#9eea9a"
    if (role === "determiner") return "#ffe56a"
    if (role === "adjective" || role === "adverbial modifier") return "#ffad52"
    if (role === "preposition") return "#c58cff"
    return Color.foreground
  }
  function showSentence(text, message, needsConfirmation) {
    sentence.text = text || ""; parserStatus = message || "Ready"; diagnostic = ""; awaitingConfirmation = needsConfirmation === true; open = true
    viewTabs.currentIndex = settings && settings.display && settings.display.mode === "dependency" ? 2 : 0
    if (awaitingConfirmation) diagnostic = "The clipboard has more than one sentence. Confirm before parsing the first sentence."
    Qt.callLater(function() { sentence.forceActiveFocus(); sentence.selectAll() })
    if (!awaitingConfirmation && (!settings || !settings.widget || settings.widget.auto_parse_on_open !== false) && sentence.text.trim() !== "") parse()
  }
  function closePanel() { cancelParse(""); open = false }
  function cancelParse(message) { if (!busy) return; parseTimer.stop(); parser.signal(15); parser.running = false; busy = false; parserStatus = "Ready"; if (message !== "") diagnostic = message }
  function validModel(next) {
    if (!next || next.schemaVersion !== 1 || !next.provider || typeof next.provider.id !== "string" || next.provider.id.length === 0 || next.provider.id.length > 80 || typeof next.provider.version !== "string" || typeof next.provider.model !== "string" || !next.sentence || typeof next.sentence.text !== "string" || next.sentence.text.length === 0 || next.sentence.text.length > 1000 || typeof next.sentence.confidence !== "number" || next.sentence.confidence < 0 || next.sentence.confidence > 1 || (next.mode !== "reed_kellogg" && next.mode !== "dependency") || !Array.isArray(next.nodes) || next.nodes.length === 0 || !Array.isArray(next.edges) || !Array.isArray(next.phrases) || !Array.isArray(next.clauses) || !Array.isArray(next.findings) || !Array.isArray(next.constructions) || next.nodes.length > 128 || next.edges.length > 256 || next.phrases.length > 256 || next.clauses.length > 256 || next.findings.length > 256 || next.constructions.length > 256 || typeof next.diagnostic !== "string" || next.diagnostic.length > 240 || typeof next.confidence !== "number" || next.confidence < 0 || next.confidence > 1 || typeof next.simplified !== "boolean" || typeof next.parser !== "string" || next.parser.length === 0 || next.parser.length > 80) return false
    for (var i = 0; i < next.nodes.length; i++) { var node = next.nodes[i]; if (!node || node.id !== i || typeof node.text !== "string" || node.text.length === 0 || node.text.length > 80 || typeof node.role !== "string" || node.role.length === 0 || node.role.length > 80 || typeof node.pos !== "string" || node.pos.length === 0 || node.pos.length > 24 || typeof node.lemma !== "string" || node.lemma.length === 0 || node.lemma.length > 80 || !node.features || typeof node.features !== "object" || Array.isArray(node.features) || Object.keys(node.features).length > 16) return false; var featureKeys = Object.keys(node.features); for (var featureIndex = 0; featureIndex < featureKeys.length; featureIndex++) { var featureKey = featureKeys[featureIndex], featureValue = node.features[featureKey]; if (featureKey.length > 40 || typeof featureValue !== "string" || featureValue.length > 80) return false } }
    for (var j = 0; j < next.edges.length; j++) { var edge = next.edges[j]; if (!edge || !Number.isInteger(edge.from) || !Number.isInteger(edge.to) || edge.from < 0 || edge.to < 0 || edge.from >= next.nodes.length || edge.to >= next.nodes.length || edge.from === edge.to || typeof edge.label !== "string" || edge.label.length === 0 || edge.label.length > 80) return false }
    var groups = next.phrases.concat(next.clauses)
    for (var k = 0; k < groups.length; k++) { var group = groups[k]; if (!group || typeof group.kind !== "string" || group.kind.length === 0 || group.kind.length > 80 || !Array.isArray(group.node_ids) || group.node_ids.length === 0 || group.node_ids.length > next.nodes.length) return false; var groupSeen = {}; for (var m = 0; m < group.node_ids.length; m++) { var groupId = group.node_ids[m]; if (!Number.isInteger(groupId) || groupId < 0 || groupId >= next.nodes.length || groupSeen[groupId]) return false; groupSeen[groupId] = true } }
    for (var n = 0; n < next.findings.length; n++) { var finding = next.findings[n]; if (!finding || ["error", "possible", "correct", "style"].indexOf(finding.kind) === -1 || typeof finding.title !== "string" || finding.title.length === 0 || finding.title.length > 100 || typeof finding.message !== "string" || finding.message.length === 0 || finding.message.length > 400 || !Array.isArray(finding.node_ids) || finding.node_ids.length > next.nodes.length) return false; var findingSeen = {}; for (var p = 0; p < finding.node_ids.length; p++) { var findingId = finding.node_ids[p]; if (!Number.isInteger(findingId) || findingId < 0 || findingId >= next.nodes.length || findingSeen[findingId]) return false; findingSeen[findingId] = true } }
    for (var q = 0; q < next.constructions.length; q++) { var construction = next.constructions[q]; if (!construction || construction.kind !== "pattern" || typeof construction.title !== "string" || construction.title.length === 0 || construction.title.length > 100 || typeof construction.message !== "string" || construction.message.length === 0 || construction.message.length > 400 || !Array.isArray(construction.node_ids) || construction.node_ids.length === 0 || construction.node_ids.length > next.nodes.length) return false; var constructionSeen = {}; for (var r = 0; r < construction.node_ids.length; r++) { var constructionId = construction.node_ids[r]; if (!Number.isInteger(constructionId) || constructionId < 0 || constructionId >= next.nodes.length || constructionSeen[constructionId]) return false; constructionSeen[constructionId] = true } }
    return true
  }
  function parse() {
    var text = sentence.text.trim()
    if (busy || text === "") { diagnostic = "Paste or type one English sentence."; return }
    if (text.length > 1000) { diagnostic = "Use a sentence shorter than 1,000 characters."; return }
    awaitingConfirmation = false; busy = true; diagnostic = ""; parserStatus = "Parsing locally…"
    parser.command = [helper, "parse", "--mode", selectedMode(), text]; parser.running = true; parseTimer.interval = (settings && settings.parser && typeof settings.parser.timeout_ms === "number" ? settings.parser.timeout_ms : 2000) + 250; parseTimer.restart()
  }
  function setMode(next) { viewTabs.currentIndex = next === "dependency" ? 2 : 0; if (open && diagram.nodes && diagram.nodes.length) parse() }
  Item {
    visible: false
    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    Shortcut { sequence: "Return"; enabled: sentence.activeFocus; onActivated: root.parse() }
    Shortcut { sequence: "Ctrl+Return"; onActivated: root.parse() }
    Shortcut { sequence: "1"; enabled: !sentence.activeFocus; onActivated: root.setMode("reed_kellogg") }
    Shortcut { sequence: "2"; enabled: !sentence.activeFocus; onActivated: root.setMode("dependency") }
    Process {
      id: parser
      stdout: StdioCollector { id: parserOut; waitForEnd: true }
      stderr: StdioCollector { id: parserErr; waitForEnd: true }
      onExited: function(code) {
        parseTimer.stop(); if (!root.busy) return; root.busy = false
        var raw = String(parserOut.text || "")
        if (code !== 0 || raw.length > 65536) { root.parserStatus = "Parser is unavailable"; root.diagnostic = String(parserErr.text || "Check the local parser setup, then retry.").trim(); if (root.livePending) { root.livePending = false; liveTimer.restart() }; return }
        try { var next = JSON.parse(raw); if (!root.validModel(next)) throw new Error("invalid model"); root.diagram = next; root.parserStatus = next.simplified ? "Simplified diagram" : "Parsed locally"; root.diagnostic = next.diagnostic } catch (error) { root.parserStatus = "Parser is unavailable"; root.diagnostic = "The local parser returned an invalid response." }
        if (root.livePending) { root.livePending = false; liveTimer.restart() }
      }
    }
    Timer { id: parseTimer; onTriggered: root.cancelParse("Local parsing timed out. Retry when the parser is available.") }
    Timer { id: liveTimer; interval: 260; repeat: false; onTriggered: { if (sentence.text.trim() !== "") { if (root.busy) root.livePending = true; else root.parse() } } }
  }

  ColumnLayout {
    anchors.fill: parent; anchors.margins: 14; spacing: 8
    RowLayout {
      Layout.fillWidth: true; Layout.preferredHeight: 42; spacing: 8
      Label { text: "grammarchy"; color: "#9e82ff"; font.pixelSize: 26; font.weight: Font.Medium; textFormat: Text.PlainText }
      Label { text: "sentence diagram"; color: Color.muted; font.pixelSize: 22; textFormat: Text.PlainText }
    }
    Rectangle {
      Layout.fillWidth: true; Layout.preferredHeight: 86; radius: 8; color: Color.popups.background; border.color: Color.popups.border
      ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 0
        Label { text: "Sentence"; color: "#9e82ff"; font.pixelSize: 16; textFormat: Text.PlainText }
        OmarchyUi.TextField {
          id: sentence
          Layout.fillWidth: true
          Layout.preferredHeight: 42
          focus: true
          activeFocusOnTab: true
          focusPolicy: Qt.StrongFocus
          enabled: true
          readOnly: false
          selectByMouse: true
          persistentSelection: true
          font.pixelSize: 23
          placeholderText: "Paste or type one English sentence"
          Accessible.name: "Sentence to diagram"
          onAccepted: root.parse()
          onTextEdited: { root.parserStatus = "Building structure…"; liveTimer.restart() }
        }
      }
    }
    Label { Layout.fillWidth: true; visible: root.diagnostic !== ""; color: Color.muted; wrapMode: Text.Wrap; text: root.diagnostic; textFormat: Text.PlainText }
    Rectangle {
      Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: 300; Layout.minimumHeight: 240; radius: 8; color: Color.popups.background; border.color: Color.popups.border
      ColumnLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 6
        RowLayout {
          Layout.fillWidth: true; Layout.preferredHeight: 32
          Item { Layout.fillWidth: true }
          TabBar {
            id: viewTabs
            Layout.preferredWidth: 520; Layout.preferredHeight: 32
            TabButton { text: "Diagram"; Accessible.name: "Sentence map" }
            TabButton { text: "Phrases"; Accessible.name: "Phrases and clauses" }
            TabButton { text: "Relationships"; Accessible.name: "Dependency relationships" }
            TabButton { text: "Improve"; Accessible.name: "Grammar and style findings" }
            TabButton { text: "Patterns"; Accessible.name: "Named grammatical constructions" }
            onCurrentIndexChanged: if (root.open && root.diagram.nodes && root.diagram.nodes.length && currentIndex === 2 && root.diagram.mode !== "dependency") root.parse()
          }
        }
        DiagramCanvas { Layout.fillWidth: true; Layout.fillHeight: true; model: root.diagram; busy: root.busy; treeMode: viewTabs.currentIndex === 2; viewIndex: viewTabs.currentIndex; accentFor: root.accentFor }
      }
    }
    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 42; radius: 8; color: Qt.rgba(1, 1, 1, .025); border.color: Color.popups.border
      RowLayout { anchors.fill: parent; anchors.margins: 8; spacing: 8; Label { Layout.fillWidth: true; text: (root.busy ? "Parsing locally…" : root.parserStatus) + " · " + (root.diagram.parser || "Local parser") + " · Enter parses · Esc closes"; color: Color.muted; font.pixelSize: 14; elide: Text.ElideRight; textFormat: Text.PlainText } Button { visible: root.awaitingConfirmation; text: "Parse first sentence"; Layout.preferredHeight: 28; onClicked: root.parse() } Button { visible: root.busy; text: "Cancel"; Layout.preferredHeight: 28; onClicked: root.cancelParse("Parsing cancelled.") } Button { visible: !root.busy && !root.awaitingConfirmation; text: "Parse"; Layout.preferredHeight: 28; onClicked: root.parse() } }
    }
  }
}
