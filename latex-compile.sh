#!/bin/bash
# =============================================================================
# latex-compile.sh - LaTeX compilation script for neovim/VimTeX
# =============================================================================
# Mirrors the behavior of pdfLaTeXWithBuild.engine:
# - Compiles LaTeX with auxiliary files in ./.build directory
# - Runs pdflatex 3x for references, includes BibTeX support
# - Moves PDF back to source folder for clean directory structure
# =============================================================================

# Note: not using set -e because pdflatex returns non-zero on warnings

# Check if file argument provided
if [ -z "$1" ]; then
    echo "Usage: latex-compile.sh <file.tex>"
    exit 1
fi

# Validate input file exists
if [ ! -f "$1" ]; then
    echo "ERROR: File '$1' not found"
    exit 1
fi

# Validate .tex extension
if [[ "$1" != *.tex ]]; then
    echo "ERROR: File must have .tex extension"
    exit 1
fi

# Extract the filename without path and extension
filename="$(basename "$1" .tex)"

# Extract the directory containing the .tex file
dirname="$(dirname "$1")"

# Handle relative paths - get absolute path
if [[ "$dirname" != /* ]]; then
    dirname="$(cd "$dirname" && pwd)"
fi

# Create the path to and the build directory if it does not already exist
builddir="${dirname}/.build"
mkdir -p "$builddir"

echo "=== Compiling $filename.tex ==="
echo "Build directory: $builddir"

# Function to check if PDF was generated (indicates successful compilation)
check_compilation() {
    if [ ! -f "$builddir/${filename}.pdf" ]; then
        echo "ERROR: PDF was not generated. Cleaning auxiliary files..."
        rm -f "$builddir/$filename.aux" \
              "$builddir/$filename.out" \
              "$builddir/$filename.toc" \
              "$builddir/$filename.lof" \
              "$builddir/$filename.lot" \
              "$builddir/$filename.loc" \
              "$builddir/$filename.soc"
        exit 1
    fi
}

# First pass
echo "--- Pass 1/3: Initial compilation ---"
pdflatex -interaction=nonstopmode -output-directory="$builddir" "$dirname/$filename.tex"
check_compilation

# Run BibTeX on the .aux file in the build folder
echo "--- Running BibTeX ---"
(cd "$builddir" && bibtex "$filename") || echo "WARNING: BibTeX returned non-zero (may be expected if no citations)"

# Copy bbl file to source dir (needed for some setups)
if [ -f "$builddir/${filename}.bbl" ]; then
    cp "$builddir/${filename}.bbl" "$dirname/"
fi

# Second pass (resolve citations)
echo "--- Pass 2/3: Resolving citations ---"
pdflatex -interaction=nonstopmode -output-directory="$builddir" "$dirname/$filename.tex"
check_compilation

# Third pass (resolve references)
echo "--- Pass 3/3: Resolving references ---"
pdflatex -interaction=nonstopmode -output-directory="$builddir" "$dirname/$filename.tex"
check_compilation

# Move PDF back to the source folder
mv "$builddir/${filename}.pdf" "$dirname/"

# Clean any auxiliary files that might have been created in the main directory
# Note: bbl/blg are kept for reference resolution
rm -f "$dirname/$filename.aux" \
      "$dirname/$filename.out" \
      "$dirname/$filename.log" \
      "$dirname/$filename.toc" \
      "$dirname/$filename.lof" \
      "$dirname/$filename.lot" \
      "$dirname/$filename.loc" \
      "$dirname/$filename.soc" 2>/dev/null || true

echo "=== Compilation complete: $dirname/$filename.pdf ==="
