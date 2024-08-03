from __future__ import annotations

import argparse
import re
import webbrowser
from difflib import HtmlDiff
from pathlib import Path
from tempfile import NamedTemporaryFile
from textwrap import dedent
from typing import Iterable

MISMATCH_RE = re.compile(
    dedent(
        """
        USER ## SearchReplaceNoExactMatch: This SEARCH block failed to exactly match lines in (?P<search_file>[^\\n]+)
        USER <<<<<<< SEARCH
        (?P<search>.*?)
        USER =======|
        USER Did you mean to match some of these actual lines from (?P<actual_file>[^\\n]+)\?
        USER 
        USER ```
        (?P<actual>.*?)
        USER ```
        """
    ),
    re.DOTALL,
)

PREFIX = "USER "


class Lines(list):
    def __init__(self, text: str, source_file: str) -> list[str]:
        super().__init__()
        self.source_file = source_file
        lines = text.splitlines()
        if not all(line.startswith(PREFIX) for line in lines):
            raise ValueError("Not all lines start with {PREFIX!r}")
        self.extend((line[len(PREFIX) :] for line in lines))


def analyze_search_mismatches(filepath: Path) -> Iterable[tuple[list[str], list[str]]]:
    search_lines = None
    for match in MISMATCH_RE.finditer(filepath.read_text()):
        if match.group("search"):
            search_lines = Lines(match.group("search"), match.group("search_file"))
        elif match.group("actual"):
            if search_lines:
                actual_lines = Lines(match.group("actual"), match.group("actual_file"))
                yield search_lines, actual_lines
            search_lines = None


def show_in_browser(html: str):
    with NamedTemporaryFile("w", delete=False, suffix=".html") as f:
        f.write(html)
        webbrowser.open(f.name)


def create_diff(search: list[str], actual: list[str]) -> str:
    htmldiff = HtmlDiff(wrapcolumn=78)
    return htmldiff.make_file(search, actual)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("aider_log", type=Path, help="Path to the aider log file")
    args = parser.parse_args()
    searches = []
    actuals = []

    for index, (search, actual) in enumerate(analyze_search_mismatches(args.aider_log)):
        searches.extend(
            [
                "",
                f"================ Search {index + 1}: {search.source_file} ================",
                "",
                *search,
            ]
        )
        actuals.extend(
            [
                "",
                f"================ Search {index + 1}: {actual.source_file} ================",
                "",
                *actual,
            ]
        )
    diff_html = create_diff(searches, actuals)
    show_in_browser(diff_html)


if __name__ == "__main__":
    main()
