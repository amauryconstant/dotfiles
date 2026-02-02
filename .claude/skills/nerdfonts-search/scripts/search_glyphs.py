#!/usr/bin/env python3
"""
Search Nerd Fonts glyphs by keyword or concept.
Usage: python search_glyphs.py <search_term> [--limit N]
"""

import json
import sys
from pathlib import Path
from difflib import SequenceMatcher

def load_glyphs():
    """Load glyphs from JSON file."""
    script_dir = Path(__file__).parent
    json_path = script_dir.parent / "references" / "glyphnames.json"

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Remove metadata entry
    if "METADATA" in data:
        del data["METADATA"]

    return data

def search_glyphs(search_term, glyphs, limit=10):
    """
    Search glyphs by keyword with fuzzy matching.
    Returns list of (name, char, code, score) tuples sorted by relevance.
    """
    search_term = search_term.lower()
    results = []

    for name, glyph_data in glyphs.items():
        # Extract the readable part after the prefix (e.g., "cod-battery" -> "battery")
        name_lower = name.lower()
        readable_name = name.split('-', 1)[1] if '-' in name else name

        # Calculate relevance score
        score = 0

        # Exact match in readable name
        if search_term in readable_name.lower():
            score += 100
            # Bonus for exact word match
            if search_term == readable_name.lower():
                score += 50

        # Partial match in full name
        if search_term in name_lower:
            score += 50

        # Fuzzy matching
        similarity = SequenceMatcher(None, search_term, readable_name.lower()).ratio()
        score += similarity * 30

        if score > 0:
            results.append((name, glyph_data['char'], glyph_data['code'], score))

    # Sort by score (descending)
    results.sort(key=lambda x: x[3], reverse=True)

    return results[:limit]

def format_results(results):
    """Format search results for display."""
    if not results:
        return "No glyphs found matching your search."

    output = []
    output.append(f"Found {len(results)} matching glyph(s):\n")

    for name, char, code, score in results:
        output.append(f"  {char}  {name}")
        output.append(f"     Code: U+{code.upper()}")
        output.append("")

    return "\n".join(output)

def main():
    if len(sys.argv) < 2:
        print("Usage: python search_glyphs.py <search_term> [--limit N]")
        print("Example: python search_glyphs.py battery")
        sys.exit(1)

    search_term = sys.argv[1]
    limit = 10

    # Parse limit argument
    if len(sys.argv) > 2 and sys.argv[2] == "--limit" and len(sys.argv) > 3:
        try:
            limit = int(sys.argv[3])
        except ValueError:
            print("Error: limit must be an integer")
            sys.exit(1)

    glyphs = load_glyphs()
    results = search_glyphs(search_term, glyphs, limit)
    print(format_results(results))

if __name__ == "__main__":
    main()
