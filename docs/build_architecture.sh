#!/bin/bash
# Assembles ARCHITECTURE.md from the base document (§1-11) and section files (§12-29)
# Run from the docs/ directory: bash build_architecture.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR/ARCHITECTURE.md"
SECTIONS_DIR="$SCRIPT_DIR/sections"
OUTPUT="$SCRIPT_DIR/ARCHITECTURE.md"
TEMP="$SCRIPT_DIR/.ARCHITECTURE_build.md"

# Extract §1-11 (everything up to the closing marker)
# Find the line with "Sections 12-29" or the last --- before the closing
CUTLINE=$(grep -n "^---$" "$BASE" | tail -1 | cut -d: -f1)
if [ -z "$CUTLINE" ]; then
    CUTLINE=$(wc -l < "$BASE")
fi

# Take everything up to 2 lines before the last ---
head -n $((CUTLINE - 1)) "$BASE" > "$TEMP"
echo "" >> "$TEMP"
echo "---" >> "$TEMP"
echo "" >> "$TEMP"

# Append section files in order
SECTION_FILES=(
    "s12_14.md"
    "s15_17.md"
    "s18_19.md"
    "s20_21.md"
    "s22_25.md"
    "s26.md"
    "s27_29.md"
)

FOUND=0
MISSING=0
for sf in "${SECTION_FILES[@]}"; do
    if [ -f "$SECTIONS_DIR/$sf" ]; then
        echo "" >> "$TEMP"
        cat "$SECTIONS_DIR/$sf" >> "$TEMP"
        echo "" >> "$TEMP"
        echo "---" >> "$TEMP"
        FOUND=$((FOUND + 1))
    else
        echo "WARNING: Missing section file: $sf" >&2
        MISSING=$((MISSING + 1))
    fi
done

# Add closing
echo "" >> "$TEMP"
echo "*This document constitutes the complete architectural blueprint for ATLAS.OS — a comprehensive military simulation operating system for Arma 3. Every system has been specified at sufficient depth to guide implementation directly. The architecture is ready to build.*" >> "$TEMP"

# Replace main file
mv "$TEMP" "$OUTPUT"

TOTAL=$(wc -l < "$OUTPUT")
echo "Assembly complete: $OUTPUT ($TOTAL lines)"
echo "Sections found: $FOUND / ${#SECTION_FILES[@]}"
if [ $MISSING -gt 0 ]; then
    echo "Missing sections: $MISSING — run agents to generate missing files"
fi
