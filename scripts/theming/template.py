"""Moteur de templates : remplace chaque {{ expression }} par une valeur du contexte.

Syntaxe : {{ nom }} ou {{ nom | filtre | filtre:argument }}.
Une variable ou un filtre inconnu est une erreur, jamais un trou silencieux.
"""
from __future__ import annotations

import difflib
import re
from typing import Mapping

from .filters import apply_filter, format_value

_TAG = re.compile(r"\{\{(.*?)\}\}")
_NAME = re.compile(r"[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)*")
_FILTER = re.compile(r"([a-z_]+)(?::(.+))?")


class TemplateError(Exception):
    def __init__(self, source: str, line: int, message: str):
        super().__init__(f"{source}:{line}: {message}")


def render(text: str, context: Mapping[str, object], source: str = "<template>") -> str:
    pieces: list[str] = []
    cursor = 0
    for match in _TAG.finditer(text):
        _check_literal(text, cursor, match.start(), source)
        pieces.append(text[cursor:match.start()])
        try:
            pieces.append(_evaluate(match.group(1), context))
        except ValueError as error:
            raise TemplateError(source, _line_of(text, match.start()), str(error)) from None
        cursor = match.end()
    _check_literal(text, cursor, len(text), source)
    pieces.append(text[cursor:])
    return "".join(pieces)


def _evaluate(expression: str, context: Mapping[str, object]) -> str:
    name, *filters = (part.strip() for part in expression.split("|"))
    if not _NAME.fullmatch(name):
        raise ValueError(f"invalid expression '{expression.strip()}'")
    if name not in context:
        raise ValueError(_unknown_variable(name, context))
    value = context[name]
    for item in filters:
        parsed = _FILTER.fullmatch(item)
        if not parsed:
            raise ValueError(f"invalid filter '{item}'")
        value = apply_filter(parsed.group(1), value, parsed.group(2))
    return format_value(value)


def _unknown_variable(name: str, context: Mapping[str, object]) -> str:
    close = difflib.get_close_matches(name, list(context), n=1)
    hint = f" (did you mean '{close[0]}'?)" if close else ""
    return f"unknown variable '{name}'{hint}"


def _check_literal(text: str, start: int, end: int, source: str) -> None:
    """Refuse un « {{ » resté sans fermeture dans le texte littéral."""
    position = text.find("{{", start, end)
    if position != -1:
        message = "unclosed '{{' (write '{ {' if you meant two braces)"
        raise TemplateError(source, _line_of(text, position), message)


def _line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1
