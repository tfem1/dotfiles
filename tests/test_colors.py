"""Tests for the Color type: hex parsing, transparency and output formats."""
import unittest

from theming.colors import Color


class ParseTest(unittest.TestCase):
    def test_parses_opaque_hex(self):
        self.assertEqual(Color.parse("#cba6f7"), Color(203, 166, 247, 1.0))

    def test_parses_hex_with_alpha(self):
        self.assertEqual(Color.parse("#cba6f780").alpha_byte, 0x80)

    def test_is_case_insensitive(self):
        self.assertEqual(Color.parse("#CBA6F7"), Color.parse("#cba6f7"))

    def test_rejects_invalid_values(self):
        for bad in ("cba6f7", "#cba6f", "#zzzzzz", "", None, 12):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                Color.parse(bad)


class FormatTest(unittest.TestCase):
    def setUp(self):
        self.mauve = Color.parse("#cba6f7")

    def test_hex_omits_alpha_when_opaque(self):
        self.assertEqual(self.mauve.hex(), "#cba6f7")

    def test_hex_appends_alpha_when_transparent(self):
        self.assertEqual(self.mauve.with_alpha(0.8).hex(), "#cba6f7cc")

    def test_strip_removes_hash(self):
        self.assertEqual(self.mauve.strip(), "cba6f7")

    def test_hypr_always_has_alpha(self):
        self.assertEqual(self.mauve.hypr(), "rgba(cba6f7ff)")
        self.assertEqual(self.mauve.with_alpha(0.5).hypr(), "rgba(cba6f780)")

    def test_argb_puts_alpha_first(self):
        self.assertEqual(self.mauve.with_alpha(0.8).argb(), "#cccba6f7")

    def test_rgb_lists_channels(self):
        self.assertEqual(self.mauve.rgb(), "203, 166, 247")

    def test_with_alpha_rejects_out_of_range(self):
        for bad in (-0.1, 1.5):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.mauve.with_alpha(bad)


class SgrTest(unittest.TestCase):
    def test_true_color_code_for_terminals(self):
        self.assertEqual(Color.parse("#5fd0c0").sgr(), "38;2;95;208;192")


if __name__ == "__main__":
    unittest.main()
