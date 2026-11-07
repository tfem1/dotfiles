"""Template engine tests: substitution, filters and error messages."""
import unittest

from theming.colors import Color
from theming.template import TemplateError, render

CONTEXT = {
    "accent": Color.parse("#cba6f7"),
    "shape.radius": 12,
    "effects.opacity": 0.9,
    "effects.blur": True,
    "font.sans": 'My "Font"',
    "base0A": Color.parse("#f9e2af"),
}


class RenderTest(unittest.TestCase):
    def test_substitutes_values(self):
        self.assertEqual(render("r = {{ shape.radius }}", CONTEXT), "r = 12")

    def test_spaces_inside_braces_are_optional(self):
        self.assertEqual(render("{{shape.radius}}", CONTEXT), "12")

    def test_colors_default_to_hex(self):
        self.assertEqual(render("{{ accent }}", CONTEXT), "#cba6f7")

    def test_uppercase_base16_names_are_valid(self):
        self.assertEqual(render("{{ base0A }}", CONTEXT), "#f9e2af")

    def test_booleans_render_lowercase(self):
        self.assertEqual(render("{{ effects.blur }}", CONTEXT), "true")

    def test_floats_render_shortest_form(self):
        self.assertEqual(render("{{ effects.opacity }}", CONTEXT), "0.9")

    def test_filters_chain_left_to_right(self):
        self.assertEqual(render("{{ accent | alpha:0.8 | hypr }}", CONTEXT), "rgba(cba6f7cc)")

    def test_json_filter_quotes_and_escapes(self):
        self.assertEqual(render("{{ font.sans | json }}", CONTEXT), '"My \\"Font\\""')

    def test_quote_filter_keeps_one_shell_argument(self):
        self.assertEqual(render("{{ font.sans | quote }}", CONTEXT), "'My \"Font\"'")
        self.assertEqual(render("{{ shape.radius | quote }}", CONTEXT), "12")

    def test_json_filter_on_color_gives_string(self):
        self.assertEqual(render("{{ accent | json }}", CONTEXT), '"#cba6f7"')

    def test_text_without_tags_is_unchanged(self):
        text = "-- comment\nhl.config({ general = { } })\n"
        self.assertEqual(render(text, CONTEXT), text)


class ErrorTest(unittest.TestCase):
    def assert_error(self, text, *fragments):
        with self.assertRaises(TemplateError) as caught:
            render(text, CONTEXT, source="demo.tpl")
        message = str(caught.exception)
        for fragment in fragments:
            self.assertIn(fragment, message)

    def test_unknown_variable_reports_file_line_and_suggestion(self):
        self.assert_error("ok\n{{ shape.radus }}", "demo.tpl:2", "shape.radus", "shape.radius")

    def test_unknown_filter(self):
        self.assert_error("{{ accent | shiny }}", "unknown filter 'shiny'")

    def test_color_filter_on_number(self):
        self.assert_error("{{ shape.radius | hypr }}", "expects a color")

    def test_filter_missing_argument(self):
        self.assert_error("{{ accent | alpha }}", "alpha")

    def test_filter_bad_argument(self):
        self.assert_error("{{ accent | alpha:lots }}", "not a number")

    def test_filter_unexpected_argument(self):
        self.assert_error("{{ accent | hypr:2 }}", "takes no argument")

    def test_invalid_expression(self):
        self.assert_error("{{ 1 + 1 }}", "invalid expression")

    def test_unclosed_tag(self):
        self.assert_error("a {{ accent", "unclosed")


if __name__ == "__main__":
    unittest.main()
