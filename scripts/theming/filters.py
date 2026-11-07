"""Filtres des templates ({{ valeur | filtre:arg }}) et mise en texte des valeurs."""
from __future__ import annotations

import json
from typing import Callable

from .colors import Color


class FilterError(ValueError):
    """Erreur d'application d'un filtre (message destiné à l'utilisateur)."""


def _type_name(value: object) -> str:
    return {bool: "un booléen", int: "un nombre", float: "un nombre", str: "une chaîne"}.get(
        type(value), type(value).__name__
    )


def _color(name: str, value: object) -> Color:
    if not isinstance(value, Color):
        raise FilterError(f"le filtre '{name}' attend une couleur, pas {_type_name(value)}")
    return value


def _no_arg(name: str, arg: str | None) -> None:
    if arg is not None:
        raise FilterError(f"le filtre '{name}' ne prend pas d'argument")


def _color_format(name: str, method: str) -> Callable[[object, str | None], object]:
    """Fabrique un filtre sans argument qui appelle une méthode de Color."""

    def apply(value: object, arg: str | None) -> object:
        _no_arg(name, arg)
        return getattr(_color(name, value), method)()

    return apply


def _alpha(value: object, arg: str | None) -> object:
    if arg is None:
        raise FilterError("le filtre 'alpha' a besoin d'une valeur, ex. alpha:0.8")
    try:
        amount = float(arg)
    except ValueError:
        raise FilterError(f"alpha : {arg!r} n'est pas un nombre") from None
    try:
        return _color("alpha", value).with_alpha(amount)
    except ValueError as error:
        raise FilterError(str(error)) from None


def _json(value: object, arg: str | None) -> object:
    _no_arg("json", arg)
    if isinstance(value, Color):
        value = value.hex()
    return json.dumps(value, ensure_ascii=False)


FILTERS: dict[str, Callable[[object, str | None], object]] = {
    "hex": _color_format("hex", "hex"),
    "strip": _color_format("strip", "strip"),
    "hypr": _color_format("hypr", "hypr"),
    "argb": _color_format("argb", "argb"),
    "rgb": _color_format("rgb", "rgb"),
    "alpha": _alpha,
    "json": _json,
}


def apply_filter(name: str, value: object, arg: str | None) -> object:
    try:
        function = FILTERS[name]
    except KeyError:
        known = ", ".join(sorted(FILTERS))
        raise FilterError(f"filtre inconnu '{name}' (disponibles : {known})") from None
    return function(value, arg)


def format_value(value: object) -> str:
    """Convertit une valeur finale en texte à insérer dans le fichier."""
    if isinstance(value, Color):
        return value.hex()
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, float):
        return repr(value)
    return str(value)
