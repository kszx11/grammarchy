import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

FocusScope {
  id: root
  property var model: ({ nodes: [], phrases: [], clauses: [], edges: [], findings: [], constructions: [] })
  property bool busy: false
  property bool treeMode: false
  property int viewIndex: 0
  property var accentFor: function(role) { return Color.foreground }
  property int selected: -1
  implicitHeight: 330

  function nodes() { return model.nodes || [] }
  function words(ids) {
    var output = [], source = nodes()
    for (var i = 0; i < (ids || []).length; i++) if (source[ids[i]]) output.push(source[ids[i]].text)
    return output.join(" ")
  }
  function roleWords(roles) {
    var output = [], source = nodes()
    for (var i = 0; i < source.length; i++) if (roles.indexOf(source[i].role) !== -1) output.push(source[i].text)
    return output.join(" ") || "—"
  }
  function coreCards() {
    return [
      { title: "Subject", text: roleWords(["subject"]), color: "#9eea9a" },
      { title: "Predicate", text: roleWords(["predicate"]), color: "#6fc7ff" },
      { title: "Object / complement", text: roleWords(["object / complement", "object of preposition"]), color: "#c6bbff" }
    ]
  }
  function findingColor(kind) {
    if (kind === "error") return "#ff827c"
    if (kind === "correct") return "#9eea9a"
    if (kind === "style") return "#c6bbff"
    return "#ffbf62"
  }
  function partOfSpeechName(pos) {
    var names = {
      "ADJ": "adjective", "ADP": "preposition", "ADV": "adverb", "AUX": "auxiliary verb",
      "CCONJ": "coordinating conjunction", "DET": "determiner", "INTJ": "interjection",
      "NOUN": "noun", "NUM": "number", "PART": "particle", "PRON": "pronoun",
      "PROPN": "proper noun", "SCONJ": "subordinating conjunction", "VERB": "verb", "X": "unclassified word"
    }
    return names[pos] || "word"
  }
  function featureText(features) {
    var names = { "Number": "number", "Person": "person", "Tense": "tense", "VerbForm": "verb form", "Aspect": "aspect", "Degree": "degree", "Definite": "definiteness", "PronType": "pronoun type", "Case": "case", "Gender": "gender" }
    var values = { "Sing": "singular", "Plur": "plural", "Pres": "present", "Past": "past", "Fin": "finite", "Inf": "infinitive", "Part": "participle", "Ger": "gerund", "Pos": "positive", "Cmp": "comparative", "Sup": "superlative", "Def": "definite", "Ind": "indefinite", "Art": "article", "Prs": "personal", "Nom": "nominative", "Acc": "accusative", "Masc": "masculine", "Fem": "feminine", "Neut": "neuter" }
    var output = []
    for (var key in (features || {})) output.push((names[key] || key) + ": " + (values[features[key]] || features[key]))
    return output.length ? output.join(" · ") : "No additional form details"
  }
  function relationName(label) {
    var names = {
      "nsubj": "is the subject of", "nsubjpass": "is the passive subject of",
      "obj": "is the object of", "dobj": "is the direct object of", "pobj": "is the object of the preposition",
      "det": "determines", "amod": "describes", "advmod": "modifies", "npadvmod": "adds a time or place detail to",
      "prep": "introduces a prepositional phrase for", "case": "introduces a prepositional phrase for", "obl": "adds a circumstance to", "obl:tmod": "adds a time detail to", "nmod:poss": "shows possession for", "mark": "introduces a clause for", "advcl": "is an adverbial clause modifying", "cc": "coordinates", "conj": "is coordinated with",
      "aux": "is an auxiliary verb for", "neg": "negates", "compound": "forms a compound with",
      "prt": "is a verb particle for", "attr": "is a subject complement of", "ccomp": "is a clause complement of", "xcomp": "is an open complement of"
    }
    return names[label] || "relates to"
  }
  function glossaryItems() {
    if (viewIndex === 1) return [
      { term: "Clause", definition: "A group of words built around a verb; an independent clause can stand as a sentence." },
      { term: "Phrase", definition: "A group of words that works together but does not contain a complete subject-predicate clause." },
      { term: "Noun phrase", definition: "A noun or pronoun together with words that identify or describe it." },
      { term: "Prepositional phrase", definition: "A preposition plus its object, often adding place, time, direction, or manner." }
    ]
    if (viewIndex === 2) return [
      { term: "Relationship", definition: "How one word depends on or contributes to another word in the sentence." },
      { term: "Subject", definition: "Who or what performs the action or is described by the predicate." },
      { term: "Object", definition: "A word or phrase affected by, completed by, or governed by another word." },
      { term: "Modifier", definition: "A word or phrase that adds detail by describing, limiting, or qualifying another element." },
      { term: "Preposition", definition: "A word such as “by,” “with,” or “under” that introduces a relationship in a phrase." }
    ]
    if (viewIndex === 3) return [
      { term: "Subject–verb agreement", definition: "A subject and finite verb match in number and person, such as “dogs run” or “dog runs.”" },
      { term: "Fragment", definition: "A group of words that may be missing a complete independent subject-predicate clause." },
      { term: "Determiner", definition: "A word that introduces or limits a noun, such as “the,” “this,” “my,” or “those.”" },
      { term: "Tense shift", definition: "A change of verb tense; it can be intentional, but should match the intended time relationship." },
      { term: "Style note", definition: "A writing observation rather than a grammar error." }
    ]
    if (viewIndex === 4) return [
      { term: "Conditional clause", definition: "A clause, often introduced by “if,” that states a condition for another clause." },
      { term: "Causative", definition: "A construction in which someone or something causes, allows, makes, or forces an action." },
      { term: "Infinitive", definition: "The basic verb form, often introduced by “to,” as in “to hide.”" },
      { term: "Finite clause", definition: "A clause with a verb marked for tense, person, number, or a modal auxiliary." },
      { term: "Cognate object", definition: "An object that shares a base word with its verb, as in “smiled a smile.”" },
      { term: "Emphatic self-pronoun", definition: "A self-pronoun used for emphasis, as in “I myself carried it.”" },
      { term: "Coordination", definition: "A joining of equal elements with a word such as “and,” “but,” or “or.”" }
    ]
    return []
  }

  Label { anchors.centerIn: parent; visible: root.busy; text: "Building structure…" }
  Label { anchors.centerIn: parent; visible: !root.busy && root.nodes().length === 0; text: "Type a sentence to see its structure."; color: Color.muted }

  ScrollView {
    anchors.fill: parent
    visible: !root.busy && root.nodes().length > 0
    clip: true
    ColumnLayout {
      width: parent.width
      spacing: 8

      Label { visible: root.viewIndex === 0; text: "Sentence map"; color: "#9e82ff"; font.pixelSize: 16 }
      Flow {
        visible: root.viewIndex === 0
        Layout.fillWidth: true
        spacing: 8
        Repeater {
          model: root.coreCards()
          delegate: Rectangle {
            required property var modelData
            width: 190
            height: 58
            radius: 7
            color: Qt.rgba(1, 1, 1, .035)
            border.color: modelData.color
            border.width: 1
            ColumnLayout {
              id: cardContent
              anchors.fill: parent
              anchors.margins: 8
              spacing: 2
              Label { text: modelData.title; color: modelData.color; font.pixelSize: 13; textFormat: Text.PlainText }
              Label { text: modelData.text; color: Color.foreground; font.pixelSize: 17; textFormat: Text.PlainText; elide: Text.ElideRight; Layout.maximumWidth: 170 }
            }
          }
        }
      }
      Rectangle {
        visible: root.viewIndex === 0 && root.selected >= 0
        Layout.fillWidth: true
        Layout.preferredHeight: 70
        radius: 6
        color: Qt.rgba(1, 1, 1, .05)
        border.color: root.nodes()[root.selected] ? root.accentFor(root.nodes()[root.selected].role) : Color.popups.border
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 8
          spacing: 1
          Label {
            text: root.nodes()[root.selected] ? "Selected: " + root.nodes()[root.selected].text + " — " + root.nodes()[root.selected].role : ""
            color: root.nodes()[root.selected] ? root.accentFor(root.nodes()[root.selected].role) : Color.foreground
            font.pixelSize: 15
            elide: Text.ElideRight
            textFormat: Text.PlainText
          }
          Label {
            text: root.nodes()[root.selected] ? "Part of speech: " + root.partOfSpeechName(root.nodes()[root.selected].pos) + " · Base form: " + root.nodes()[root.selected].lemma : ""
            color: Color.foreground
            font.pixelSize: 14
            elide: Text.ElideRight
            textFormat: Text.PlainText
          }
          Label {
            text: root.nodes()[root.selected] ? root.featureText(root.nodes()[root.selected].features) : ""
            color: Color.muted
            font.pixelSize: 13
            elide: Text.ElideRight
            textFormat: Text.PlainText
          }
        }
      }
      Label { visible: root.viewIndex === 0; text: "Tokens — select one to inspect its role"; color: Color.muted; font.pixelSize: 14 }
      Flow {
        visible: root.viewIndex === 0
        Layout.fillWidth: true
        spacing: 7
        Repeater {
          model: root.nodes()
          delegate: Button {
            required property var modelData
            required property int index
            text: modelData.text
            checkable: true
            checked: root.selected === index
            font.pixelSize: 16
            leftPadding: 8; rightPadding: 8; topPadding: 4; bottomPadding: 4; implicitHeight: 30
            onClicked: root.selected = index
            background: Rectangle {
              radius: 5
              color: root.selected === index ? Qt.rgba(0.62, 0.51, 1.0, .18) : Qt.rgba(1, 1, 1, .025)
              border.color: root.selected === index ? root.accentFor(modelData.role) : Color.popups.border
              border.width: root.selected === index ? 2 : 1
            }
            contentItem: Text { text: parent.text; color: root.accentFor(modelData.role); font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; textFormat: Text.PlainText }
          }
        }
      }
      Label { visible: root.viewIndex === 1; text: "Clauses & phrases"; color: "#9e82ff"; font.pixelSize: 16 }
      Repeater {
        model: root.viewIndex === 1 ? (root.model.clauses || []).concat(root.model.phrases || []) : []
        delegate: RowLayout {
          required property var modelData
          Layout.fillWidth: true; spacing: 10
          Label { text: modelData.kind || "phrase"; color: "#c6bbff"; font.pixelSize: 15; Layout.preferredWidth: 160; textFormat: Text.PlainText }
          Label { text: root.words(modelData.node_ids); color: Color.foreground; font.pixelSize: 16; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        }
      }

      Label { visible: root.viewIndex === 2; text: "Word relationships"; color: "#9e82ff"; font.pixelSize: 16 }
      Repeater {
        model: root.viewIndex === 2 ? (root.model.edges || []) : []
        delegate: RowLayout {
          required property var modelData
          Layout.fillWidth: true; spacing: 10
          Label { text: root.nodes()[modelData.from] ? root.nodes()[modelData.from].text : "word"; color: "#6fc7ff"; font.pixelSize: 16; Layout.preferredWidth: 120; elide: Text.ElideRight; textFormat: Text.PlainText }
          Label { text: root.relationName(modelData.label) + " → " + (root.nodes()[modelData.to] ? root.nodes()[modelData.to].text : "word"); color: Color.foreground; font.pixelSize: 16; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        }
      }

      Label { visible: root.viewIndex === 3; text: "Grammar & style"; color: "#9e82ff"; font.pixelSize: 16 }
      Repeater {
        model: root.viewIndex === 3 ? (root.model.findings || []) : []
        delegate: ColumnLayout {
          required property var modelData
          Layout.fillWidth: true; spacing: 2
          Label { text: modelData.title || "Writing note"; color: root.findingColor(modelData.kind); font.pixelSize: 16; textFormat: Text.PlainText }
          Label { text: modelData.message || ""; color: Color.foreground; font.pixelSize: 15; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        }
      }

      Label { visible: root.viewIndex === 4; text: "Constructions & rhetoric"; color: "#9e82ff"; font.pixelSize: 16 }
      Repeater {
        model: root.viewIndex === 4 ? (root.model.constructions || []) : []
        delegate: ColumnLayout {
          required property var modelData
          Layout.fillWidth: true; spacing: 2
          Label { text: modelData.title || "Construction"; color: "#c6bbff"; font.pixelSize: 16; textFormat: Text.PlainText }
          Label { text: modelData.message || ""; color: Color.foreground; font.pixelSize: 15; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
          Label { text: root.words(modelData.node_ids); color: Color.muted; font.pixelSize: 14; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        }
      }

      Rectangle { visible: root.viewIndex >= 1; Layout.fillWidth: true; height: 1; color: Color.popups.border; Layout.topMargin: 6 }
      Label { visible: root.viewIndex >= 1; text: "Glossary"; color: "#9e82ff"; font.pixelSize: 16; Layout.topMargin: 2 }
      Repeater {
        model: root.viewIndex >= 1 ? root.glossaryItems() : []
        delegate: RowLayout {
          required property var modelData
          Layout.fillWidth: true
          spacing: 10
          Label { text: modelData.term; color: "#c6bbff"; font.pixelSize: 15; Layout.preferredWidth: 185; Layout.alignment: Qt.AlignTop; wrapMode: Text.Wrap; textFormat: Text.PlainText }
          Label { text: modelData.definition; color: Color.foreground; font.pixelSize: 15; Layout.fillWidth: true; wrapMode: Text.Wrap; textFormat: Text.PlainText }
        }
      }
    }
  }
}
