"""Tests of theming.edit: one key changed, the rest of the file kept."""
import tomllib
import unittest

from theming.edit import set_value


class SetValueTest(unittest.TestCase):
    def test_replaces_the_key_and_keeps_comments_and_other_keys(self):
        text = '# mine\n[wallpaper]\n# my pick\npath = "old.jpg"\n\n[font]\nsize = 12\n'
        result = set_value(text, "wallpaper", "path", "pony/new.jpg")
        self.assertEqual(result, '# mine\n[wallpaper]\n# my pick\npath = "pony/new.jpg"\n\n[font]\nsize = 12\n')

    def test_adds_the_key_to_an_existing_table(self):
        result = set_value('[wallpaper]\nmode = "fill"\n[font]\npath = "x"\n', "wallpaper", "path", "a.png")
        data = tomllib.loads(result)
        self.assertEqual(data["wallpaper"], {"path": "a.png", "mode": "fill"})
        self.assertEqual(data["font"], {"path": "x"})

    def test_adds_the_table_when_missing(self):
        self.assertEqual(set_value("", "wallpaper", "path", "a.png"), '[wallpaper]\npath = "a.png"\n')
        self.assertEqual(set_value("[font]\nsize = 12\n", "wallpaper", "path", "a.png"),
                         '[font]\nsize = 12\n\n[wallpaper]\npath = "a.png"\n')

    def test_quotes_and_backslashes_are_escaped(self):
        result = set_value("", "wallpaper", "path", 'my "best" \\ pick.png')
        self.assertEqual(tomllib.loads(result)["wallpaper"]["path"], 'my "best" \\ pick.png')

    def test_numbers_booleans_and_dotted_tables(self):
        text = set_value("[shape]\nradius = 12\n", "shape", "radius", 8)
        text = set_value(text, "effects", "blur", False)
        text = set_value(text, "effects", "opacity", 0.85)
        text = set_value(text, "palette.overrides", "base00", "#11111b")
        data = tomllib.loads(text)
        self.assertEqual(data["shape"]["radius"], 8)
        self.assertIs(data["effects"]["blur"], False)
        self.assertEqual(data["effects"]["opacity"], 0.85)
        self.assertEqual(data["palette"]["overrides"]["base00"], "#11111b")

    def test_refuses_a_file_it_cannot_change_safely(self):
        # A dotted key already defines the table: adding [wallpaper] would break the file.
        with self.assertRaises(ValueError):
            set_value('wallpaper.path = "a.png"\n', "wallpaper", "path", "b.png")


if __name__ == "__main__":
    unittest.main()
