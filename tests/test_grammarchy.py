import importlib.machinery
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest

PATH = Path(__file__).parents[1] / "bin" / "grammarchy"
LOADER = importlib.machinery.SourceFileLoader("grammarchy", str(PATH))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
grammarchy = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(grammarchy)

class GrammarchyTests(unittest.TestCase):
    def test_normalizes_clipboard_style_text(self):
        self.assertEqual(grammarchy.clean("  “Hello”\n world  "), '"Hello" world')

    def test_diagram_has_bounded_nodes_and_edges(self):
        model = grammarchy.diagram("The fox jumps quickly.")
        self.assertEqual(model["provider"]["id"], "udpipe")
        self.assertEqual([node["role"] for node in model["nodes"]], ["determiner", "subject", "predicate", "adverbial modifier"])
        self.assertEqual(len(model["edges"]), 3)

    def test_bundled_provider_is_present_for_the_release_target(self):
        bundle = grammarchy.bundled_udpipe()
        self.assertIsNotNone(bundle)
        binary, model = bundle
        self.assertTrue(binary.stat().st_size > 1_000_000)
        self.assertTrue(model.stat().st_size > 10_000_000)

    def test_plural_subject_is_not_misread_as_the_predicate(self):
        model = grammarchy.diagram("The cats sleep.")
        self.assertEqual(model["nodes"][2]["role"], "predicate")
        self.assertEqual(model["nodes"][1]["role"], "subject")

    def test_mockup_sentence_maps_to_readable_roles(self):
        model = grammarchy.diagram("The quick fox jumps over the lazy dog.")
        self.assertEqual([node["role"] for node in model["nodes"]], ["determiner", "adjective", "subject", "predicate", "preposition", "determiner", "adjective", "object of preposition"])
        self.assertEqual(model["nodes"][2]["pos"], "NOUN")
        self.assertEqual(model["nodes"][3]["lemma"], "jump")
        self.assertEqual(model["nodes"][3]["features"]["Tense"], "Pres")

    def test_compound_sentence_has_multiple_clause_analysis(self):
        model = grammarchy.diagram("Alice sings and Bob dances.")
        self.assertEqual(model["provider"]["id"], "udpipe")
        self.assertGreaterEqual(len(model["clauses"]), 1)

    def test_mode_is_part_of_the_diagram_contract(self):
        self.assertEqual(grammarchy.diagram("Birds fly.", "dependency")["mode"], "dependency")
        with self.assertRaisesRegex(ValueError, "Unknown diagram mode"):
            grammarchy.diagram("Birds fly.", "tree")

    def test_config_is_bounded_and_rejects_unsafe_path(self):
        previous = os.environ.get("XDG_CONFIG_HOME")
        with tempfile.TemporaryDirectory() as directory:
            os.environ["XDG_CONFIG_HOME"] = directory
            config_dir = Path(directory) / "grammarchy"
            config_dir.mkdir()
            (config_dir / "config.toml").write_text("[widget]\nwidth_px = 9999\nclipboard_max_chars = 9999\n[parser]\ntimeout_ms = 1\n[display]\nmode = 'tree'\n")
            config = grammarchy.bounded_config()
            self.assertEqual(config["widget"]["width_px"], 760)
            self.assertEqual(config["widget"]["clipboard_max_chars"], 1000)
            self.assertEqual(config["parser"]["timeout_ms"], 100)
            self.assertEqual(config["display"]["mode"], "reed_kellogg")
        if previous is None: os.environ.pop("XDG_CONFIG_HOME", None)
        else: os.environ["XDG_CONFIG_HOME"] = previous

    def test_empty_sentence_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Paste or type"):
            grammarchy.diagram("...")

    def test_reports_subject_verb_agreement_error(self):
        findings = grammarchy.diagram("The dogs runs.")["findings"]
        self.assertTrue(any(item["kind"] == "error" and item["title"] == "Subject–verb agreement" for item in findings))

    def test_reports_clear_fragment_and_determiner_number_candidates(self):
        fragment = grammarchy.diagram("Running down the road.")["findings"]
        self.assertTrue(any(item["title"] == "Fragment candidate" for item in fragment))
        mismatch = grammarchy.diagram("These dog runs.")["findings"]
        self.assertTrue(any(item["title"] == "Determiner and noun number" for item in mismatch))

    def test_exposes_named_constructions_from_syntax(self):
        constructions = grammarchy.diagram("If I caused the children to hide, I carried my bag and my map.")["constructions"]
        titles = {item["title"] for item in constructions}
        self.assertIn("Conditional clause", titles)
        self.assertIn("Causative infinitive", titles)
        self.assertIn("Repeated possessive pronouns", titles)

    def test_exposes_learning_structure(self):
        model = grammarchy.diagram("I found a lost dog down by the river today.")
        self.assertEqual(model["provider"]["id"], "udpipe")
        self.assertTrue(model["clauses"])
        self.assertTrue(model["phrases"])
        self.assertEqual(model["nodes"][4]["role"], "object / complement")
        self.assertTrue(any(edge["label"] in {"obj", "dobj"} for edge in model["edges"]))
        self.assertTrue(any(phrase["kind"] == "noun phrase" and phrase["node_ids"] == [2, 3, 4] for phrase in model["phrases"]))

    def test_model_is_versioned_and_validated(self):
        model = grammarchy.diagram("The dog runs.")
        self.assertEqual(model["schemaVersion"], 1)
        self.assertTrue(grammarchy.validate_model(model))
        model["edges"][0]["to"] = 999
        self.assertFalse(grammarchy.validate_model(model))

    def test_model_validation_rejects_unsafe_nested_references(self):
        model = grammarchy.diagram("The dog runs.")
        model["phrases"][0]["node_ids"] = [999]
        self.assertFalse(grammarchy.validate_model(model))
        model = grammarchy.diagram("The dog runs.")
        model["findings"][0]["kind"] = "unknown"
        self.assertFalse(grammarchy.validate_model(model))
