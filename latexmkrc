# =============================================================================
# latexmkrc - Global latexmk configuration
# =============================================================================
# Puts auxiliary files in .build/ while keeping PDF in source directory.
# Symlinked to ~/.latexmkrc by setup.sh
# =============================================================================

# Use pdflatex
$pdf_mode = 1;
$postscript_mode = 0;
$dvi_mode = 0;

# Put all output files in .build subdirectory
$out_dir = '.build';

# SyncTeX for forward/inverse search with PDF viewers
push @extra_pdflatex_options, '-synctex=1';

# Ensure bibtex/biber run when needed
$bibtex_use = 2;  # Run bibtex/biber when .bib files are detected

# Make bibtex/biber find .bib files (handles both direct and cd-based invocation)
# Path includes: current dir, parent dir, then default TeX paths
$ENV{'BIBINPUTS'} = '.:..::';
$ENV{'BSTINPUTS'} = '.:..::';

# TEXINPUTS: current, parent, then defaults (for \input, \include from .build)
$ENV{'TEXINPUTS'} = '.:..::';

# Run bibtex from the output directory where .aux files are
$bibtex = 'bibtex %O %B';

# Additional extensions to clean with latexmk -c
$clean_ext = 'run.xml';
